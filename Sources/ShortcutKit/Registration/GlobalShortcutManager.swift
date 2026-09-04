import Carbon.HIToolbox

private let shortcutSignature: OSType = 0x5343_4B54 // "SCKT"

@MainActor
final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    struct ResumeFailure {
        let shortcut: Shortcut
        let error: Shortcuts.RegistrationError
    }

    private struct Registration {
        let shortcut: Shortcut
        var ref: EventHotKeyRef?
        let action: @MainActor (ShortcutPhase) -> Void
    }

    private var registrations: [UInt32: Registration] = [:]
    private var nextID: UInt32 = 1
    private var suspensionCount = 0
    private var eventHandler: EventHandlerRef?
    private var installationStatus: OSStatus = noErr

    var isSuspended: Bool {
        suspensionCount > 0
    }

    var registrationCount: Int {
        registrations.count
    }

    private init() {
        var eventTypes = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ),
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyReleased)
            ),
        ]
        installationStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr, hotKeyID.signature == shortcutSignature,
                      let phase = GlobalShortcutManager.phase(for: GetEventKind(event))
                else { return OSStatus(eventNotHandledErr) }

                MainActor.assumeIsolated {
                    Unmanaged<GlobalShortcutManager>
                        .fromOpaque(context)
                        .takeUnretainedValue()
                        .perform(id: hotKeyID.id, phase: phase)
                }
                return noErr
            },
            eventTypes.count,
            &eventTypes,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    func register(
        _ shortcut: Shortcut,
        action: @escaping @MainActor (ShortcutPhase) -> Void
    ) throws -> UInt32 {
        guard installationStatus == noErr else {
            throw Self.registrationError(for: installationStatus)
        }
        guard shortcut.modifiers.subtracting(.all).isEmpty else {
            throw Shortcuts.RegistrationError.invalidShortcut
        }
        guard !registrations.values.contains(where: {
            Self.sameCombination($0.shortcut, shortcut)
        }) else {
            throw Shortcuts.RegistrationError.unavailable
        }

        let id = nextID
        nextID &+= 1
        let ref = try makeRef(for: shortcut, id: id)
        if isSuspended {
            UnregisterEventHotKey(ref)
        }
        registrations[id] = Registration(
            shortcut: shortcut,
            ref: isSuspended ? nil : ref,
            action: action
        )
        return id
    }

    func retry(id: UInt32) throws {
        guard !isSuspended, let registration = registrations[id], registration.ref == nil else {
            return
        }
        registrations[id]?.ref = try makeRef(for: registration.shortcut, id: id)
    }

    func unregister(id: UInt32) {
        guard let registration = registrations.removeValue(forKey: id) else { return }
        if let ref = registration.ref {
            UnregisterEventHotKey(ref)
        }
    }

    func suspend() {
        suspensionCount += 1
        guard suspensionCount == 1 else { return }

        for id in Array(registrations.keys) {
            guard let ref = registrations[id]?.ref else { continue }
            UnregisterEventHotKey(ref)
            registrations[id]?.ref = nil
        }
    }

    func resume() -> [ResumeFailure] {
        guard suspensionCount > 0 else { return [] }
        suspensionCount -= 1
        guard suspensionCount == 0 else { return [] }

        var failures: [ResumeFailure] = []
        for id in Array(registrations.keys) where registrations[id]?.ref == nil {
            guard let shortcut = registrations[id]?.shortcut else { continue }
            do {
                registrations[id]?.ref = try makeRef(for: shortcut, id: id)
            } catch let error as Shortcuts.RegistrationError {
                failures.append(ResumeFailure(shortcut: shortcut, error: error))
            } catch {
                assertionFailure("Unexpected registration error: \(error)")
            }
        }
        return failures
    }

    private func makeRef(
        for shortcut: Shortcut,
        id: UInt32
    ) throws -> EventHotKeyRef {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(shortcut.key.keyCode),
            Self.modifierFlags(from: shortcut.modifiers),
            EventHotKeyID(signature: shortcutSignature, id: id),
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else {
            throw Self.registrationError(for: status)
        }
        return ref
    }

    static func registrationError(for status: OSStatus) -> Shortcuts.RegistrationError {
        switch status {
        case OSStatus(eventHotKeyExistsErr): .unavailable
        case OSStatus(eventHotKeyInvalidErr): .invalidShortcut
        default: .system(status: status)
        }
    }

    static func phase(for eventKind: UInt32) -> ShortcutPhase? {
        switch eventKind {
        case UInt32(kEventHotKeyPressed): .keyDown
        case UInt32(kEventHotKeyReleased): .keyUp
        default: nil
        }
    }

    static func modifierFlags(from modifiers: Modifiers) -> UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) {
            flags |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            flags |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            flags |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            flags |= UInt32(shiftKey)
        }
        return flags
    }

    private static func sameCombination(_ lhs: Shortcut, _ rhs: Shortcut) -> Bool {
        lhs.key.keyCode == rhs.key.keyCode
            && modifierFlags(from: lhs.modifiers) == modifierFlags(from: rhs.modifiers)
    }

    private func perform(id: UInt32, phase: ShortcutPhase) {
        guard !isSuspended, let registration = registrations[id], registration.ref != nil else {
            return
        }
        registration.action(phase)
    }
}

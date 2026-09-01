import AppKit
import Carbon.HIToolbox
@testable import ShortcutKit
import XCTest

final class ModelTests: XCTestCase {
    func testCodableModelsRoundTrip() throws {
        let shortcut = Shortcut(key: .k, modifiers: [.command, .shift])
        let data = try JSONEncoder().encode(shortcut)
        XCTAssertEqual(try JSONDecoder().decode(Shortcut.self, from: data), shortcut)
        XCTAssertEqual(try JSONDecoder().decode(Modifier.self, from: JSONEncoder().encode(Modifier.option)), .option)
        XCTAssertEqual(Key.k, Key(keyCode: 40))
        XCTAssertEqual(Key.returnKey, .return)
    }

    func testModifierNormalization() {
        XCTAssertEqual(KeyboardEventNormalizer.modifiers(from: []), [])
        XCTAssertEqual(KeyboardEventNormalizer.modifiers(from: [.command, .shift]), [.command, .shift])
        XCTAssertEqual(KeyboardEventNormalizer.modifiers(from: [.control, .option, .capsLock]), [.control, .option])
        XCTAssertEqual(KeyboardEventNormalizer.modifiers(from: [.command, .option, .control, .shift]), .all)
    }

    func testModifierTransitions() {
        XCTAssertEqual(
            KeyboardEventNormalizer.transitions(from: [.command], to: [.command, .shift]),
            [.modifierDown(.shift)]
        )
        XCTAssertEqual(
            KeyboardEventNormalizer.transitions(from: [.command, .shift], to: []),
            [.modifierUp(.command), .modifierUp(.shift)]
        )
    }

    func testSpecialKeyFormatting() {
        let formatter = KeyFormatter()
        XCTAssertEqual(formatter.string(for: .k), "K")
        XCTAssertEqual(formatter.string(for: .escape), "Escape")
        XCTAssertEqual(formatter.string(for: .returnKey), "Return")
        XCTAssertEqual(formatter.string(for: .tab), "Tab")
        XCTAssertEqual(formatter.string(for: .space), "Space")
        XCTAssertEqual(formatter.string(for: .leftArrow), "←")
        XCTAssertEqual(formatter.string(for: Key(keyCode: 122)), "F1")
        let shortcutFormatter = ShortcutFormatter()
        let shortcut = Shortcut(key: .escape, modifiers: [.command, .shift])
        XCTAssertEqual(shortcutFormatter.string(for: shortcut), "⌘⇧Escape")
        XCTAssertEqual(shortcutFormatter.components(for: shortcut), ["⌘", "⇧", "Escape"])
        XCTAssertEqual(
            shortcutFormatter.string(for: RecordingState(modifiers: [.command, .shift])),
            "⌘⇧"
        )
        XCTAssertFalse(KeyFormatter(layout: .current).string(for: .k).isEmpty)
        XCTAssertEqual(
            shortcutFormatter.string(for: RecordingState(
                modifiers: [.command],
                pressedKeys: [.escape, .returnKey]
            )),
            "⌘ReturnEscape"
        )
        XCTAssertEqual(formatter.string(for: .quote), "'")
        XCTAssertEqual(formatter.string(for: .deleteForward), "Forward Delete")
        XCTAssertEqual(formatter.string(for: .keypadEnter), "Enter")
        XCTAssertEqual(formatter.string(for: .volumeUp), "Volume Up")
        XCTAssertEqual(formatter.string(for: .jisYen), "¥")
        XCTAssertEqual(formatter.string(for: .jisEisu), "英数")
        XCTAssertEqual(formatter.string(for: .jisKana), "かな")

        let specialKeys: [Key] = [
            .returnKey, .tab, .space, .delete, .deleteForward, .escape, .help,
            .isoSection, .jisYen, .jisUnderscore, .jisKeypadComma, .jisEisu, .jisKana,
            .home, .end, .pageUp, .pageDown, .leftArrow, .rightArrow, .upArrow,
            .downArrow, .mute, .volumeUp, .volumeDown,
            .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
            .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20,
            .keypad0, .keypad1, .keypad2, .keypad3, .keypad4, .keypad5,
            .keypad6, .keypad7, .keypad8, .keypad9, .keypadClear,
            .keypadDecimal, .keypadDivide, .keypadEnter, .keypadEquals,
            .keypadMinus, .keypadMultiply, .keypadPlus,
        ]
        for key in specialKeys {
            XCTAssertFalse(formatter.string(for: key).hasPrefix("Key "), "Missing label for \(key)")
        }
    }
}

final class NamedShortcutTests: XCTestCase {
    @MainActor
    func testRegistrationErrorMapping() {
        XCTAssertEqual(
            GlobalShortcutManager.registrationError(for: OSStatus(eventHotKeyExistsErr)),
            .unavailable
        )
        XCTAssertEqual(
            GlobalShortcutManager.registrationError(for: OSStatus(eventHotKeyInvalidErr)),
            .invalidShortcut
        )
        XCTAssertEqual(
            GlobalShortcutManager.registrationError(for: -1),
            .system(status: -1)
        )
    }

    @MainActor
    func testUnknownModifierBitsAreInvalid() {
        let shortcut = Shortcut(key: .f17, modifiers: Modifiers(rawValue: 1 << 7))
        XCTAssertThrowsError(try Shortcuts.register(shortcut) {}) {
            XCTAssertEqual($0 as? Shortcuts.RegistrationError, .invalidShortcut)
        }
    }

    @MainActor
    func testGlobalShortcutPhaseMapping() {
        XCTAssertEqual(
            GlobalShortcutManager.phase(for: UInt32(kEventHotKeyPressed)),
            .keyDown
        )
        XCTAssertEqual(
            GlobalShortcutManager.phase(for: UInt32(kEventHotKeyReleased)),
            .keyUp
        )
        XCTAssertNil(GlobalShortcutManager.phase(for: UInt32.max))
    }

    @MainActor
    func testDuplicateRegistrationFailsWhileSuspended() throws {
        let shortcut = Shortcut(key: .f18, modifiers: .all)
        let name = Shortcuts.Name("test.\(UUID().uuidString)", default: shortcut)
        let recorder = ShortcutRecordingSession(monitor: TestMonitor())
        recorder.start()
        defer { recorder.stop() }

        try Shortcuts.register(name) {}
        defer { Shortcuts.unregister(name) }

        XCTAssertThrowsError(try Shortcuts.register(shortcut) {}) {
            XCTAssertEqual($0 as? Shortcuts.RegistrationError, .unavailable)
        }
    }

    @MainActor
    func testInMemoryRegistrationIsRetainedUntilUnregistered() throws {
        let shortcut = Shortcut(key: .f20, modifiers: .all)
        let initialCount = GlobalShortcutManager.shared.registrationCount

        try Shortcuts.register(shortcut) {}
        defer { Shortcuts.unregister(shortcut) }
        XCTAssertEqual(GlobalShortcutManager.shared.registrationCount, initialCount + 1)

        try Shortcuts.register(shortcut, onEvent: { _ in })
        XCTAssertEqual(GlobalShortcutManager.shared.registrationCount, initialCount + 1)

        Shortcuts.unregister(shortcut)
        XCTAssertEqual(GlobalShortcutManager.shared.registrationCount, initialCount)
    }

    @MainActor
    func testDefaultPersistenceClearAndReset() throws {
        let defaultShortcut = Shortcut(key: Key(keyCode: 40), modifiers: [.command])
        let customShortcut = Shortcut(key: Key(keyCode: 1), modifiers: [.control, .option])
        let name = Shortcuts.Name("test.\(UUID().uuidString)", default: defaultShortcut)

        XCTAssertEqual(Shortcuts.shortcut(for: name), defaultShortcut)

        try Shortcuts.set(customShortcut, for: name)
        XCTAssertEqual(Shortcuts.shortcut(for: name), customShortcut)

        try Shortcuts.set(nil, for: name)
        XCTAssertNil(Shortcuts.shortcut(for: name))

        try Shortcuts.reset(name)
        XCTAssertEqual(Shortcuts.shortcut(for: name), defaultShortcut)
    }
}

final class RecordingTests: XCTestCase {
    @MainActor
    func testModifierEventUpdatesStateBeforeCallback() throws {
        let monitor = TestMonitor()
        let recorder = ShortcutRecordingSession(monitor: monitor)
        var modifiersInCallback: Modifiers?
        recorder.onEvent = { event in
            if event == .modifierDown(.command) {
                modifiersInCallback = recorder.state.modifiers
            }
        }
        recorder.start()
        defer { recorder.stop() }

        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .flagsChanged,
            location: .zero,
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: UInt16(kVK_Command)
        ))
        monitor.send(event)

        XCTAssertEqual(modifiersInCallback, .command)
    }

    @MainActor
    func testStateTransitionsAndCommit() {
        let monitor = TestMonitor()
        let recorder = ShortcutRecordingSession(policy: RecordingPolicy(), monitor: monitor)
        var states: [RecordingState] = []
        var commits: [Shortcut] = []
        recorder.onChange = { states.append($0) }
        recorder.onCommit = { commits.append($0) }

        recorder.start()
        defer { recorder.stop() }
        XCTAssertTrue(GlobalShortcutManager.shared.isSuspended)
        recorder.process(.modifierDown(.command))
        recorder.process(.modifierDown(.shift))
        recorder.process(.keyDown(Key(keyCode: 40)))
        recorder.process(.keyDown(Key(keyCode: 40)), isRepeat: true)
        recorder.process(.keyUp(Key(keyCode: 40)))
        recorder.process(.modifierUp(.shift))
        recorder.process(.modifierUp(.command))

        XCTAssertEqual(commits, [Shortcut(key: Key(keyCode: 40), modifiers: [.command, .shift])])
        XCTAssertEqual(states.last, RecordingState())
        XCTAssertTrue(monitor.didStart)
    }

    @MainActor
    func testInvalidCommits() {
        let recorder = ShortcutRecordingSession(policy: RecordingPolicy(), monitor: TestMonitor())
        var commits: [Shortcut] = []
        recorder.onCommit = { commits.append($0) }
        recorder.start()
        defer { recorder.stop() }

        recorder.process(.keyDown(Key(keyCode: 40)))
        recorder.process(.keyUp(Key(keyCode: 40)))
        recorder.process(.modifierDown(.command))
        recorder.process(.keyDown(Key(keyCode: 40)), isRepeat: true)
        recorder.process(.keyDown(Key(keyCode: 1)))

        XCTAssertTrue(commits.isEmpty)
    }

    @MainActor
    func testRegistrationFailureIsReportedWhenRestoring() throws {
        let shortcut = Shortcut(key: .f19, modifiers: .all)
        try Shortcuts.register(shortcut) {}
        defer { Shortcuts.unregister(shortcut) }

        let recorder = ShortcutRecordingSession(monitor: TestMonitor())
        var failedShortcut: Shortcut?
        var registrationError: Shortcuts.RegistrationError?
        recorder.onRegistrationFailure = {
            failedShortcut = $0
            registrationError = $1
        }
        recorder.start()
        defer {
            if recorder.isRecording {
                recorder.stop()
            }
        }

        var competingRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(shortcut.key.keyCode),
            GlobalShortcutManager.modifierFlags(from: shortcut.modifiers),
            EventHotKeyID(signature: 0x5445_5354, id: 1),
            GetApplicationEventTarget(),
            0,
            &competingRef
        )
        XCTAssertEqual(status, noErr)
        let registeredCompetingRef = try XCTUnwrap(competingRef)
        defer {
            if let competingRef {
                UnregisterEventHotKey(competingRef)
            }
        }

        recorder.stop()

        XCTAssertEqual(failedShortcut, shortcut)
        XCTAssertEqual(registrationError, .unavailable)

        UnregisterEventHotKey(registeredCompetingRef)
        competingRef = nil
        try Shortcuts.register(shortcut) {}

        var probeRef: EventHotKeyRef?
        let probeStatus = RegisterEventHotKey(
            UInt32(shortcut.key.keyCode),
            GlobalShortcutManager.modifierFlags(from: shortcut.modifiers),
            EventHotKeyID(signature: 0x5445_5354, id: 2),
            GetApplicationEventTarget(),
            0,
            &probeRef
        )
        if let probeRef {
            UnregisterEventHotKey(probeRef)
        }
        XCTAssertEqual(probeStatus, OSStatus(eventHotKeyExistsErr))
    }

    @MainActor
    func testRecordingSuspendsAndRestoresGlobalShortcuts() {
        let recorder = ShortcutRecordingSession(monitor: TestMonitor())

        recorder.start()
        XCTAssertTrue(GlobalShortcutManager.shared.isSuspended)

        recorder.stop()
        XCTAssertFalse(GlobalShortcutManager.shared.isSuspended)
    }

    @MainActor
    func testEscapeAndBareReturnCancel() {
        let monitor = TestMonitor()
        let recorder = ShortcutRecordingSession(monitor: monitor)
        var cancellationCount = 0
        var events: [RecordingEvent] = []
        recorder.onCancel = { cancellationCount += 1 }
        recorder.onEvent = { events.append($0) }

        for key in [Key.escape, .return, .keypadEnter] {
            recorder.start()
            recorder.process(.keyDown(key))
            XCTAssertFalse(recorder.isRecording)
        }

        XCTAssertEqual(cancellationCount, 3)
        XCTAssertEqual(events, [.keyDown(.escape), .keyDown(.return), .keyDown(.keypadEnter)])
        XCTAssertTrue(monitor.didStop)

        var committed: Shortcut?
        recorder.onCommit = { committed = $0 }
        recorder.start()
        recorder.process(.modifierDown(.command))
        recorder.process(.keyDown(.return))
        recorder.stop()

        XCTAssertEqual(committed, Shortcut(key: .return, modifiers: .command))
    }
}

@MainActor
private final class TestMonitor: KeyboardEventMonitoring {
    var didStart = false
    var didStop = false
    private var handler: ((NSEvent) -> Void)?

    func start(handler: @escaping (NSEvent) -> Void) {
        didStart = true
        self.handler = handler
    }

    func stop() {
        didStop = true
        handler = nil
    }

    func send(_ event: NSEvent) {
        handler?(event)
    }
}

private extension ShortcutRecordingSession {
    convenience init(monitor: KeyboardEventMonitoring) {
        self.init(policy: RecordingPolicy(), monitor: monitor)
    }
}

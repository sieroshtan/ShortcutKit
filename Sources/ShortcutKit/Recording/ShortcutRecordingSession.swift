import AppKit
import Observation

/// A headless, local keyboard-shortcut recording session.
///
/// Recording runs only after ``start()`` and while the app is active. It does
/// not need Accessibility permission. Use ``state`` or ``onChange`` to update
/// your SwiftUI or AppKit UI. Use ``Shortcuts`` to register global shortcuts.
@MainActor
@Observable
public final class ShortcutRecordingSession {
    public private(set) var isRecording = false
    public private(set) var state = RecordingState()
    public var policy: RecordingPolicy

    /// Called when the current keys or modifiers change.
    public var onChange: (@MainActor (RecordingState) -> Void)?
    /// Called for each key or modifier down and up event.
    public var onEvent: (@MainActor (RecordingEvent) -> Void)?
    /// Called once for each valid key press. Repeated events are ignored.
    public var onCommit: (@MainActor (Shortcut) -> Void)?
    /// Called when recording is cancelled.
    public var onCancel: (@MainActor () -> Void)?
    /// Called when a global shortcut cannot be registered again after recording.
    public var onRegistrationFailure: (@MainActor (Shortcut, Shortcuts.RegistrationError) -> Void)?

    private let monitor: KeyboardEventMonitoring
    @ObservationIgnored
    private var hasSuspendedGlobalShortcuts = false

    public convenience init(policy: RecordingPolicy = RecordingPolicy()) {
        self.init(policy: policy, monitor: KeyboardEventMonitor())
    }

    init(policy: RecordingPolicy, monitor: KeyboardEventMonitoring) {
        self.policy = policy
        self.monitor = monitor
    }

    /// Clears the state, pauses ShortcutKit global shortcuts, and starts recording.
    public func start() {
        guard !isRecording else { return }
        state = RecordingState()
        GlobalShortcutManager.shared.suspend()
        hasSuspendedGlobalShortcuts = true
        isRecording = true
        monitor.start { [weak self] event in
            self?.handle(event)
        }
        onChange?(state)
    }

    /// Stops recording and registers the paused global shortcuts again. Keeps the last state.
    public func stop() {
        guard isRecording else { return }
        monitor.stop()
        let failures = GlobalShortcutManager.shared.resume()
        hasSuspendedGlobalShortcuts = false
        isRecording = false
        for failure in failures {
            onRegistrationFailure?(failure.shortcut, failure.error)
        }
    }

    /// Stops recording and calls ``onCancel``.
    public func cancel() {
        guard isRecording else { return }
        stop()
        onCancel?()
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            process(.keyDown(KeyboardEventNormalizer.key(from: event)), isRepeat: event.isARepeat)
        case .keyUp:
            process(.keyUp(KeyboardEventNormalizer.key(from: event)))
        case .flagsChanged:
            let modifiers = KeyboardEventNormalizer.modifiers(from: event.modifierFlags)
            for transition in KeyboardEventNormalizer.transitions(from: state.modifiers, to: modifiers) {
                process(transition)
            }
        default:
            break
        }
    }

    func process(_ event: RecordingEvent, isRepeat: Bool = false) {
        guard isRecording else { return }
        switch event {
        case let .keyDown(key):
            if key == .escape || (state.modifiers.isEmpty && (key == .return || key == .keypadEnter)) {
                onEvent?(event)
                cancel()
                return
            }
            let inserted = state.pressedKeys.insert(key).inserted
            onEvent?(event)
            onChange?(state)
            guard inserted, !isRepeat, state.pressedKeys.count == 1,
                  !policy.requiresModifier || !state.modifiers.isEmpty,
                  state.modifiers.subtracting(policy.allowedModifiers).isEmpty
            else { return }
            onCommit?(Shortcut(key: key, modifiers: state.modifiers))

        case let .keyUp(key):
            state.pressedKeys.remove(key)
            onEvent?(event)
            onChange?(state)

        case let .modifierDown(modifier):
            state.modifiers.insert(Modifiers(modifier))
            onEvent?(event)
            onChange?(state)

        case let .modifierUp(modifier):
            state.modifiers.remove(Modifiers(modifier))
            onEvent?(event)
            onChange?(state)
        }
    }

    deinit {
        let shouldResumeGlobalShortcuts = hasSuspendedGlobalShortcuts
        Task { @MainActor [monitor] in
            monitor.stop()
            if shouldResumeGlobalShortcuts {
                _ = GlobalShortcutManager.shared.resume()
            }
        }
    }
}

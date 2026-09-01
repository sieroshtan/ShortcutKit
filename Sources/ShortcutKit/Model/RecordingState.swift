/// The keys and modifiers held during recording.
public struct RecordingState: Equatable, Sendable {
    public var modifiers: Modifiers
    public var pressedKeys: Set<Key>

    public init(modifiers: Modifiers = [], pressedKeys: Set<Key> = []) {
        self.modifiers = modifiers
        self.pressedKeys = pressedKeys
    }
}

/// A key or modifier event during recording.
public enum RecordingEvent: Equatable, Sendable {
    case keyDown(Key)
    case keyUp(Key)
    case modifierDown(Modifier)
    case modifierUp(Modifier)
}

/// Rules for deciding which key presses create shortcuts.
public struct RecordingPolicy: Sendable {
    public var requiresModifier: Bool
    public var allowedModifiers: Modifiers

    public init(requiresModifier: Bool = true, allowedModifiers: Modifiers = .all) {
        self.requiresModifier = requiresModifier
        self.allowedModifiers = allowedModifiers
    }
}

/// A keyboard shortcut.
///
/// Use ``ShortcutRecordingSession`` to create shortcuts from local keyboard
/// input.
public struct Shortcut: Hashable, Codable, Sendable {
    public let key: Key
    public let modifiers: Modifiers

    public init(key: Key, modifiers: Modifiers) {
        self.key = key
        self.modifiers = modifiers
    }
}

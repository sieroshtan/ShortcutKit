/// Formats shortcuts using standard macOS modifier symbols.
public struct ShortcutFormatter: Sendable {
    private let keyFormatter: KeyFormatter

    public init(layout: KeyFormatter.Layout = .english) {
        keyFormatter = KeyFormatter(layout: layout)
    }

    public init(keyFormatter: KeyFormatter) {
        self.keyFormatter = keyFormatter
    }

    @MainActor
    public func string(for shortcut: Shortcut) -> String {
        components(for: shortcut).joined()
    }

    @MainActor
    public func string(for state: RecordingState) -> String {
        components(for: state).joined()
    }

    @MainActor
    public func components(for shortcut: Shortcut) -> [String] {
        modifierComponents(for: shortcut.modifiers) + [keyFormatter.string(for: shortcut.key)]
    }

    @MainActor
    public func components(for state: RecordingState) -> [String] {
        modifierComponents(for: state.modifiers) + state.pressedKeys
            .sorted { $0.keyCode < $1.keyCode }
            .map { keyFormatter.string(for: $0) }
    }

    private func modifierComponents(for modifiers: Modifiers) -> [String] {
        var result: [String] = []
        if modifiers.contains(.command) {
            result.append("⌘")
        }
        if modifiers.contains(.option) {
            result.append("⌥")
        }
        if modifiers.contains(.control) {
            result.append("⌃")
        }
        if modifiers.contains(.shift) {
            result.append("⇧")
        }
        return result
    }
}

import AppKit
import Carbon.HIToolbox

/// Checks if a shortcut conflicts with macOS or an app menu.
public enum ShortcutValidator {
    public enum Conflict: Equatable, Sendable {
        /// An enabled shortcut from System Settings uses this combination.
        case system
        /// A menu item uses this combination.
        case menuItem(title: String)
    }

    /// Checks enabled macOS shortcuts and the app's main menu.
    @MainActor
    public static func conflict(for shortcut: Shortcut) -> Conflict? {
        conflict(for: shortcut, in: NSApp.mainMenu)
    }

    /// Checks enabled macOS shortcuts and a specific menu.
    ///
    /// Pass `nil` to check only enabled macOS shortcuts.
    @MainActor
    public static func conflict(for shortcut: Shortcut, in menu: NSMenu?) -> Conflict? {
        conflict(for: shortcut, in: menu, systemHotKeys: systemHotKeys())
    }

    @MainActor
    static func conflict(
        for shortcut: Shortcut,
        in menu: NSMenu?,
        systemHotKeys: [[String: Any]]
    ) -> Conflict? {
        if isTakenBySystem(shortcut, systemHotKeys: systemHotKeys) {
            return .system
        }
        if let menu, let item = matchingMenuItem(for: shortcut, in: menu) {
            return .menuItem(title: item.title)
        }
        return nil
    }

    @MainActor
    static func isTakenBySystem(
        _ shortcut: Shortcut,
        systemHotKeys: [[String: Any]]
    ) -> Bool {
        let keyCode = Int(shortcut.key.keyCode)
        let modifiers = Int(GlobalShortcutManager.modifierFlags(from: shortcut.modifiers))

        return systemHotKeys.contains { hotKey in
            (hotKey[kHISymbolicHotKeyEnabled] as? Bool) == true
                && hotKey[kHISymbolicHotKeyCode] as? Int == keyCode
                && hotKey[kHISymbolicHotKeyModifiers] as? Int == modifiers
        }
    }

    @MainActor
    private static func systemHotKeys() -> [[String: Any]] {
        var value: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&value) == noErr,
              let hotKeys = value?.takeRetainedValue() as? [[String: Any]]
        else { return [] }
        return hotKeys
    }

    @MainActor
    private static func matchingMenuItem(for shortcut: Shortcut, in menu: NSMenu) -> NSMenuItem? {
        guard let expectedKey = menuKeyEquivalent(for: shortcut.key) else { return nil }
        let expectedModifiers = cocoaModifiers(from: shortcut.modifiers)

        for item in menu.items {
            var key = item.keyEquivalent
            var modifiers = item.keyEquivalentModifierMask.intersection(supportedCocoaModifiers)
            if key != key.lowercased() {
                key = key.lowercased()
                modifiers.insert(.shift)
            }

            if key == expectedKey.lowercased(), modifiers == expectedModifiers {
                return item
            }
            if let submenu = item.submenu,
               let match = matchingMenuItem(for: shortcut, in: submenu)
            {
                return match
            }
        }
        return nil
    }

    @MainActor
    private static func menuKeyEquivalent(for key: Key) -> String? {
        if let equivalent = menuKeyEquivalents[key] {
            return equivalent
        }
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let equivalent = KeyFormatter.translatedString(for: key, using: source),
              equivalent.count == 1
        else { return nil }
        return equivalent
    }

    private static func cocoaModifiers(from modifiers: Modifiers) -> NSEvent.ModifierFlags {
        var result: NSEvent.ModifierFlags = []
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        return result
    }

    private static let supportedCocoaModifiers: NSEvent.ModifierFlags = [
        .command,
        .option,
        .control,
        .shift,
    ]

    private static func functionKeyEquivalent(_ value: Int) -> String {
        String(UnicodeScalar(value)!)
    }

    private static let menuKeyEquivalents: [Key: String] = [
        .returnKey: "↩",
        .tab: "⇥",
        .space: " ",
        .delete: "⌫",
        .deleteForward: "⌦",
        .escape: "⎋",
        .help: "?⃝",
        .home: "↖",
        .end: "↘",
        .pageUp: "⇞",
        .pageDown: "⇟",
        .leftArrow: "←",
        .rightArrow: "→",
        .upArrow: "↑",
        .downArrow: "↓",
        .f1: functionKeyEquivalent(NSF1FunctionKey),
        .f2: functionKeyEquivalent(NSF2FunctionKey),
        .f3: functionKeyEquivalent(NSF3FunctionKey),
        .f4: functionKeyEquivalent(NSF4FunctionKey),
        .f5: functionKeyEquivalent(NSF5FunctionKey),
        .f6: functionKeyEquivalent(NSF6FunctionKey),
        .f7: functionKeyEquivalent(NSF7FunctionKey),
        .f8: functionKeyEquivalent(NSF8FunctionKey),
        .f9: functionKeyEquivalent(NSF9FunctionKey),
        .f10: functionKeyEquivalent(NSF10FunctionKey),
        .f11: functionKeyEquivalent(NSF11FunctionKey),
        .f12: functionKeyEquivalent(NSF12FunctionKey),
        .f13: functionKeyEquivalent(NSF13FunctionKey),
        .f14: functionKeyEquivalent(NSF14FunctionKey),
        .f15: functionKeyEquivalent(NSF15FunctionKey),
        .f16: functionKeyEquivalent(NSF16FunctionKey),
        .f17: functionKeyEquivalent(NSF17FunctionKey),
        .f18: functionKeyEquivalent(NSF18FunctionKey),
        .f19: functionKeyEquivalent(NSF19FunctionKey),
        .f20: functionKeyEquivalent(NSF20FunctionKey),
    ]
}

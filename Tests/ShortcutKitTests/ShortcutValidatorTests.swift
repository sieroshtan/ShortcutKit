import AppKit
import Carbon.HIToolbox
import XCTest
@testable import ShortcutKit

final class ShortcutValidatorTests: XCTestCase {
    @MainActor
    func testFindsEnabledSystemConflict() {
        let shortcut = Shortcut(key: .k, modifiers: .command)
        let hotKey: [String: Any] = [
            kHISymbolicHotKeyEnabled: true,
            kHISymbolicHotKeyCode: Int(shortcut.key.keyCode),
            kHISymbolicHotKeyModifiers: Int(cmdKey),
        ]

        XCTAssertEqual(
            ShortcutValidator.conflict(for: shortcut, in: nil, systemHotKeys: [hotKey]),
            .system
        )

        var disabledHotKey = hotKey
        disabledHotKey[kHISymbolicHotKeyEnabled] = false
        XCTAssertNil(
            ShortcutValidator.conflict(for: shortcut, in: nil, systemHotKeys: [disabledHotKey])
        )
    }

    @MainActor
    func testFindsNestedMenuConflict() {
        let menu = NSMenu()
        let submenu = NSMenu()
        let parent = NSMenuItem(title: "Parent", action: nil, keyEquivalent: "")
        let item = NSMenuItem(title: "Open Panel", action: nil, keyEquivalent: "K")
        item.keyEquivalentModifierMask = [.command]
        submenu.addItem(item)
        parent.submenu = submenu
        menu.addItem(parent)

        XCTAssertEqual(
            ShortcutValidator.conflict(
                for: Shortcut(key: .k, modifiers: [.command, .shift]),
                in: menu,
                systemHotKeys: []
            ),
            .menuItem(title: "Open Panel")
        )
    }
}

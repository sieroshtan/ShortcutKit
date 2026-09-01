import Observation
import ShortcutKit
import SwiftUI

@main
struct ShortcutKitExampleApp: App {
    @State private var model = ExampleModel()

    var body: some Scene {
        WindowGroup {
            TabView {
                SwiftUIExampleView(model: model)
                    .tabItem { Label("SwiftUI", systemImage: "swift") }

                AppKitExampleView(model: model)
                    .tabItem { Label("AppKit", systemImage: "macwindow") }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .defaultSize(width: 420, height: 300)
    }
}

@MainActor
@Observable
final class ExampleModel {
    var swiftUIAction: String?
    var appKitAction: String?
    var isSwiftUIShortcutPressed = false
    var isAppKitShortcutPressed = false

    init() {
        do {
//            try Shortcuts.register(.swiftUIExample) { [weak self] in
//                self?.swiftUIAction = "SwiftUI shortcut triggered"
//            }
            try Shortcuts.register(.swiftUIExample, onEvent: { [weak self] phase in
                switch phase {
                case .keyDown:
                    self?.isSwiftUIShortcutPressed = true
                    self?.swiftUIAction = "Shortcut pressed"
                case .keyUp:
                    self?.isSwiftUIShortcutPressed = false
                    self?.swiftUIAction = "Shortcut released"
                }
            })
        } catch {
            swiftUIAction = "Registration failed: \(error)"
        }

        do {
            try Shortcuts.register(.appKitExample, onEvent: { [weak self] phase in
                switch phase {
                case .keyDown:
                    self?.isAppKitShortcutPressed = true
                    self?.appKitAction = "Shortcut pressed"
                case .keyUp:
                    self?.isAppKitShortcutPressed = false
                    self?.appKitAction = "Shortcut released"
                }
            })
        } catch {
            appKitAction = "Registration failed: \(error)"
        }
    }
}

extension Shortcuts.Name {
    static let swiftUIExample = Self(
        "example.swiftUI",
        default: Shortcut(key: .k, modifiers: [.command, .shift])
    )

    static let appKitExample = Self(
        "example.appKit",
        default: Shortcut(key: .j, modifiers: [.command, .shift])
    )
}

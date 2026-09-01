import AppKit
import ShortcutKit
import SwiftUI

struct SwiftUIExampleView: View {
    let model: ExampleModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("SwiftUI Recorder")
                    .font(.title.bold())
                Text("A custom view driven by ShortcutRecordingSession.")
                    .foregroundStyle(.secondary)
            }

            ShortcutRecorderView(
                name: .swiftUIExample,
                isPressed: model.isSwiftUIShortcutPressed,
                onChange: { _ in model.swiftUIAction = nil }
            )

            Text(model.swiftUIAction ?? "SwiftUI shortcut released")
                .font(.callout)
                .foregroundStyle(.secondary)
                .opacity(model.swiftUIAction == nil ? 0 : 1)
                .accessibilityHidden(model.swiftUIAction == nil)
        }
        .padding(40)
    }
}

struct ShortcutRecorderView: View {
    let name: Shortcuts.Name
    let isPressed: Bool
    let onChange: (Shortcut?) -> Void

    @State private var shortcut: Shortcut?
    @State private var hoveredClearButton = false
    @State private var errorMessage: String?
    @State private var recorder = ShortcutRecordingSession()

    private let formatter = ShortcutFormatter(layout: .current)

    init(
        name: Shortcuts.Name,
        isPressed: Bool,
        onChange: @escaping (Shortcut?) -> Void
    ) {
        self.name = name
        self.isPressed = isPressed
        self.onChange = onChange
        _shortcut = State(initialValue: Shortcuts.shortcut(for: name))
    }

    var body: some View {
        VStack(spacing: 16) {
            ShortcutKeyCaps(labels: shortcutComponents, isPressed: isPressed)

            recorderControl
        }
        .onAppear {
            recorder.onCommit = saveShortcut
            recorder.onRegistrationFailure = { _, _ in
                errorMessage = "That shortcut could not be restored because it is now in use."
            }
        }
        .onDisappear {
            recorder.stop()
        }
        .alert("Unable to Record Shortcut", isPresented: Binding(
            get: { errorMessage != nil },
            set: {
                if !$0 {
                    errorMessage = nil
                }
            }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var recorderControl: some View {
        ZStack {
            Button(action: toggleRecording) {
                Text(shortcutText.isEmpty ? (recorder.isRecording ? "Recording…" : "Record") : shortcutText)
                    .foregroundStyle(shortcutText.isEmpty ? .secondary : .primary)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 150, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)

            if shortcut != nil || recorder.isRecording {
                Button(action: clearOrCancel) {
                    Image(systemName: recorder.isRecording ? "escape" : "xmark")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.secondary)
                        .frame(width: 19, height: 19)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.secondary.opacity(hoveredClearButton ? 0.3 : 0.2))
                        )
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help(recorder.isRecording ? "Cancel recording" : "Clear shortcut")
                .onHover { hoveredClearButton = $0 }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
            }
        }
        .frame(width: 150, height: 26)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color(nsColor: .separatorColor))
        }
    }

    private var shortcutComponents: [String] {
        if recorder.isRecording {
            return formatter.components(for: recorder.state)
        }
        return shortcut.map(formatter.components(for:)) ?? []
    }

    private var shortcutText: String {
        shortcutComponents.joined()
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.cancel()
        } else {
            recorder.start()
        }
    }

    private func clearOrCancel() {
        if recorder.isRecording {
            recorder.cancel()
        } else {
            _ = save(nil)
        }
    }

    private func saveShortcut(_ shortcut: Shortcut) {
        if save(shortcut) {
            recorder.stop()
        }
    }

    private func save(_ shortcut: Shortcut?) -> Bool {
        do {
            try Shortcuts.set(shortcut, for: name)
            self.shortcut = shortcut
            onChange(shortcut)
            return true
        } catch {
            errorMessage = "That shortcut could not be registered. It may already be in use."
            return false
        }
    }
}

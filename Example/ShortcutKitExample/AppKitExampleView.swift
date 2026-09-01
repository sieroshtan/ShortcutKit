import AppKit
import ShortcutKit
import SwiftUI

struct AppKitExampleView: View {
    let model: ExampleModel

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("AppKit Recorder")
                    .font(.title.bold())
                Text("NSControl driven by ShortcutRecordingSession.")
                    .foregroundStyle(.secondary)
            }

            AppKitRecorderRepresentable(
                name: .appKitExample,
                isPressed: model.isAppKitShortcutPressed,
                onChange: { _ in model.appKitAction = nil }
            )
            .frame(width: 220, height: 84)

            Text(model.appKitAction ?? "AppKit shortcut released")
                .font(.callout)
                .foregroundStyle(.secondary)
                .opacity(model.appKitAction == nil ? 0 : 1)
                .accessibilityHidden(model.appKitAction == nil)
        }
        .padding(40)
    }
}

private struct AppKitRecorderRepresentable: NSViewRepresentable {
    let name: Shortcuts.Name
    let isPressed: Bool
    let onChange: (Shortcut?) -> Void

    func makeNSView(context _: Context) -> AppKitRecorderExampleView {
        AppKitRecorderExampleView(name: name, onChange: onChange)
    }

    func updateNSView(_ nsView: AppKitRecorderExampleView, context _: Context) {
        nsView.setPressed(isPressed)
    }
}

@MainActor
private final class AppKitRecorderExampleView: NSView {
    private let keyStack = NSStackView()
    private let recorderControl: AppKitShortcutRecorderControl
    private var isPressed = false

    init(name: Shortcuts.Name, onChange: @escaping (Shortcut?) -> Void) {
        recorderControl = AppKitShortcutRecorderControl(name: name)
        super.init(frame: .zero)
        buildView()

        recorderControl.onShortcutChange = onChange
        recorderControl.onDisplayChange = { [weak self] labels in
            self?.renderKeyCaps(labels: labels)
        }
        recorderControl.refresh()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func buildView() {
        keyStack.orientation = .horizontal
        keyStack.alignment = .centerY
        keyStack.spacing = 6

        let keyCapsContainer = NSView()
        keyCapsContainer.translatesAutoresizingMaskIntoConstraints = false
        keyStack.translatesAutoresizingMaskIntoConstraints = false
        keyCapsContainer.addSubview(keyStack)

        let content = NSStackView(views: [keyCapsContainer, recorderControl])
        content.orientation = .vertical
        content.alignment = .centerX
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
            keyCapsContainer.widthAnchor.constraint(equalToConstant: 220),
            keyCapsContainer.heightAnchor.constraint(equalToConstant: 42),
            keyStack.centerXAnchor.constraint(equalTo: keyCapsContainer.centerXAnchor),
            keyStack.centerYAnchor.constraint(equalTo: keyCapsContainer.centerYAnchor),
        ])
    }

    func setPressed(_ isPressed: Bool) {
        guard self.isPressed != isPressed else { return }
        self.isPressed = isPressed
        for case let keyCap as AppKitKeyCapView in keyStack.arrangedSubviews {
            keyCap.setPressed(isPressed, animated: true)
        }
    }

    private func renderKeyCaps(labels: [String]) {
        for arrangedSubview in keyStack.arrangedSubviews {
            keyStack.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        for label in labels {
            let keyCap = AppKitKeyCapView(label: label)
            keyCap.setPressed(isPressed, animated: false)
            keyStack.addArrangedSubview(keyCap)
        }
    }
}

@MainActor
private final class AppKitShortcutRecorderControl: NSControl {
    var onDisplayChange: (([String]) -> Void)?
    var onShortcutChange: ((Shortcut?) -> Void)?

    private let name: Shortcuts.Name
    private let recorder = ShortcutRecordingSession()
    private let shortcutFormatter = ShortcutFormatter(layout: .english)
    private let mainButton = NSButton()
    private let clearButton = SquareButton()
    private var shortcut: Shortcut?

    init(name: Shortcuts.Name) {
        self.name = name
        shortcut = Shortcuts.shortcut(for: name)
        super.init(frame: NSRect(x: 0, y: 0, width: 150, height: 26))
        buildControl()
        configureRecorder()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 150, height: 26)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            recorder.stop()
        }
    }

    func refresh() {
        render()
    }

    private func buildControl() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 7
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1

        mainButton.isBordered = false
        mainButton.font = .systemFont(ofSize: 12, weight: .medium)
        mainButton.target = self
        mainButton.action = #selector(toggleRecording)
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainButton)

        clearButton.isBordered = false
        clearButton.imagePosition = .imageOnly
        clearButton.imageScaling = .scaleProportionallyDown
        clearButton.contentTintColor = .secondaryLabelColor
        clearButton.target = self
        clearButton.action = #selector(clearOrCancel)
        clearButton.wantsLayer = true
        clearButton.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.2).cgColor
        clearButton.layer?.cornerRadius = 5
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.symbolConfiguration = .init(pointSize: 9, weight: .heavy)
        addSubview(clearButton)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 150),
            heightAnchor.constraint(equalToConstant: 26),
            mainButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainButton.topAnchor.constraint(equalTo: topAnchor),
            mainButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 19),
            clearButton.heightAnchor.constraint(equalToConstant: 19),
        ])
    }

    private func configureRecorder() {
        recorder.onChange = { [weak self] _ in
            self?.render()
        }
        recorder.onCommit = { [weak self] shortcut in
            self?.save(shortcut)
        }
        recorder.onCancel = { [weak self] in
            self?.render()
        }
        recorder.onRegistrationFailure = { [weak self] _, _ in
            self?.showRegistrationError(
                "That shortcut could not be restored because it is now in use."
            )
        }
    }

    @objc private func toggleRecording() {
        recorder.isRecording ? recorder.cancel() : recorder.start()
    }

    @objc private func clearOrCancel() {
        recorder.isRecording ? recorder.cancel() : save(nil)
    }

    private func save(_ shortcut: Shortcut?) {
        do {
            try Shortcuts.set(shortcut, for: name)
            self.shortcut = shortcut
            onShortcutChange?(shortcut)
            recorder.stop()
            render()
        } catch {
            showRegistrationError(
                "That shortcut could not be registered. It may already be in use."
            )
        }
    }

    private func showRegistrationError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Unable to Record Shortcut"
        alert.informativeText = message
        if let window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    private func render() {
        let components = recorder.isRecording
            ? shortcutFormatter.components(for: recorder.state)
            : shortcut.map(shortcutFormatter.components(for:)) ?? []
        let value = components.joined()

        mainButton.title = value.isEmpty
            ? (recorder.isRecording ? "Recording…" : "Record")
            : value
        mainButton.contentTintColor = value.isEmpty ? .secondaryLabelColor : .labelColor

        clearButton.isHidden = shortcut == nil && !recorder.isRecording
        clearButton.image = NSImage(
            systemSymbolName: recorder.isRecording ? "escape" : "xmark",
            accessibilityDescription: recorder.isRecording ? "Cancel recording" : "Clear shortcut"
        )
        clearButton.toolTip = recorder.isRecording ? "Cancel recording" : "Clear shortcut"
        onDisplayChange?(components)
    }
}

@MainActor
private final class SquareButton: NSButton {
    override var alignmentRectInsets: NSEdgeInsets {
        NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 19, height: 19)
    }
}

@MainActor
private final class AppKitKeyCapView: NSView {
    private let gradient = CAGradientLayer()
    private let textField: NSTextField
    private let keyWidth: CGFloat

    init(label: String) {
        keyWidth = label.count > 2 ? 50 : 34
        textField = NSTextField(labelWithString: label)
        super.init(frame: NSRect(x: 0, y: 0, width: keyWidth, height: 34))

        wantsLayer = true
        gradient.colors = [
            NSColor(white: 0.16, alpha: 1).cgColor,
            NSColor(white: 0.035, alpha: 1).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 1)
        gradient.endPoint = CGPoint(x: 0.5, y: 0)
        gradient.cornerRadius = 7
        gradient.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        gradient.borderWidth = 0.7
        gradient.shadowColor = NSColor.black.cgColor
        gradient.shadowOpacity = 0.38
        gradient.shadowRadius = 1
        gradient.shadowOffset = CGSize(width: 0, height: -2)
        layer?.addSublayer(gradient)

        textField.font = .systemFont(ofSize: 13, weight: .medium)
        textField.textColor = .white
        textField.alignment = .center
        textField.wantsLayer = true
        textField.layer?.opacity = 0.94
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: keyWidth, height: 34)
    }

    func setPressed(_ isPressed: Bool, animated: Bool) {
        let transform = isPressed
            ? CGAffineTransform(translationX: 0, y: -2).scaledBy(x: 0.97, y: 0.97)
            : .identity
        if animated, let layer {
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = layer.presentation()?.transform ?? layer.transform
            animation.toValue = CATransform3DMakeAffineTransform(transform)
            animation.duration = 0.1
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(animation, forKey: "pressed")
        }

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        CATransaction.setAnimationDuration(0.1)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))

        layer?.setAffineTransform(transform)
        gradient.colors = isPressed
            ? [NSColor(white: 0.08, alpha: 1).cgColor, NSColor(white: 0.025, alpha: 1).cgColor]
            : [NSColor(white: 0.16, alpha: 1).cgColor, NSColor(white: 0.035, alpha: 1).cgColor]
        gradient.borderColor = NSColor.white.withAlphaComponent(isPressed ? 0.07 : 0.14).cgColor
        gradient.shadowOpacity = isPressed ? 0.18 : 0.38
        gradient.shadowRadius = isPressed ? 0.5 : 1
        gradient.shadowOffset = CGSize(width: 0, height: isPressed ? -0.5 : -2)
        textField.layer?.opacity = isPressed ? 0.78 : 0.94

        CATransaction.commit()
    }

    override func layout() {
        super.layout()
        gradient.frame = bounds
    }
}

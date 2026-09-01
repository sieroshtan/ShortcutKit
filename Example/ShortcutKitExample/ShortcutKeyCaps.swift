import SwiftUI

struct ShortcutKeyCaps: View {
    let labels: [String]
    let isPressed: Bool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                MacShortcutKey(label: label, isPressed: isPressed)
            }
        }
        .frame(height: 42)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(labels.isEmpty ? "No shortcut set" : labels.joined())
    }
}

struct MacShortcutKey: View {
    let label: String
    let isPressed: Bool
    @State private var isHovered = false

    private var isDepressed: Bool {
        isPressed || isHovered
    }

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(isDepressed ? 0.78 : 0.94))
            .frame(width: label.count > 2 ? 50 : 34, height: 34)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isDepressed
                                ? [Color(white: 0.08), Color(white: 0.025)]
                                : [Color(white: 0.16), Color(white: 0.035)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color.white.opacity(isDepressed ? 0.07 : 0.14), lineWidth: 0.7)
                    }
                    .shadow(color: .black.opacity(isDepressed ? 0.18 : 0.38), radius: isDepressed ? 0.5 : 1, y: isDepressed ? 0.5 : 2)
            }
            .scaleEffect(isDepressed ? 0.97 : 1)
            .offset(y: isDepressed ? 2 : 0)
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.1), value: isDepressed)
    }
}

import SwiftUI

// Padded Liquid Glass container for arbitrary content.
struct Glass<Content: View>: View {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    // Glass that can be switched off. `glassEffect` takes no enabled flag, and
    // an `if` in the view body would change identity mid-animation.
    func glass<S: Shape>(_ enabled: Bool, in shape: S) -> some View {
        modifier(ConditionalGlass(enabled: enabled, shape: shape))
    }

    // Rounds an image and adds a subtle hairline border.
    func imageBorder(corner: CGFloat = Theme.corner) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(Theme.border)
            )
    }
}

private struct ConditionalGlass<S: Shape>: ViewModifier {
    let enabled: Bool
    let shape: S

    func body(content: Content) -> some View {
        if enabled {
            content.glassEffect(.regular, in: shape)
        } else {
            content
        }
    }
}

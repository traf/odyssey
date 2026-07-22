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

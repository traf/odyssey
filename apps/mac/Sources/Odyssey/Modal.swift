import SwiftUI

// Dimmed backdrop + centered rounded card. Click outside or Esc to dismiss.
struct Modal<Content: View>: View {
    var width: CGFloat = 420
    var onDismiss: () -> Void
    @ViewBuilder var content: Content

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            content
                .padding(20)
                .frame(width: width)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: Theme.corner))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.corner)
                        .strokeBorder(.white.opacity(0.08))
                )
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress(.escape) { onDismiss(); return .handled }
        .onAppear { focused = true }
    }
}

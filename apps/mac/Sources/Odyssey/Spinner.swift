import SwiftUI

// The app's only loading indicator: a slowly spinning Cosmos mark.
// Use this anywhere a spinner is needed — never a system ProgressView.
struct Spinner: View {
    var size: CGFloat = 20

    @State private var spinning = false

    var body: some View {
        CosmosMark()
            .fill(Theme.foreground)
            .frame(width: size, height: size * 16 / 15)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: spinning)
            .onAppear { spinning = true }
    }
}

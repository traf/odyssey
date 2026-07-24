import SwiftUI

// A light "beam" that continuously travels around a shape's border — a bright
// gradient arc orbiting the perimeter, fading to transparent. Matches the
// border-beam effect. Apply via `.borderBeam()`.
struct BorderBeam<S: InsettableShape>: ViewModifier {
    var shape: S
    var duration: Double = 6
    var lineWidth: CGFloat = 1

    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content.overlay {
            shape
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .clear, .clear, .clear, .clear, .clear,
                            Theme.accent.opacity(0.35),
                            .clear, .clear, .clear, .clear, .clear,
                        ]),
                        center: .center,
                        angle: .degrees(angle)
                    ),
                    lineWidth: lineWidth
                )
                .onAppear {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        angle = 360
                    }
                }
        }
    }
}

extension View {
    func borderBeam<S: InsettableShape>(in shape: S, duration: Double = 4, lineWidth: CGFloat = 1.5) -> some View {
        modifier(BorderBeam(shape: shape, duration: duration, lineWidth: lineWidth))
    }
}

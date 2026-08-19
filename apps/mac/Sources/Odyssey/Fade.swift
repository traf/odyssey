import SwiftUI
import AppKit
import QuartzCore

// Softens the grid where it runs off an edge of the window — under the toolbar
// at the top, off the sill at the bottom.
//
// The blur radius ramps, the opacity doesn't: this is a backdrop with a
// `variableBlur` filter, the same pair macOS draws for its own scroll edge
// effects (they show up in our window's layer tree). Fading a fixed-radius blur
// out by opacity instead leaves a half-transparent blur over sharp content,
// which reads as a milky wash rather than depth.
//
// Ours rather than the system's because the system's only blurs whatever
// happens to be behind it, so the effect came and went with the window state;
// this reads the same windowed, fullscreen, at the top of the grid or deep into
// a scroll.
struct Fade: View {
    var edge: VerticalEdge = .top

    var body: some View {
        Group {
            if VariableBlurView.isSupported {
                VariableBlur(edge: edge)
            } else {
                // No backdrop to ramp: a plain material, gradient-masked.
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        LinearGradient(
                            colors: [.black.opacity(0.8), .clear],
                            startPoint: edge == .top ? .top : .bottom,
                            endPoint: edge == .top ? .bottom : .top
                        )
                    )
            }
        }
        // A breath of shade with the blur, densest against the window edge, so
        // chrome has something to sit on over pale images. Eased off at the sides
        // like the blur is — shade that stopped square on the sidebar divider
        // drew a line down it.
        .overlay {
            LinearGradient(
                colors: [.black.opacity(Theme.fadeTint), .clear],
                startPoint: edge == .top ? .top : .bottom,
                endPoint: edge == .top ? .bottom : .top
            )
            .mask { SideTaper() }
        }
        .frame(height: Theme.fade)
        // Chrome, not content: never eat a click meant for a tile.
        .allowsHitTesting(false)
        // Reach out through the titlebar strip, where the tiles actually sit.
        .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
    }
}

// Opaque across the middle, easing to nothing over `Theme.fadeInset` at either
// side. Fixed-width ends around a flexible middle, so it needs no reader to know
// how wide it is.
private struct SideTaper: View {
    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: Theme.fadeInset)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: Theme.fadeInset)
        }
    }
}

private struct VariableBlur: NSViewRepresentable {
    let edge: VerticalEdge

    func makeNSView(context: Context) -> VariableBlurView { VariableBlurView(edge: edge) }
    func updateNSView(_ view: VariableBlurView, context: Context) {}
}

final class VariableBlurView: NSView {
    // Private CoreAnimation, so check before leaning on it and keep a fallback.
    static var isSupported: Bool {
        NSClassFromString("CABackdropLayer") != nil && NSClassFromString("CAFilter") != nil
    }

    private let edge: VerticalEdge
    private var ramped: CGSize = .zero

    init(edge: VerticalEdge) {
        self.edge = edge
        super.init(frame: .zero)
        wantsLayer = true
        // Sample the window at half resolution, as the system's own cheap blurs
        // do: a quarter of the pixels to blur every frame, and at this radius
        // there's nothing to see in the difference.
        layer?.setValue(0.5, forKey: "scale")
    }

    required init?(coder: NSCoder) { fatalError("Not loaded from a nib") }

    override func makeBackingLayer() -> CALayer {
        (NSClassFromString("CABackdropLayer") as? CALayer.Type)?.init() ?? CALayer()
    }

    // The mask is drawn at the strip's size, so it's rebuilt on resize but not on
    // every scroll.
    override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0, bounds.size != ramped else { return }
        ramped = bounds.size
        layer?.masksToBounds = true
        layer?.filters = filter(size: bounds.size).map { [$0] }
    }

    private func filter(size: CGSize) -> NSObject? {
        guard let filters = NSClassFromString("CAFilter") as? NSObject.Type,
              let filter = filters
                .perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?
                .takeUnretainedValue() as? NSObject,
              let ramp = ramp(size: size)
        else { return nil }

        filter.setValue(Theme.fadeBlur, forKey: "inputRadius")
        filter.setValue(ramp, forKey: "inputMaskImage")
        // Without this the blur samples past the strip and darkens its edges.
        filter.setValue(true, forKey: "inputNormalizeEdges")
        return filter
    }

    // Alpha is the radius, so the mask is where the shape of the effect lives:
    // strongest against the window edge and easing evenly across the strip, then
    // eased off sideways too. That last part matters — a blur that stopped dead
    // at the sidebar divider clamped its sampling there and smeared a bright
    // seam down it, and covering the sidebar instead ghosted the search field.
    private func ramp(size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let ramp = CGGradient(
                colorsSpace: space,
                colors: [CGColor(gray: 0, alpha: 1), CGColor(gray: 0, alpha: 0)] as CFArray,
                locations: [0, 1]
              )
        else { return nil }

        // Row zero is the top of the image and the context counts up from the
        // bottom, so the strong end sits at `height` for the top strip.
        let strong = edge == .top ? size.height : 0
        context.drawLinearGradient(
            ramp,
            start: CGPoint(x: 0, y: strong),
            end: CGPoint(x: 0, y: size.height - strong),
            options: []
        )

        // Multiply that down to nothing at either side. `destinationIn` scales
        // the alpha already there, and the fills run to the far edge so only the
        // inset itself is touched.
        context.setBlendMode(.destinationIn)
        context.drawLinearGradient(
            ramp,
            start: CGPoint(x: Theme.fadeInset, y: 0),
            end: .zero,
            options: .drawsBeforeStartLocation
        )
        context.drawLinearGradient(
            ramp,
            start: CGPoint(x: size.width - Theme.fadeInset, y: 0),
            end: CGPoint(x: size.width, y: 0),
            options: .drawsBeforeStartLocation
        )

        return context.makeImage()
    }
}

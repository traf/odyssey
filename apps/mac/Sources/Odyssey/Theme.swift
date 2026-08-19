import SwiftUI

// Single source of truth for colors, typography, and spacing.
enum Theme {
    // Color
    static let background = Color(red: 0.078, green: 0.078, blue: 0.078) // #141414
    static let foreground = Color.white
    static let accent = Color.white
    static let border = Color.white.opacity(0.1)

    // Font
    static let fontDesign: Font.Design = .rounded

    // Motion — one bouncy-but-fast spring reused everywhere.
    static let spring: Animation = .spring(response: 0.32, dampingFraction: 0.68)
    // Media reveal: images fade up as they decode. Not an interaction, so not the
    // spring — a bouncy curve on opacity overshoots and flickers at the top.
    static let reveal: Animation = .easeOut(duration: 0.35)

    // Spacing / sizing
    static let gap: CGFloat = 10
    static let corner: CGFloat = 20
    // Depth of the soft fade at each edge of the grid, and the blur radius it
    // reaches against the window edge.
    static let fade: CGFloat = 80
    static let fadeBlur: CGFloat = 4
    // Shade at the very edge, easing to nothing across the strip.
    static let fadeTint: Double = 0.4
    // How far in from the sides the fade eases up, so it never cuts on a divider.
    static let fadeInset: CGFloat = 24
    // Titlebar band, the glass controls sitting in it, and the mark's capsule —
    // wider than the controls are tall, and exactly as tall as they are.
    static let titlebar: CGFloat = 52
    static let control: CGFloat = 36
    static let markCapsule: CGFloat = 60
    static let mark: CGFloat = 20
    static let sortPadding: CGFloat = 10
    static let sortLabelGap: CGFloat = 6
    static let sortChevron: CGFloat = 8
    static let minWindow = CGSize(width: 960, height: 640)
}

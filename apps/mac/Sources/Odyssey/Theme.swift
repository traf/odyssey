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

    // Spacing / sizing
    static let gap: CGFloat = 10
    static let corner: CGFloat = 20
    static let minWindow = CGSize(width: 960, height: 640)
}

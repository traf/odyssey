import SwiftUI

// Cosmos logo: six dots. Scales to fit while preserving the 38×42 ratio.
struct CosmosMark: Shape {
    private static let viewBox = CGSize(width: 38, height: 42)
    private static let radius: CGFloat = 5.97
    private static let centers: [CGPoint] = [
        CGPoint(x: 19.025, y: 5.95),
        CGPoint(x: 19.025, y: 35.996),
        CGPoint(x: 5.97, y: 13.46),
        CGPoint(x: 32.08, y: 28.485),
        CGPoint(x: 32.08, y: 13.46),
        CGPoint(x: 5.97, y: 28.484),
    ]

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / Self.viewBox.width, rect.height / Self.viewBox.height)
        let offsetX = rect.minX + (rect.width - Self.viewBox.width * scale) / 2
        let offsetY = rect.minY + (rect.height - Self.viewBox.height * scale) / 2
        let r = Self.radius * scale

        var path = Path()
        for center in Self.centers {
            let c = CGPoint(x: offsetX + center.x * scale, y: offsetY + center.y * scale)
            path.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        }
        return path
    }
}

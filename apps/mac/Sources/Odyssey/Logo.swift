import SwiftUI

// The mark where it sits over the grid and the image behind it is anyone's
// guess. A glass capsule the height of the toolbar's own controls carries it,
// so it reads over light photography the way every other piece of chrome does.
struct Mark: View {
    var size: CGFloat = Theme.mark

    var body: some View {
        Logo(size: size)
            .frame(width: Theme.markCapsule, height: Theme.control)
            .glassEffect(.regular, in: .capsule)
    }
}

struct Logo: View {
    var size: CGFloat = 44

    var body: some View {
        if let url = Bundle.module.url(forResource: "logo", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(height: size)
        }
    }
}

import SwiftUI

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

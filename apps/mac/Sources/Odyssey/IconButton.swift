import SwiftUI

// Circular glass icon button, matching the native sidebar-toggle control.
struct IconButton<Content: View>: View {
    var action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        SwiftUI.Button(action: action) {
            content
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.foreground)
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: .circle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

extension IconButton where Content == Image {
    init(systemImage: String, action: @escaping () -> Void) {
        self.init(action: action) { Image(systemName: systemImage) }
    }
}

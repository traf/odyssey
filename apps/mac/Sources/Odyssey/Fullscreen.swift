import SwiftUI
import AppKit

// Publishes the window's fullscreen state so views can drop the titlebar
// clearance (there are no traffic lights / titlebar in fullscreen).
extension EnvironmentValues {
    @Entry var isFullscreen: Bool = false
}

struct FullscreenReader: ViewModifier {
    @State private var fullscreen = false

    func body(content: Content) -> some View {
        content
            .environment(\.isFullscreen, fullscreen)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
                fullscreen = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
                fullscreen = false
            }
    }
}

extension View {
    func readsFullscreen() -> some View { modifier(FullscreenReader()) }
}

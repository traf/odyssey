import SwiftUI
import AppKit

@main
struct OdysseyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model = GalleryModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 820)
        .commands {
            CommandGroup(replacing: .appSettings) {
                SwiftUI.Button("Settings…") {
                    guard model.hasProfile else { return }
                    withAnimation(Theme.spring) { model.showAccount = true }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                SwiftUI.Button("Search") {
                    guard model.hasProfile else { return }
                    withAnimation(Theme.spring) { model.focusSearch() }
                }
                .keyboardShortcut("f", modifiers: .command)
                SwiftUI.Button("Toggle Sidebar") { model.toggleSidebar() }
                    .keyboardShortcut("s", modifiers: .command)
                SwiftUI.Button("Zen Mode") { withAnimation(Theme.spring) { model.toggleZen() } }
                    .keyboardShortcut("z", modifiers: .command)
                Divider()
                SwiftUI.Button("Zoom In") { model.zoomIn() }
                    .keyboardShortcut("=", modifiers: .command)
                // ⌘+ alias (so Shift isn't required); hidden from the menu.
                SwiftUI.Button("") { model.zoomIn() }
                    .keyboardShortcut("+", modifiers: .command)
                    .hidden()
                SwiftUI.Button("Zoom Out") { model.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                SwiftUI.Button("Actual Size") { model.resetZoom() }
                    .keyboardShortcut("0", modifiers: .command)
                Divider()
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let url = Bundle.module.url(forResource: "icon", withExtension: "png"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first else { return }
            // Let content (the sidebar panel) draw up under the titlebar so the
            // traffic lights sit on it. Pure window chrome — no SwiftUI layout impact.
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.delegate = self
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    // In fullscreen NSToolbar draws an unremovable blur band that clashes with
    // our chrome. Auto-hide it so the content fills cleanly (revealed on hover
    // at the top edge). See the enter/exit notifications driving `isFullscreen`.
    func window(_ window: NSWindow,
                willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        [.autoHideToolbar, .autoHideMenuBar, .fullScreen]
    }
}

import SwiftUI
import AppKit

// The toolbar draws no background of its own: the fade under it is the `Fade`
// component, so keeping the system's scroll edge effect as well would stack two
// blurs over the same strip. (Leave it hidden — `.automatic` also reintroduces a
// band across full-bleed content whenever the window state changes.)
struct TitlebarChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            // The window keeps its title for the Window menu and screen
            // readers; it just never draws one.
            .toolbar(removing: .title)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }
}

// Makes something drawn in the titlebar band clickable.
//
// Content there is visible but not touchable: the window is full-size, so the
// grid runs up under the toolbar, but clicks in that band belong to the titlebar
// (verified — a hit test over the mark lands on `NSToolbarPrimaryTitleContainerView`
// and a button drawn there never fires; a second click zooms the window). So the
// view stays where it is and a catcher goes into the titlebar on top of the
// toolbar, tracking the frame of whatever it's attached to. If the titlebar ever
// stops looking the way this expects, the catcher simply isn't installed and the
// content is inert again.
struct TitlebarClick: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> ClickAnchor { ClickAnchor(action: action) }

    func updateNSView(_ view: ClickAnchor, context: Context) {
        view.action = action
        view.reposition()
    }

    static func dismantleNSView(_ view: ClickAnchor, coordinator: ()) {
        view.catcher.removeFromSuperview()
    }
}

final class ClickAnchor: NSView {
    var action: () -> Void
    let catcher = ClickCatcher()

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("Not loaded from a nib") }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        install()
    }

    // SwiftUI lays this out whenever the window resizes or the sidebar moves, so
    // the catcher follows the mark without watching anything itself.
    override func layout() {
        super.layout()
        install()
        reposition()
    }

    // Checked every pass rather than done once, because the titlebar doesn't hold
    // still: hiding the toolbar (Zen mode) and showing it again rebuilds it, and
    // a catcher left in the old container — or buried under toolbar views added
    // after it — is a dead click. Both are cheap to spot and fix here.
    private func install() {
        guard let titlebar = window?.contentView?.superview?.subviews.first(where: {
            String(describing: type(of: $0)).contains("TitlebarContainer")
        }) else {
            catcher.removeFromSuperview()
            return
        }
        // Already in place *and* on top: nothing to do.
        guard titlebar.subviews.last !== catcher else { return }

        catcher.removeFromSuperview()
        catcher.action = { [weak self] in self?.action() }
        // Last subview, so it takes the click before the toolbar does.
        titlebar.addSubview(catcher)
        reposition()

        // A toolbar coming back finishes restoring itself after this pass, and
        // anything it adds lands on top of us. One look on the next turn of the
        // runloop settles it; `bringToFront` schedules nothing further, so this
        // can't chase its own tail.
        DispatchQueue.main.async { [weak self] in self?.bringToFront() }
    }

    private func bringToFront() {
        guard let titlebar = catcher.superview, titlebar.subviews.last !== catcher else { return }
        catcher.removeFromSuperview()
        titlebar.addSubview(catcher)
        reposition()
    }

    func reposition() {
        guard let host = catcher.superview else { return }
        catcher.frame = host.convert(convert(bounds, to: nil), from: nil)
    }
}

final class ClickCatcher: NSView {
    var action: (() -> Void)?

    // Only claim our own bounds; the rest of the titlebar keeps dragging the
    // window as usual.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let superview else { return nil }
        return bounds.contains(convert(point, from: superview)) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        action?()
    }
}

extension View {
    func titlebarChrome() -> some View {
        modifier(TitlebarChrome())
    }

    // Clickable in the titlebar band, where clicks otherwise go to the window.
    func titlebarClick(action: @escaping () -> Void) -> some View {
        overlay { TitlebarClick(action: action) }
    }
}

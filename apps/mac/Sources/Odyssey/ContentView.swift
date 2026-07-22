import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var model: GalleryModel
    @State private var zoomed: CosmosElement?
    @State private var transitioningID: Int?
    @State private var didActivate = false
    @State private var updater = Updater()
    @Namespace private var hero

    private var modalPresented: Bool { zoomed != nil || model.showAccount }

    private var sidebarVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { model.sidebarVisible && !model.zenMode ? .all : .detailOnly },
            set: { model.sidebarVisible = $0 != .detailOnly }
        )
    }

    var body: some View {
        ZStack {
            content

            if let element = zoomed {
                Lightbox(element: element, namespace: hero) { dismissZoom() }
            }

            if model.showAccount {
                Modal(onDismiss: closeAccount) {
                    Account(model: model, updater: updater, onDone: closeAccount)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: Theme.minWindow.width, minHeight: Theme.minWindow.height)
        .background(Theme.background)
        .foregroundStyle(Theme.foreground)
        .tint(Theme.accent)
        .fontDesign(Theme.fontDesign)
        .preferredColorScheme(.dark)
        .readsFullscreen()
        .task { await model.restore() }
        .task { await updater.check() }
        // Silent refresh whenever the app regains focus, so external Cosmos edits
        // (e.g. a deleted element) show up invisibly. Skip the first activation —
        // launch restore already covers it.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            guard didActivate else { didActivate = true; return }
            Task { await model.refreshCurrent() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isRestoring {
            Loading()
        } else if model.hasProfile {
            NavigationSplitView(columnVisibility: sidebarVisibility) {
                Sidebar(model: model, updater: updater, onAccount: openAccount)
                    .blur(radius: modalPresented ? 2 : 0)
                    // While a modal/lightbox is up, drop any inherited animation so
                    // the zoom spring can't drive layout in the sidebar (no shift).
                    .transaction { if modalPresented { $0.animation = nil } }
                    .toolbar(removing: .sidebarToggle)
            } detail: {
                Gallery(model: model, namespace: hero, zoomedID: zoomed?.id, elevatedID: transitioningID, onTap: openZoom)
                    .blur(radius: modalPresented ? 2 : 0)
            }
            // Hide the toolbar over a modal/lightbox backdrop, and in Zen mode
            // (⌘H) where all chrome disappears to leave only the images.
            .toolbar(modalPresented || model.zenMode ? .hidden : .automatic, for: .windowToolbar)
        } else {
            Splash(model: model, onSubmit: search)
        }
    }

    private func search() {
        Task { await model.search() }
    }

    private func openAccount() {
        Haptic.tap()
        withAnimation(Theme.spring) { model.showAccount = true }
    }

    private func closeAccount() {
        Haptic.tap()
        withAnimation(Theme.spring) { model.showAccount = false }
    }

    private func openZoom(_ element: CosmosElement) {
        Haptic.tap()
        transitioningID = element.id
        withAnimation(Theme.spring) { zoomed = element }
    }

    private func dismissZoom() {
        Haptic.tap()
        let id = zoomed?.id
        withAnimation(Theme.spring) { zoomed = nil }
        // Keep the tile elevated until the morph settles, then drop it.
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            if transitioningID == id { transitioningID = nil }
        }
    }
}

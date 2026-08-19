import SwiftUI

// Masonry gallery with pinch-to-zoom and empty/error/loading states.
struct Gallery: View {
    @Bindable var model: GalleryModel
    var namespace: Namespace.ID
    var zoomedID: Int?
    var elevatedID: Int?
    var zoomToken: Int
    var onTap: (CosmosElement, URL?) -> Void

    @State private var pinchAnchor: Int?
    @Environment(\.isFullscreen) private var fullscreen

    var body: some View {
        // Keep a single container whose toolbar is ALWAYS present. Swapping the
        // inner state (spinner/empty/masonry) never adds/removes the toolbar, so
        // the window titlebar can't recompute and jerk the traffic lights.
        content
            // Zen is images only — nothing softened at either edge.
            .overlay(alignment: .top) {
                if !model.zenMode { Fade(edge: .top) }
            }
            .overlay(alignment: .bottom) {
                if !model.zenMode { Fade(edge: .bottom) }
            }
            // Above the fade, and centred on the gallery rather than the window,
            // so it lands over the middle column. It can't be a toolbar item:
            // `.principal` on macOS drops into the title slot beside the sidebar
            // section (measured at x=332 of a 1200pt window), nowhere near centre.
            .overlay(alignment: .top) {
                if !model.zenMode && !fullscreen {
                    Mark()
                        .titlebarClick { model.scrollToTop() }
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.titlebar)
                        .ignoresSafeArea(edges: .top)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    SwiftUI.Button {
                        withAnimation(Theme.spring) { model.toggleSidebar() }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }
                ToolbarSpacer(.flexible, placement: .primaryAction)
                ToolbarItem(placement: .primaryAction) {
                    SortPicker(model: model)
                }
                ToolbarSpacer(.fixed, placement: .primaryAction)
                ToolbarItemGroup(placement: .primaryAction) {
                    SwiftUI.Button {
                        withAnimation(Theme.spring) { model.zoomOut() }
                    } label: {
                        Image(systemName: "minus")
                    }
                    .disabled(model.columnCount >= GalleryModel.maxColumns)

                    SwiftUI.Button {
                        withAnimation(Theme.spring) { model.zoomIn() }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(model.columnCount <= GalleryModel.minColumns)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        // A failure only takes the screen when there's nothing to show: a page
        // that fails deep into a scroll shouldn't replace the grid behind it.
        if let error = model.errorMessage, model.elements.isEmpty {
            ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
        } else if model.isLoading && model.elements.isEmpty {
            Spinner()
        } else if case .search(let term) = model.selection, model.elements.isEmpty {
            ContentUnavailableView.search(text: term)
        } else if model.elements.isEmpty {
            ContentUnavailableView("Search a username to view their cosmos.", systemImage: "sparkles")
        } else {
            Masonry(
                elements: model.elements,
                columnCount: model.columnCount,
                spacing: Theme.gap,
                namespace: namespace,
                hiddenID: zoomedID,
                elevatedID: elevatedID,
                zoomToken: zoomToken,
                loadingMore: model.isLoading,
                zen: model.zenMode,
                scrollTopToken: model.scrollTopToken,
                onTap: onTap,
                onReachEnd: { Task { await model.loadMore() } }
            )
            .animation(Theme.spring, value: model.columnCount)
            .gesture(pinch)
        }
    }

    // Pinch out → more columns (zoom out), pinch in → fewer (zoom in).
    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let anchor = pinchAnchor ?? model.columnCount
                pinchAnchor = anchor
                // Guard against magnification hitting 0/near-0 on a fast pinch,
                // which makes 1/magnification blow up to Inf/NaN and traps when
                // converted to Int.
                let magnification = max(value.magnification, 0.1)
                let raw = (1 / magnification - 1) * 4
                guard raw.isFinite else { return }
                let steps = Int(raw)
                let target = (anchor + steps).clamped(to: GalleryModel.minColumns...GalleryModel.maxColumns)
                if target != model.columnCount {
                    withAnimation(Theme.spring) { model.setColumns(target) }
                }
            }
            .onEnded { _ in pinchAnchor = nil }
    }
}

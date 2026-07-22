import SwiftUI

// Masonry gallery with pinch-to-zoom and empty/error/loading states.
struct Gallery: View {
    @Bindable var model: GalleryModel
    var namespace: Namespace.ID
    var zoomedID: Int?
    var elevatedID: Int?
    var onTap: (CosmosElement) -> Void

    @State private var pinchAnchor: Int?

    var body: some View {
        // Keep a single container whose toolbar is ALWAYS present. Swapping the
        // inner state (spinner/empty/masonry) never adds/removes the toolbar, so
        // the window titlebar can't recompute and jerk the traffic lights.
        content
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    SwiftUI.Button {
                        withAnimation(Theme.spring) { model.toggleSidebar() }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }
                ToolbarSpacer(.flexible, placement: .primaryAction)
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
        if let error = model.errorMessage {
            ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
        } else if model.isLoading && model.elements.isEmpty {
            Spinner()
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
                loadingMore: model.isLoading,
                zen: model.zenMode,
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
                let steps = Int((1 / value.magnification - 1) * 4)
                let target = (anchor + steps).clamped(to: GalleryModel.minColumns...GalleryModel.maxColumns)
                if target != model.columnCount {
                    withAnimation(Theme.spring) { model.setColumns(target) }
                }
            }
            .onEnded { _ in pinchAnchor = nil }
    }
}

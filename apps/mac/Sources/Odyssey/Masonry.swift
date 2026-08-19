import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// A tile and the lightbox it opens into pair up through this, and the pairing
// lasts exactly one zoom.
//
// Keying it on the element alone is what broke reopening an image straight after
// closing it: the outgoing lightbox is still in its group for the length of the
// morph, so the incoming one arrived to find the tile and its predecessor both
// claiming to be the source, resolved against the wrong one, and sat at the
// tile's frame instead of growing (measured: 375x254 in a 1200pt window, which
// looks like the popup opening empty). A group per zoom can't be occupied when
// the next one starts.
enum Hero {
    static func id(_ element: Int, zoom: Int) -> String { "\(element)/\(zoom)" }
}

struct Masonry: View {
    let elements: [CosmosElement]
    let columnCount: Int
    let spacing: CGFloat
    let namespace: Namespace.ID
    let hiddenID: Int?
    let elevatedID: Int?
    let zoomToken: Int
    let loadingMore: Bool
    let zen: Bool
    let scrollTopToken: Int
    // Hands over the rendition this tile already holds, so opening one shows an
    // image immediately instead of waiting on a fetch.
    let onTap: (CosmosElement, URL?) -> Void
    let onReachEnd: () -> Void

    @State private var position = ScrollPosition()

    // Tiles ask the CDN for their own size, so the grid needs its width. Comes
    // from the scroll view itself rather than a GeometryReader, which would cost
    // us the smooth sidebar/resize animations.
    @State private var containerWidth: CGFloat = 0

    // The reading is only ever a hint about *quality*. It can arrive late, and
    // during a split-view's first layout it can arrive plainly wrong (a 20pt
    // container, measured) and then never correct itself, so anything
    // implausible falls back to a normal column width. Sizing must never be able
    // to decide whether an image loads at all.
    private static let assumedTileWidth: CGFloat = 320
    private static let plausibleTileWidth: CGFloat = 40

    private var tileWidth: CGFloat {
        let gaps = spacing * CGFloat(columnCount - 1)
        let width = (containerWidth - gaps - spacing * 2) / CGFloat(columnCount)
        return width > Self.plausibleTileWidth ? width : Self.assumedTileWidth
    }

    // The first screenful loads without waiting to be told it's visible — both so
    // there's something to look at immediately, and so a grid can never come up
    // empty if visibility reporting doesn't land.
    private static let eagerTiles = 24

    var body: some View {
        ScrollView {
            MasonryLayout(columnCount: columnCount, spacing: spacing) {
                ForEach(Array(elements.enumerated()), id: \.element.id) { index, element in
                    Thumbnail(element: element, width: tileWidth, eager: index < Self.eagerTiles)
                        .matchedGeometryEffect(id: Hero.id(element.id, zoom: zoomToken), in: namespace)
                        .opacity(element.id == hiddenID ? 0 : 1)
                        // Keep the transitioning tile above its neighbors so the
                        // zoom morph never passes behind other images.
                        .zIndex(element.id == elevatedID ? 1 : 0)
                        .onTapGesture { onTap(element, element.image(width: tileWidth)) }
                        .onAppear {
                            if element.id == elements.last?.id { onReachEnd() }
                        }
                }
            }
            .padding(spacing)
            // A hair more breathing room between the outer images and the window.
            .padding(.horizontal, 2)
            // Nudge under the toolbar normally; in Zen mode (no toolbar) keep
            // the top gap equal to the sides.
            .padding(.top, zen ? 0 : -4)

            // Footer spinner: only while paging in more, sits below the last row.
            if loadingMore {
                Spinner().padding(.bottom, spacing)
            }
        }
        .scrollContentBackground(.hidden)
        .ignoresSafeArea(.container, edges: zen ? .top : [])
        .scrollPosition($position)
        .onChange(of: scrollTopToken) {
            withAnimation(Theme.spring) { position.scrollTo(edge: .top) }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width
        } action: { _, width in
            containerWidth = width
        }
    }
}

// Native Layout: measures each child at the resolved column width and packs
// into the shortest column. No GeometryReader, so width changes (sidebar
// toggle) animate smoothly with zero reflow jump.
struct MasonryLayout: Layout {
    let columnCount: Int
    let spacing: CGFloat

    // Measuring hundreds of tiles is the expensive part of a pass, and a pass
    // needs the same numbers twice — once to size the grid, once to place it.
    // Measure once per width instead: with a cluster of 500 that's a thousand
    // measurements saved on every frame of a resize or sidebar animation.
    struct Cache {
        var columnWidth: CGFloat = -1
        var heights: [CGFloat] = []
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = Cache()
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.width ?? 0
        let heights = measure(subviews, columnWidth: columnWidth(for: width), cache: &cache)
        let tallest = columnTotals(heights).max() ?? 0
        return CGSize(width: width, height: max(0, tallest - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let columnWidth = columnWidth(for: bounds.width)
        let measured = measure(subviews, columnWidth: columnWidth, cache: &cache)
        var heights = Array(repeating: CGFloat(0), count: columnCount)

        for (index, subview) in subviews.enumerated() {
            let column = heights.firstIndex(of: heights.min()!) ?? 0
            let x = bounds.minX + CGFloat(column) * (columnWidth + spacing)
            let y = bounds.minY + heights[column]
            subview.place(at: CGPoint(x: x, y: y), proposal: .init(width: columnWidth, height: measured[index]))
            heights[column] += measured[index] + spacing
        }
    }

    private func measure(_ subviews: Subviews, columnWidth: CGFloat, cache: inout Cache) -> [CGFloat] {
        guard cache.columnWidth != columnWidth || cache.heights.count != subviews.count else {
            return cache.heights
        }
        cache.columnWidth = columnWidth
        cache.heights = subviews.map {
            $0.sizeThatFits(.init(width: columnWidth, height: nil)).height
        }
        return cache.heights
    }

    // Shortest-column packing, in the same order `placeSubviews` walks.
    private func columnTotals(_ heights: [CGFloat]) -> [CGFloat] {
        var totals = Array(repeating: CGFloat(0), count: columnCount)
        for height in heights {
            let column = totals.firstIndex(of: totals.min()!) ?? 0
            totals[column] += height + spacing
        }
        return totals
    }

    private func columnWidth(for width: CGFloat) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columnCount - 1)
        return (width - totalSpacing) / CGFloat(columnCount)
    }
}

struct Thumbnail: View {
    let element: CosmosElement
    let width: CGFloat
    var eager = false

    // A cluster can run to hundreds of elements and the grid isn't lazy — every
    // tile exists as soon as it loads — so fetching on sight is what keeps a few
    // dozen images in memory instead of the entire collection. Once loaded a tile
    // stays loaded: scrolling back is instant and re-decodes nothing.
    @State private var seen = false

    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.06))
            .overlay {
                if eager || seen, let url = element.image(width: width) {
                    // The transaction is what animates the phase change — without
                    // one the decoded image just snaps in over the placeholder.
                    AsyncImage(url: url, transaction: Transaction(animation: Theme.reveal)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                                .transition(.opacity)
                        case .failure:
                            Color.secondary.opacity(0.1)
                        default:
                            Color.clear
                        }
                    }
                }
            }
            // Space is reserved from the API's dimensions, so filling it later
            // never shifts the layout.
            .aspectRatio(element.ratio, contentMode: .fit)
            .imageBorder()
            .onScrollVisibilityChange(threshold: 0.01) { visible in
                if visible { seen = true }
            }
    }
}

// Fullscreen image with a hero zoom from its grid tile. Click dismisses; Esc is
// wired up in `ContentView`, which knows what's on top.
struct Lightbox: View {
    let element: CosmosElement
    // Whatever the tile was showing: already decoded, so it stands in the instant
    // this opens. Without it the zoom lands on an empty frame whenever the grid's
    // rendition and the lightbox's don't happen to be the same size.
    let preview: URL?
    let namespace: Namespace.ID
    // Pairs this with the tile it came from, for this zoom only.
    let zoomToken: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            // Big, but still a rendition rather than the original — a full-window
            // image needs nothing like the source's megapixels.
            AsyncImage(url: element.image(width: 1200)) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    AsyncImage(url: preview) { tile in
                        if case .success(let image) = tile {
                            image.resizable().aspectRatio(contentMode: .fit)
                        } else {
                            Color.clear.aspectRatio(element.ratio, contentMode: .fit)
                        }
                    }
                }
            }
            .imageBorder()
            // Leave this a source like the tile: as the follower it would take the
            // tile's frame and never grow, since the tile stays in the hierarchy
            // (hidden) the whole time this is up.
            .matchedGeometryEffect(id: Hero.id(element.id, zoom: zoomToken), in: namespace)
            .padding(40)
            .onTapGesture(perform: onDismiss)

            HStack(spacing: 8) {
                if let cosmos = element.cosmosUrl {
                    Button(title: "View in Cosmos", action: { NSWorkspace.shared.open(cosmos) }) {
                        CosmosMark().frame(width: 15, height: 16)
                    }
                }
                if let source = element.source {
                    Button(title: "View source", systemImage: "link", action: { NSWorkspace.shared.open(source) })
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .zIndex(1)
        }
        .ignoresSafeArea()
    }
}

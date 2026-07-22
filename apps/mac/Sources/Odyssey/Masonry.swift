import SwiftUI

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

struct Masonry: View {
    let elements: [CosmosElement]
    let columnCount: Int
    let spacing: CGFloat
    let namespace: Namespace.ID
    let hiddenID: Int?
    let elevatedID: Int?
    let loadingMore: Bool
    let zen: Bool
    let onTap: (CosmosElement) -> Void
    let onReachEnd: () -> Void

    var body: some View {
        ScrollView {
            MasonryLayout(columnCount: columnCount, spacing: spacing) {
                ForEach(elements) { element in
                    Thumbnail(element: element)
                        .matchedGeometryEffect(id: element.id, in: namespace)
                        .opacity(element.id == hiddenID ? 0 : 1)
                        // Keep the transitioning tile above its neighbors so the
                        // zoom morph never passes behind other images.
                        .zIndex(element.id == elevatedID ? 1 : 0)
                        .onTapGesture { onTap(element) }
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
    }
}

// Native Layout: measures each child at the resolved column width and packs
// into the shortest column. No GeometryReader, so width changes (sidebar
// toggle) animate smoothly with zero reflow jump.
struct MasonryLayout: Layout {
    let columnCount: Int
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        let columnWidth = columnWidth(for: width)
        let heights = columnHeights(subviews, columnWidth: columnWidth)
        let tallest = heights.max() ?? 0
        return CGSize(width: width, height: max(0, tallest - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let columnWidth = columnWidth(for: bounds.width)
        var heights = Array(repeating: CGFloat(0), count: columnCount)

        for subview in subviews {
            let column = heights.firstIndex(of: heights.min()!) ?? 0
            let x = bounds.minX + CGFloat(column) * (columnWidth + spacing)
            let y = bounds.minY + heights[column]
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            subview.place(at: CGPoint(x: x, y: y), proposal: .init(width: columnWidth, height: size.height))
            heights[column] += size.height + spacing
        }
    }

    private func columnWidth(for width: CGFloat) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columnCount - 1)
        return (width - totalSpacing) / CGFloat(columnCount)
    }

    private func columnHeights(_ subviews: Subviews, columnWidth: CGFloat) -> [CGFloat] {
        var heights = Array(repeating: CGFloat(0), count: columnCount)
        for subview in subviews {
            let column = heights.firstIndex(of: heights.min()!) ?? 0
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))
            heights[column] += size.height + spacing
        }
        return heights
    }
}

struct Thumbnail: View {
    let element: CosmosElement

    var body: some View {
        AsyncImage(url: URL(string: element.url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .failure:
                Color.secondary.opacity(0.1)
            default:
                Color.secondary.opacity(0.06)
            }
        }
        .aspectRatio(element.ratio, contentMode: .fit)
        .imageBorder()
    }
}

// Fullscreen image with a hero zoom from its grid tile. Esc / click dismisses.
struct Lightbox: View {
    let element: CosmosElement
    let namespace: Namespace.ID
    let onDismiss: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            AsyncImage(url: URL(string: element.url)) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fit)
                } else {
                    Color.clear.aspectRatio(element.ratio, contentMode: .fit)
                }
            }
            .imageBorder()
            .matchedGeometryEffect(id: element.id, in: namespace)
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
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress(.escape) { onDismiss(); return .handled }
        .onAppear { focused = true }
    }
}

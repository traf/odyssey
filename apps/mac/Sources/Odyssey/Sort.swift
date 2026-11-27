import SwiftUI
import AppKit

// How the grid is ordered. Cosmos itself offers no sorting — none of its
// queries take an order/sort argument — so every option below is applied
// locally over the loaded elements. Because the feed is cursor-paginated,
// picking a non-default order makes `GalleryModel` pull the remaining pages in
// so the result is true for the whole collection, not just the first page.
enum Sort: String, CaseIterable, Identifiable {
    case recent
    case random

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: "Recent"
        case .random: "Random"
        }
    }

    // Recency is the order the API already hands back, so it needs no local
    // pass — and no draining.
    var isDefault: Bool { self == .recent }

    func apply(to elements: [CosmosElement], seed: UInt64) -> [CosmosElement] {
        switch self {
        case .recent:
            elements
        case .random:
            elements.stablySorted { shuffleKey($0.id, seed) }
        }
    }
}

private extension Array where Element == CosmosElement {
    // Equal keys keep their API order, so re-sorting after a drained page
    // arrives can never disturb what's already placed. Keys are computed once,
    // not per comparison.
    func stablySorted<Key: Comparable>(by key: (Element) -> Key) -> [Element] {
        enumerated()
            .map { (key: key($0.element), offset: $0.offset, element: $0.element) }
            .sorted { ($0.key, $0.offset) < ($1.key, $1.offset) }
            .map(\.element)
    }
}

// splitmix64 — a cheap, stable per-element key. Hashing the id (rather than
// shuffling) keeps the order reproducible for a given seed, so appending a page
// slots it into the existing order instead of re-rolling the whole grid. A new
// seed is what re-rolls it.
private func shuffleKey(_ id: Int, _ seed: UInt64) -> UInt64 {
    var x = UInt64(bitPattern: Int64(id)) &+ (seed | 1) &* 0x9E37_79B9_7F4A_7C15
    x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
    x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
    return x ^ (x >> 31)
}

// Toolbar pull-down: a plain Button face that opens a real NSMenu.
//
// A `Menu` can't be used here. In a macOS toolbar its label is rebuilt as a
// title-and-icon pair and every layout modifier is thrown away — measured, the
// item stays 71pt wide whether the label carries 0, 16 or 32pt of padding, and
// an AppKit button cell draws its image *before* its title, which is what
// flipped the chevron to the left. A `Button` keeps the label exactly as
// written (82 → 114 → 146pt across those same paddings), so the text, the gap
// and the padding are ours, and the glass capsule matches the hit target.
struct SortPicker: View {
    @Bindable var model: GalleryModel

    @State private var openCount = 0

    var body: some View {
        SwiftUI.Button {
            openCount &+= 1
        } label: {
            HStack(spacing: Theme.sortLabelGap) {
                Text(model.sort.label)
                Image(systemName: "chevron.down")
                    .font(.system(size: Theme.sortChevron, weight: .semibold))
            }
            .padding(.horizontal, Theme.sortPadding)
            .contentShape(.capsule)
        }
        // On the button, not inside its label: here the anchor spans the whole
        // glass capsule (36pt tall) rather than just the text box (16pt), so the
        // menu hangs off the capsule's bottom edge like any pull-down.
        .overlay(
            SortMenuAnchor(
                openCount: openCount,
                options: Sort.allCases,
                current: model.sort,
                onPick: { option in withAnimation(Theme.spring) { model.setSort(option) } },
                onReshuffle: { withAnimation(Theme.spring) { model.reshuffle() } }
            )
            .allowsHitTesting(false)
        )
        // Search results are ranked by relevance, which any local sort would
        // destroy — leave them as Cosmos ordered them.
        .disabled(model.selection.isSearch)
    }
}

// Bridges the button to a native menu: AppKit owns the menu (checkmarks, glass,
// keyboard, dismissal), we own the button it hangs from.
private struct SortMenuAnchor: NSViewRepresentable {
    let openCount: Int
    let options: [Sort]
    let current: Sort
    let onPick: (Sort) -> Void
    let onReshuffle: () -> Void

    func makeNSView(context: Context) -> Anchor { Anchor() }

    func updateNSView(_ view: Anchor, context: Context) {
        view.options = options
        view.current = current
        view.onPick = onPick
        view.onReshuffle = onReshuffle

        guard openCount != context.coordinator.lastOpen else { return }
        context.coordinator.lastOpen = openCount
        // The tap that bumped the count is still being delivered; open once
        // SwiftUI has finished this update and the anchor has its final frame.
        DispatchQueue.main.async { view.present() }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastOpen = 0
    }

    final class Anchor: NSView {
        var options: [Sort] = []
        var current: Sort = .recent
        var onPick: ((Sort) -> Void)?
        var onReshuffle: (() -> Void)?

        func present() {
            let menu = NSMenu()
            for option in options {
                let item = NSMenuItem(title: option.label, action: #selector(pick), keyEquivalent: "")
                item.target = self
                item.representedObject = option.rawValue
                item.state = option == current ? .on : .off
                menu.addItem(item)
            }

            // Re-picking Random asks for a different shuffle, which a checkmark
            // row can't express — an explicit row can.
            if current == .random {
                menu.addItem(.separator())
                let again = NSMenuItem(title: "Shuffle Again", action: #selector(shuffle), keyEquivalent: "")
                again.target = self
                menu.addItem(again)
            }

            // Hang it off the bottom edge, like any pull-down.
            let y = isFlipped ? bounds.maxY + 4 : -4
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: y), in: self)
        }

        @objc private func pick(_ sender: NSMenuItem) {
            guard let raw = sender.representedObject as? String,
                  let option = Sort(rawValue: raw) else { return }
            onPick?(option)
        }

        @objc private func shuffle() {
            onReshuffle?()
        }
    }
}

// The same options in the menu bar, where a pull-down can carry the extra
// re-roll row a picker has no room for.
struct SortMenu: View {
    @Bindable var model: GalleryModel

    var body: some View {
        Menu("Sort By") {
            // Toggles rather than a Picker: they render as the same native
            // checkmark rows, but also report a tap on the already-active row,
            // which is what re-rolls a shuffle.
            ForEach(Sort.allCases) { option in
                Toggle(option.label, isOn: binding(for: option))
            }

            if model.sort == .random {
                Divider()
                SwiftUI.Button("Shuffle Again") {
                    withAnimation(Theme.spring) { model.reshuffle() }
                }
            }
        }
        .disabled(model.selection.isSearch)
    }

    private func binding(for option: Sort) -> Binding<Bool> {
        Binding(
            get: { model.sort == option },
            set: { _ in withAnimation(Theme.spring) { model.setSort(option) } }
        )
    }
}

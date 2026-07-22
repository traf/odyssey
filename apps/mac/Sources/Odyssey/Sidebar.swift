import SwiftUI

// Cluster navigation with an account button pinned to the bottom.
struct Sidebar: View {
    @Bindable var model: GalleryModel
    var onAccount: () -> Void

    @Environment(\.isFullscreen) private var fullscreen

    var body: some View {
        VStack(spacing: 8) {
            // Clear the titlebar band (traffic lights + native sidebar toggle).
            // Fullscreen has no titlebar, so use a normal top gap instead.
            Color.clear.frame(height: fullscreen ? 8 : 34)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    Row(title: "All elements", count: model.totalCount > 0 ? model.totalCount : nil, selected: model.selection == .all) {
                        select(.all)
                    }

                    if !model.clusters.isEmpty {
                        Text("Clusters")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        ForEach(model.clusters) { cluster in
                            Row(
                                title: cluster.name,
                                count: cluster.numberOfElements,
                                selected: model.selection == .cluster(cluster.id)
                            ) {
                                select(.cluster(cluster.id))
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)

            if let user = model.user {
                SwiftUI.Button(action: onAccount) {
                    HStack(spacing: 10) {
                        Avatar(url: user.avatarUrl, size: 24)
                        Text(user.displayName)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .contentShape(Capsule())
                    .glassEffect(.regular, in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        // Concentric with the window: inner radius = window radius − inset.
        // macOS window radius ≈ 18pt, inset 8pt → ≈ 12pt.
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border))
        .padding(8)
        .background(Theme.background)
        .frame(minWidth: 260, maxWidth: .infinity)
        // Windowed: extend the panel up under the titlebar so the traffic lights
        // sit on it. Fullscreen: no titlebar, so stay within the safe area for an
        // equal top gap and correct colors. minWidth prevents column collapse.
        .ignoresSafeArea(.container, edges: fullscreen ? [] : .top)
        .navigationSplitViewColumnWidth(min: 260, ideal: 276, max: 340)
    }

    private func select(_ selection: GalleryModel.Selection) {
        Task { await model.select(selection) }
    }
}

// A single sidebar entry; selected state gets a fully-rounded glass capsule.
private struct Row: View {
    let title: String
    let count: Int?
    let selected: Bool
    var action: () -> Void

    var body: some View {
        SwiftUI.Button(action: action) {
            HStack {
                Text(title).lineLimit(1)
                Spacer()
                if let count {
                    Text("\(count)").foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background {
            // Always present (stable identity); only fade opacity so it never
            // inserts/removes during unrelated animations (e.g. lightbox zoom).
            Color.clear
                .glassEffect(.regular, in: .capsule)
                .opacity(selected ? 1 : 0)
        }
    }
}

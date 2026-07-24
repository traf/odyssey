import SwiftUI

// A glass action row pinned to the bottom of the sidebar. Metrics match the
// search field it stacks under — 24pt leading circle, 10/6 padding — so the
// whole group shares one height and one icon footprint.
struct Pill<Leading: View>: View {
    let label: String
    // Glass disc behind the leading slot; an Avatar already brings its own.
    var disc = false
    var trailing: String?
    var action: () -> Void
    @ViewBuilder var leading: Leading

    var body: some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 10) {
                leading
                    .frame(width: 24, height: 24)
                    .glass(disc, in: .circle)
                Text(label)
                    .lineLimit(1)
                Spacer()
                if let trailing {
                    Image(systemName: trailing)
                        .foregroundStyle(.secondary)
                }
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

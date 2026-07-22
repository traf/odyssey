import SwiftUI

// Glass-capsule button matching SearchField's height and style. Optional leading
// icon (any view, e.g. CosmosMark); `wide` fills the available width.
struct Button<Icon: View>: View {
    var title: String
    var role: ButtonRole?
    var wide = false
    var action: () -> Void
    @ViewBuilder var icon: Icon

    var body: some View {
        SwiftUI.Button(role: role, action: action) {
            HStack(spacing: 8) {
                icon
                if !title.isEmpty { Text(title) }
            }
            .font(.body)
            .frame(maxWidth: wide ? .infinity : nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .foregroundStyle(role == .destructive ? Color.red : Theme.foreground)
        .glassEffect(.regular, in: .capsule)
    }
}

extension Button where Icon == Image {
    init(title: String, systemImage: String, role: ButtonRole? = nil, wide: Bool = false, action: @escaping () -> Void) {
        self.init(title: title, role: role, wide: wide, action: action) {
            Image(systemName: systemImage)
        }
    }
}

extension Button where Icon == EmptyView {
    init(title: String, role: ButtonRole? = nil, wide: Bool = false, action: @escaping () -> Void) {
        self.init(title: title, role: role, wide: wide, action: action) { EmptyView() }
    }
}

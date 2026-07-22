import SwiftUI

// Glass-capsule search input. Used on the splash and in the sidebar.
struct SearchField: View {
    @Binding var text: String
    var placeholder = "Username"
    var prefix: String?
    var font: Font = .body
    var hPadding: CGFloat = 16
    var vPadding: CGFloat = 12
    var iconSize: CGFloat = 15
    var textOffset: CGFloat = 0
    var loading = false
    var autofocus = false
    var onSubmit: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 10) {
            CosmosMark()
                .fill(.white)
                .frame(width: iconSize, height: iconSize * 16 / 15)
                .rotationEffect(.degrees(loading ? 360 : 0))
                .animation(loading ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: loading)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                if let prefix {
                    Text(prefix)
                }
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .onSubmit(onSubmit)
                    .disabled(loading)
            }
            .font(font)
            .focused($focused)
            .offset(y: textOffset)

            if focused && !text.isEmpty {
                Image(systemName: "return")
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(Theme.spring, value: focused && !text.isEmpty)
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .glassEffect(.regular, in: .capsule)
        .onAppear { if autofocus { focused = true } }
    }
}

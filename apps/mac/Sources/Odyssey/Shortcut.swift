import SwiftUI

// A single keyboard-shortcut row: label on the left, key caps on the right.
struct Shortcut: View {
    let label: String
    let keys: [String]

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.callout.monospaced())
                        .frame(minWidth: 22, minHeight: 22)
                        .padding(.horizontal, 4)
                        .glassEffect(.regular, in: .rect(cornerRadius: 6))
                }
            }
        }
    }
}

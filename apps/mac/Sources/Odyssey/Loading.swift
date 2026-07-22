import SwiftUI

// Minimal full-screen loading state: just a large spinning Cosmos mark.
struct Loading: View {
    var body: some View {
        Spinner(size: 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

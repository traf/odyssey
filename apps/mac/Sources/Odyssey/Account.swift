import SwiftUI

// Account settings: shows the current profile, switch username, or sign out.
struct Account: View {
    @Bindable var model: GalleryModel
    var onDone: () -> Void

    private static let site = URL(string: "https://odyssey-hq.vercel.app/")!

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Logo(size: 22)
                Spacer()
                IconButton(systemImage: "xmark", action: onDone)
            }

            if let user = model.user {
                HStack(spacing: 12) {
                    Avatar(url: user.avatarUrl, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName).font(.headline)
                        Link("cosmos.so/\(user.username)", destination: URL(string: "https://www.cosmos.so/\(user.username)")!)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Switch account").font(.subheadline).foregroundStyle(.secondary)
                SearchField(
                    text: $model.username,
                    placeholder: "username",
                    prefix: "cosmos.so/",
                    loading: model.isLoading,
                    onSubmit: { Task { await model.search() } }
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcuts").font(.subheadline).foregroundStyle(.secondary)
                Shortcut(label: "Toggle sidebar", keys: ["⌘", "S"])
                Shortcut(label: "Zen mode", keys: ["⌘", "Z"])
                Shortcut(label: "Zoom in", keys: ["⌘", "+"])
                Shortcut(label: "Zoom out", keys: ["⌘", "−"])
                Shortcut(label: "Reset zoom", keys: ["⌘", "0"])
                Shortcut(label: "Settings", keys: ["⌘", ","])
            }

            HStack(spacing: 8) {
                Button(title: "View website", systemImage: "macwindow", role: nil, wide: true) {
                    NSWorkspace.shared.open(Self.site)
                }

                Button(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, wide: true) {
                    model.signOut()
                    onDone()
                }
            }

            Text("An unofficial client for Cosmos. Not affiliated with or endorsed by Cosmos.\nAll content and trademarks belong to their respective owners.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, -8)
        }
    }
}

import SwiftUI

// First-launch screen: logo pinned top, search centered.
struct Splash: View {
    @Bindable var model: GalleryModel
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            SearchField(
                text: $model.username,
                placeholder: "username",
                prefix: "cosmos.so/",
                font: .title,
                hPadding: 24,
                vPadding: 22,
                iconSize: 20,
                textOffset: -2,
                loading: model.isLoading,
                autofocus: true,
                beam: true,
                onSubmit: onSubmit
            )
            .frame(maxWidth: 340)

            if let error = model.errorMessage {
                Text(error).font(.callout).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            Logo(size: 36)
                .padding(.top, 28)
        }
    }
}

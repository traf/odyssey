import Foundation
import Observation

@MainActor
@Observable
final class GalleryModel {
    var username = ""
    var query = ""
    var user: UserProfile?
    var totalCount = 0
    var clusters: [CosmosCluster] = []
    var selection: Selection = .all
    var elements: [CosmosElement] = []
    var columnCount = 3
    var sidebarVisible = true
    var zenMode = false
    var showAccount = false
    var isLoading = false
    var isRestoring = false
    var errorMessage: String?

    static let minColumns = 1
    static let maxColumns = 6
    static let defaultColumns = 3

    private static let savedUsernameKey = "odyssey.username"

    // Restore the last profile on launch.
    func restore() async {
        guard let saved = UserDefaults.standard.string(forKey: Self.savedUsernameKey),
              !saved.isEmpty else { return }
        username = saved

        // Paint cached content instantly, then revalidate in the background so
        // newly-added elements appear a beat later without a blocking spinner.
        if let cached = API.cachedResolve(username: saved) {
            apply(cached)
            Task { await refreshCurrent() }
        } else {
            isRestoring = true
            await search()
            isRestoring = false
        }
    }

    private func apply(_ result: ResolveResponse) {
        user = result.user
        userId = result.user.id
        totalCount = result.totalCount
        setElements(result.elements)
        nextCursor = result.nextCursor
    }

    // Silent background reload of whatever is currently on screen (All or a
    // cluster). No spinner, no blanking — setElements diffs by id, so identical
    // data is a true no-op and unchanged data never re-renders (no flashes).
    // Called on launch and whenever the app regains focus so external edits in
    // Cosmos (e.g. a deleted element) appear without any visible reload.
    // Search results are relevance-ranked rather than chronological, so silently
    // re-fetching them would reshuffle the grid under the user. Leave them alone.
    func refreshCurrent() async {
        guard hasProfile, !selection.isSearch else { return }
        let token = loadToken
        let current = selection

        if current == .all {
            // resolve() carries the fresh total + first page; apply() diffs.
            guard let result = try? await API.resolve(username: user?.username ?? username),
                  token == loadToken, selection == .all else { return }
            apply(result)
        } else {
            guard let result = try? await fetch(current, cursor: nil),
                  token == loadToken, current == selection else { return }
            setElements(result.elements)
            nextCursor = result.nextCursor
        }

        // Refresh cluster counts silently (only replaces if actually changed).
        if let userId, let clusters = try? await API.clusters(userId: userId).clusters,
           token == loadToken,
           clusters.map(\.id) != self.clusters.map(\.id)
            || clusters.map(\.numberOfElements) != self.clusters.map(\.numberOfElements) {
            self.clusters = clusters
        }
    }

    // Clear the profile and forget the saved username (back to splash).
    func signOut() {
        UserDefaults.standard.removeObject(forKey: Self.savedUsernameKey)
        username = ""
        query = ""
        user = nil
        totalCount = 0
        clusters = []
        elements = []
        userId = nil
        nextCursor = nil
        selection = .all
        errorMessage = nil
    }

    // Fewer columns = larger images (zoom in); more = smaller (zoom out).
    func zoomIn() { setColumns(columnCount - 1) }
    func zoomOut() { setColumns(columnCount + 1) }
    func resetZoom() { setColumns(Self.defaultColumns) }

    func toggleSidebar() {
        sidebarVisible.toggle()
        Haptic.tap()
    }

    // Zen mode: hide all chrome (sidebar + toolbar), leaving only the images.
    func toggleZen() {
        zenMode.toggle()
        Haptic.tap()
    }

    func setColumns(_ count: Int) {
        let clamped = count.clamped(to: Self.minColumns...Self.maxColumns)
        guard clamped != columnCount else { return }
        columnCount = clamped
        Haptic.tap(.levelChange)
    }

    private var userId: String?
    private var nextCursor: String?
    // Monotonic token: only the most recent selection load may mutate state.
    private var loadToken = 0
    // Bumped to ask the search field to take focus.
    private(set) var searchFocusToken = 0

    enum Selection: Hashable {
        case all
        case cluster(Int)
        case search(String)

        // Search spans all of Cosmos; every other selection reads from the
        // loaded profile and so needs a resolved user id.
        var isSearch: Bool {
            if case .search = self { return true }
            return false
        }
    }

    var hasProfile: Bool { user != nil }

    // Only spin the search field's mark while a search fetches its first page —
    // not on profile/cluster fetches, and not on the paging that fires
    // constantly as you scroll results.
    var isSearching: Bool { isLoading && selection.isSearch && elements.isEmpty }

    func runSearch() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        await select(.search(term))
    }

    // Empty the field, and drop back to the profile if results are showing —
    // leaving them up with nothing in the field gives no clue what they are.
    func clearSearch() async {
        query = ""
        if selection.isSearch {
            await select(.all)   // fires its own haptic
        } else {
            Haptic.tap()
        }
    }

    // Reveal the sidebar search field and put the caret in it (⌘F, /).
    func focusSearch() {
        zenMode = false
        sidebarVisible = true
        searchFocusToken &+= 1
        Haptic.tap()
    }

    func search() async {
        let name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        user = nil
        clusters = []
        elements = []
        userId = nil
        nextCursor = nil
        selection = .all
        query = ""

        do {
            let result = try await API.resolve(username: name)
            apply(result)

            if let clusters = try? await API.clusters(userId: result.user.id).clusters {
                self.clusters = clusters
            }

            UserDefaults.standard.set(result.user.username, forKey: Self.savedUsernameKey)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func select(_ newSelection: Selection) async {
        guard newSelection != selection || elements.isEmpty else { return }
        Haptic.tap(.alignment)

        // Invalidate any in-flight load and claim this one as the latest.
        loadToken &+= 1
        let token = loadToken

        let changed = newSelection != selection
        selection = newSelection
        nextCursor = nil
        errorMessage = nil
        isLoading = true
        // Clear the old view immediately so we never show another cluster's images.
        if changed { elements = [] }
        // Leaving search returns to the profile, so drop the stale term.
        if !newSelection.isSearch { query = "" }

        guard newSelection.isSearch || userId != nil else {
            elements = []
            isLoading = false
            return
        }

        do {
            let result = try await fetch(newSelection, cursor: nil)
            guard token == loadToken else { return }   // superseded — drop it
            setElements(result.elements)
            nextCursor = result.nextCursor
        } catch {
            guard token == loadToken else { return }
            errorMessage = error.localizedDescription
        }

        guard token == loadToken else { return }
        isLoading = false
    }

    func loadMore() async {
        guard let cursor = nextCursor, !isLoading else { return }
        let token = loadToken
        let current = selection

        isLoading = true
        do {
            let result = try await fetch(current, cursor: cursor)
            // Bail if the selection changed while paging.
            guard token == loadToken, current == selection else { return }
            elements.append(contentsOf: result.elements)
            nextCursor = result.nextCursor
        } catch {
            guard token == loadToken else { return }
            errorMessage = error.localizedDescription
        }
        guard token == loadToken else { return }
        isLoading = false
    }

    private func fetch(_ selection: Selection, cursor: String?) async throws -> ElementsResponse {
        switch selection {
        case .all:
            if let cursor, let userId {
                return try await API.elements(userId: userId, cursor: cursor)
            }
            let result = try await API.resolve(username: user?.username ?? username)
            return ElementsResponse(elements: result.elements, nextCursor: result.nextCursor)
        case .cluster(let id):
            return try await API.clusterElements(clusterId: id, cursor: cursor)
        case .search(let term):
            return try await API.search(term: term, cursor: cursor)
        }
    }

    // Avoid pointless re-renders (image reloads) when the data is unchanged.
    private func setElements(_ new: [CosmosElement]) {
        guard new.map(\.id) != elements.map(\.id) else { return }
        elements = new
    }
}

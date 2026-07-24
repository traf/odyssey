import Foundation
import Observation

// Lightweight update check: compares the running app version against the latest
// GitHub release tag. No auto-download — if a newer version exists we surface a
// button in Account that opens the releases page. Versions follow semver and
// release tags are "v<version>" (e.g. v1.0.0); see AGENTS.md → Shipping.
@MainActor
@Observable
final class Updater {
    private static let latestAPI = URL(string: "https://api.github.com/repos/traf/odyssey/releases/latest")!
    static let releasesPage = URL(string: "https://github.com/traf/odyssey/releases/latest")!

    // Running app version, e.g. "1.0.0". Dev builds (swift run) have no
    // Info.plist, so fall back to the current shipped version. Keep this in
    // sync with the latest GitHub release tag (see AGENTS.md → Shipping).
    static let fallbackVersion = "1.1.0"
    let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? Updater.fallbackVersion

    private(set) var latest: String?

    // True only once we've confirmed a strictly newer release exists.
    var updateAvailable: Bool {
        guard let latest else { return false }
        return latest.compare(current, options: .numeric) == .orderedDescending
    }

    private struct Release: Decodable { let tag_name: String }

    func check() async {
        guard let (data, _) = try? await URLSession.shared.data(from: Self.latestAPI),
              let release = try? JSONDecoder().decode(Release.self, from: data) else { return }
        // Tags are "v1.0.0" — strip the leading v for comparison.
        latest = release.tag_name.hasPrefix("v")
            ? String(release.tag_name.dropFirst())
            : release.tag_name
    }
}

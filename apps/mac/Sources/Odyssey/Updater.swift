import AppKit
import Foundation
import Observation

// Silent updater. A packaged `.app` checks the latest GitHub release on
// launch and, if newer, replaces itself and relaunches. Dev (`swift run`)
// has no `.app` bundle so this is a no-op. Tags are "v<version>"; see
// AGENTS.md → Shipping. The swap happens after we quit — a running bundle
// can't overwrite its own binary.
@MainActor
@Observable
final class Updater {
    private static let latestAPI = URL(string: "https://api.github.com/repos/traf/odyssey/releases/latest")!
    static let fallbackVersion = "1.2.1"
    let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? Updater.fallbackVersion

    func check() async {
        guard Self.installed else { return }
        guard let release = await Self.latest(),
              release.version.compare(current, options: .numeric) == .orderedDescending
        else { return }
        do {
            try await Self.apply(release, replacing: Bundle.main.bundleURL)
        } catch { return }
        NSApp.terminate(nil)
    }

    // Only a real installed `.app` can be swapped. `.build`, a mounted DMG,
    // or a read-only copy would fail mid-replace or update the installer.
    private static var installed: Bool {
        let url = Bundle.main.bundleURL
        guard url.pathExtension == "app" else { return false }
        let path = url.path
        guard !path.contains("/.build/"), !path.hasPrefix("/Volumes/") else { return false }
        return FileManager.default.isWritableFile(atPath: path)
    }

    private struct Release: Sendable {
        let version: String
        let dmg: URL
    }

    private struct Payload: Decodable {
        let tag_name: String
        let assets: [Asset]
        struct Asset: Decodable {
            let name: String
            let browser_download_url: URL
        }
    }

    private static func latest() async -> Release? {
        guard let (data, _) = try? await URLSession.shared.data(from: latestAPI),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              let dmg = payload.assets.first(where: { $0.name == "Odyssey.dmg" })?.browser_download_url
        else { return nil }
        let tag = payload.tag_name
        let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        return Release(version: version, dmg: dmg)
    }

    private static func apply(_ release: Release, replacing app: URL) async throws {
        try await Task.detached(priority: .utility) {
            try await run(release, replacing: app)
        }.value
    }

    private struct Failure: Error {}

    nonisolated private static func run(_ release: Release, replacing app: URL) async throws {
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appending(path: "odyssey-update-\(UUID().uuidString)", directoryHint: .isDirectory)
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        let mount = work.appending(path: "mount", directoryHint: .isDirectory)
        try fm.createDirectory(at: mount, withIntermediateDirectories: true)

        var attached = false
        var handedOff = false
        defer {
            if attached { try? shell("/usr/bin/hdiutil", "detach", mount.path, "-quiet", "-force") }
            if !handedOff { try? fm.removeItem(at: work) }
        }

        let dmg = work.appending(path: "Odyssey.dmg")
        let (tmp, response) = try await URLSession.shared.download(from: release.dmg)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw Failure() }
        try fm.moveItem(at: tmp, to: dmg)

        try shell(
            "/usr/bin/hdiutil", "attach", dmg.path,
            "-nobrowse", "-noverify", "-noautoopen", "-readonly",
            "-mountpoint", mount.path
        )
        attached = true

        let mounted = mount.appending(path: "Odyssey.app")
        let info = NSDictionary(contentsOf: mounted.appending(path: "Contents/Info.plist"))
        let version = info?["CFBundleShortVersionString"] as? String
        let id = info?["CFBundleIdentifier"] as? String
        guard id == "io.traf.odyssey",
              let version,
              version.compare(release.version, options: .numeric) != .orderedAscending
        else { throw Failure() }
        try shell("/usr/bin/codesign", "--verify", "--deep", "--strict", mounted.path)

        let staged = work.appending(path: "Odyssey.app")
        try shell("/usr/bin/ditto", mounted.path, staged.path)
        try shell("/usr/bin/hdiutil", "detach", mount.path, "-quiet", "-force")
        attached = false

        // The running bundle is still mapped, so a helper waits for our PID
        // to die, then copies over it and reopens.
        let script = work.appending(path: "apply.sh")
        try """
        #!/bin/bash
        set -euo pipefail
        APP="$1"
        NEW="$2"
        PID="$3"
        WORK="$4"
        while kill -0 "$PID" 2>/dev/null; do sleep 0.05; done
        sleep 0.2
        ditto "$NEW" "$APP"
        xattr -dr com.apple.quarantine "$APP" >/dev/null 2>&1 || true
        open "$APP"
        rm -rf "$WORK"
        """.write(to: script, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [
            script.path, app.path, staged.path,
            String(ProcessInfo.processInfo.processIdentifier), work.path,
        ]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        handedOff = true
    }

    nonisolated private static func shell(_ launch: String, _ args: String...) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launch)
        process.arguments = args
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw Failure() }
    }
}

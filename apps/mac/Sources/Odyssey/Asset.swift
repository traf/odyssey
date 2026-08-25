import AppKit

// Never reach for `Bundle.module`. SwiftPM generates it to look for
// `Odyssey_Odyssey.bundle` beside the executable, and when that misses it falls
// back to an absolute path inside this checkout's `.build` — present on the
// machine that cuts the release and on no other, so the shipped app resolved
// its logo here and trapped on launch everywhere else. The packaged app carries
// its images loose in `Contents/Resources`; dev builds read the SwiftPM bundle,
// looked up by hand so a miss returns nil rather than killing the process.
enum Asset {
    static func url(_ name: String, extension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        let dev = Bundle.main.bundleURL.appendingPathComponent("Odyssey_Odyssey.bundle")
        return Bundle(url: dev)?.url(forResource: name, withExtension: ext)
    }

    static func image(_ name: String) -> NSImage? {
        url(name, extension: "png").flatMap(NSImage.init(contentsOf:))
    }
}

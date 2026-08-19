// Renders the DMG installer background at 1× and 2×.
//
// Same approach as vercel-labs/native: the image is only the field and the
// drag arrow. Finder draws the names itself (AppleScript sets the window).
// The field is `apps/web/public/dmg.jpg`.
//
// Usage: swift background.swift <out-dir>
//   writes background.png (660×400) and background@2x.png (1320×800)
import AppKit

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let fieldURL = URL(fileURLWithPath: CommandLine.arguments.count > 2
    ? CommandLine.arguments[2]
    : here.deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("web/public/dmg.jpg").path)

// Must match dmg.sh (Native's default canvas, plus a few points of bleed
// under the icons). Finder's titlebar is not a stable 36pt — when it's
// shorter the window's content is taller than the canvas and a strip of
// Finder's default fill shows at the bottom. Extra field covers it;
// anything still uncovered is black, not white (see dmg.sh).
let canvasH: CGFloat = 400
let bleed: CGFloat = 24
let w: CGFloat = 660, h: CGFloat = canvasH + bleed
let appX: CGFloat = 166, appsX: CGFloat = 486
let iconY: CGFloat = 182

func render(scale: CGFloat) -> Data {
    let px = Int(w * scale), py = Int(h * scale)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: py,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: w, height: h)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    if let field = NSImage(contentsOf: fieldURL) {
        let size = field.size
        let cover = max(w / size.width, h / size.height)
        let dw = size.width * cover, dh = size.height * cover
        field.draw(
            in: NSRect(x: (w - dw) / 2, y: (h - dh) / 2, width: dw, height: dh),
            from: .zero, operation: .copy, fraction: 1
        )
    } else {
        NSColor.black.setFill()
        NSRect(x: 0, y: 0, width: w, height: h).fill()
    }

    // NSImage origin is bottom-left; dmg.sh positions are top-left.
    let flippedIconY = h - iconY
    let cfg = NSImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        .applying(.init(paletteColors: [NSColor(white: 0.85, alpha: 1)]))
    if let arrow = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let s = arrow.size
        arrow.draw(in: NSRect(
            x: (appX + appsX) / 2 - s.width / 2,
            y: flippedIconY - s.height / 2,
            width: s.width, height: s.height
        ))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let dir = URL(fileURLWithPath: outDir, isDirectory: true)
try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
try! render(scale: 1).write(to: dir.appendingPathComponent("background.png"))
try! render(scale: 2).write(to: dir.appendingPathComponent("background@2x.png"))
print("wrote \(dir.path)/background.png (+ @2x, \(Int(w))×\(Int(h)))")

// Renders the DMG installer background at @2x (1080x680 for a 540x340pt window).
// Dark field, white labels painted under each icon slot, and an SF Symbol
// arrow between them. White labels are baked in because Finder's own label
// color is unreliable on a dark DMG (light vs dark appearance), and text_size
// can't be forced to 0 without macOS 26+ rejecting the whole view.
//
// Usage: swift background.swift <out.png>
import AppKit

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-background.png"
let scale: CGFloat = 2
let w: CGFloat = 540, h: CGFloat = 340
let px = Int(w * scale), py = Int(h * scale)

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: py,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: w, height: h)  // points → @2x backing

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Light field. Finder forces DMG labels black regardless of appearance, so a
// light background keeps them legible (dark arrow painted below).
NSColor(white: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: w, height: h).fill()

// Icon slots (must match dmg.py icon_locations, in points).
// NSImage origin is bottom-left; dmg.py uses top-left, so flip y.
let iconY: CGFloat = 150
let appX: CGFloat = 150, appsX: CGFloat = 390
let flippedIconY = h - iconY

// Arrow: SF Symbol arrow.right, centered between the icons at icon height.
let cfg = NSImage.SymbolConfiguration(pointSize: 30, weight: .regular)
    .applying(.init(paletteColors: [NSColor(white: 0.72, alpha: 1)]))
if let arrow = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: nil)?
    .withSymbolConfiguration(cfg) {
    let s = arrow.size
    arrow.draw(in: NSRect(x: (appX + appsX) / 2 - s.width / 2,
                          y: flippedIconY - s.height / 2,
                          width: s.width, height: s.height))
}

// No painted labels — Finder draws its own (black), legible on the light field.

NSGraphicsContext.restoreGraphicsState()

if let png = rep.representation(using: .png, properties: [:]) {
    try! png.write(to: URL(fileURLWithPath: out))
    print("wrote \(out) (\(px)x\(py))")
}

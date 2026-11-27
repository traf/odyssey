import AppKit

// Trackpad haptic feedback for changes to what's on screen — zoom, cluster,
// sort, opening or closing an image. Never for a plain button press (sidebar,
// Zen, settings, search, scroll to top): those already click.
enum Haptic {
    static func tap(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}

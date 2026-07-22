import AppKit

// Trackpad haptic feedback. Call on discrete interactions (zoom, select, navigate).
enum Haptic {
    static func tap(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}

import SwiftUI
import AppKit

// A bare-character shortcut (no modifiers), e.g. "/" to jump to search.
//
// These can't be menu commands like the ⌘ shortcuts in `OdysseyApp`: AppKit
// matches menu key equivalents before the responder chain sees the key, so a
// plain "/" item would eat the character mid-sentence while the user types.
// Watching the event stream instead lets us step aside whenever a field is
// being edited, and `enabled` keeps the monitor off entirely when the shortcut
// doesn't apply (splash, modals).
fileprivate struct KeyShortcut: ViewModifier {
    let key: String
    let enabled: Bool
    // Esc has to fire even mid-edit, since a modal can hold a text field.
    let whileEditing: Bool
    let action: () -> Void

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { if enabled { install() } }
            .onDisappear(perform: remove)
            .onChange(of: enabled) { enabled ? install() : remove() }
    }

    private func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Arrows always carry .function/.numericPad, so those two aren't
            // modifiers as far as a bare-key shortcut is concerned.
            let modifiers = event.modifierFlags
                .intersection(.deviceIndependentFlagsMask)
                .subtracting([.function, .numericPad])

            guard event.charactersIgnoringModifiers == key,
                  modifiers.isEmpty,
                  whileEditing || !isEditingText
            else { return event }
            action()
            return nil   // swallowed, so the character never lands in the UI
        }
    }

    private func remove() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    // A focused text field edits through its field editor, an NSTextView.
    private var isEditingText: Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        return responder is NSTextView || responder is NSTextField
    }
}

extension View {
    func keyShortcut(
        _ key: String,
        enabled: Bool = true,
        whileEditing: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        modifier(KeyShortcut(key: key, enabled: enabled, whileEditing: whileEditing, action: action))
    }
}

extension String {
    // Esc and the arrows arrive as bare characters, so they ride the same
    // monitor. The arrows are AppKit's function-key code points.
    static let escape = "\u{1B}"
    static let upArrow = "\u{F700}"
    static let downArrow = "\u{F701}"
}

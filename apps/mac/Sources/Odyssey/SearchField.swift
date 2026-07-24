import SwiftUI
import AppKit

// Glass-capsule search input. Used on the splash and in the sidebar.
struct SearchField: View {
    @Binding var text: String
    var placeholder = "Username"
    var prefix: String?
    var font: Font = .body
    var hPadding: CGFloat = 16
    var vPadding: CGFloat = 12
    var iconSize: CGFloat = 15
    // Diameter of a glass disc behind the mark. Set it to an adjacent avatar's
    // size to line the field up with it; nil leaves the mark bare.
    var iconGlass: CGFloat?
    // Hint for the shortcut that focuses the field, shown while it's empty.
    var shortcut: String?
    var textOffset: CGFloat = 0
    var loading = false
    var autofocus = false
    var beam = false
    // Bump to pull focus into the field from outside (e.g. a menu shortcut).
    var focusToken = 0
    // Providing this opts the field into a clear button while it has content.
    var onClear: (() -> Void)?
    var onSubmit: () -> Void

    @FocusState private var focused: Bool
    @State private var bounds: CGRect = .zero
    @State private var clicks: Any?

    var body: some View {
        HStack(spacing: 10) {
            CosmosMark()
                .fill(.white)
                .frame(width: iconSize, height: iconSize * 16 / 15)
                .rotationEffect(.degrees(loading ? 360 : 0))
                .animation(loading ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: loading)
                .frame(width: iconGlass, height: iconGlass)
                .modifier(GlassIfNeeded(active: iconGlass != nil))
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                if let prefix {
                    Text(prefix)
                }
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    // Never disabled: dimming the field made the value flash and
                    // dropped focus mid-load. Guarding submit is enough.
                    .onSubmit {
                        guard !loading else { return }
                        // Return ends AppKit's editing session and SwiftUI puts
                        // focus straight back, which selects the whole value.
                        // Hand focus to the results instead.
                        focused = false
                        onSubmit()
                    }
            }
            .font(font)
            .focused($focused)
            .offset(y: textOffset)

            if let shortcut, text.isEmpty {
                Text(shortcut)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    // Sits in an SF Symbol's box so it centers on the trailing
                    // icons in the rows below it.
                    .frame(width: 16)
                    .transition(.opacity)
            }

            if focused && !text.isEmpty {
                Image(systemName: "return")
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            if let onClear, !text.isEmpty {
                SwiftUI.Button {
                    // Clearing means you're about to type again.
                    focused = true
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .animation(Theme.spring, value: [focused, text.isEmpty])
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .glassEffect(.regular, in: .capsule)
        .modifier(BeamIfNeeded(active: beam))
        .onAppear {
            if autofocus {
                focused = true
            } else if focusToken == 0 {
                // macOS hands initial first-responder status to the first text
                // field in the window, which would open the app already in a
                // searching state. Give it back so this field only takes focus
                // on intent (click, ⌘F, /).
                DispatchQueue.main.async {
                    (NSApp.keyWindow ?? NSApp.windows.first)?.makeFirstResponder(nil)
                }
            }
        }
        .onChange(of: focusToken) { focused = true }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { bounds = $0 }
        .onChange(of: focused) { focused ? watchClicks() : stopWatching() }
        .onDisappear(perform: stopWatching)
    }

    // Buttons don't take first responder on macOS, so without this the caret
    // stays in the field while you browse clusters and images.
    private func watchClicks() {
        guard clicks == nil else { return }
        clicks = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            guard let content = event.window?.contentView else { return event }
            let point = content.convert(event.locationInWindow, from: nil)
            let flipped = content.isFlipped ? point.y : content.bounds.height - point.y
            if !bounds.contains(CGPoint(x: point.x, y: flipped)) { focused = false }
            return event
        }
    }

    private func stopWatching() {
        if let clicks { NSEvent.removeMonitor(clicks) }
        clicks = nil
    }
}

private struct GlassIfNeeded: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            content.glassEffect(.regular, in: .circle)
        } else {
            content
        }
    }
}

// Applies the border beam only when active, so non-login fields are untouched.
private struct BeamIfNeeded: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active {
            content.borderBeam(in: Capsule())
        } else {
            content
        }
    }
}

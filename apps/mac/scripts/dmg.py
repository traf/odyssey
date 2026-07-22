# dmgbuild settings for the Odyssey installer window. dmgbuild writes the
# .DS_Store directly (no Finder/AppleScript), so it works headless and the
# layout is deterministic. Invoked by release.sh.
#
# White labels + the drag arrow are painted into the background image; Finder's
# own labels render black on a DMG regardless of dark mode, so text_size is set
# to ~invisible. release.sh patches dmgbuild to skip the pBBk bookmark so
# macOS 26+ Finder honors this .DS_Store (icon size + background).
import os

app = os.environ["DMG_APP"]
app_name = os.path.basename(app)
# macOS Finder draws DMG icon labels in BLACK and there is no way to change it
# (a picture locks Light; even a solid dark color still yields black labels on
# macOS 26/27, verified). So we ship a LIGHT background with a dark drag arrow —
# black labels are legible on it. This is what iTerm2/VLC/Arc-style DMGs do.
background = os.environ["DMG_BG"]

files = [app]
symlinks = {"Applications": "/Applications"}

icon_size = 120
# Finder draws icon labels in the viewer's appearance color (white in Dark
# Mode) and there's no way to force a color on a DMG. text_size must stay ≥10
# or macOS 26+ rejects the whole icon-view and falls back to a plain window.
text_size = 13
# 540x340pt window; icons centered at y=150pt, labels render just below.
window_rect = ((200, 120), (540, 340))
icon_locations = {
    app_name: (150, 150),
    "Applications": (390, 150),
}

default_view = "icon-view"
show_status_bar = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

# Odyssey

Unofficial [Cosmos](https://cosmos.so) client. npm-workspace monorepo.

## Structure

```
apps/
  web/   Next.js 16 (App Router) — Cosmos API + web frontend. Deployed to Vercel.
  mac/   SwiftUI macOS app (Swift 6, SwiftPM executable). Consumes the web API over HTTP.
```

Root scripts (`dev`, `build`, `lint`, `start`) proxy to `apps/web`. One hoisted `node_modules`/lockfile at root.

## API

Lives in `apps/web`, not a separate app — it's serverless routes that deploy for free with the frontend. Only split out if it needs independent scaling/deploys or gains heavy auth/caching logic.

- Core logic: `apps/web/app/lib/cosmos.ts` (wraps the Cosmos GraphQL API), types in `lib/types.ts`.
- Public routes: `app/api/[username]/[[...cluster]]` and `app/api/search?q=` (README-documented + listed in the `Endpoints` modal, in-memory cached 5m via `cached()` in `lib/cache.ts`). They all return the same flat `{ images, count }` shape — keep it that way; the cursor/element detail belongs to the internal routes. `search` returns only the first page, since draining all 500 upstream matches would risk the function timeout.
- Internal routes used by the frontend + mac app: `app/api/cosmos/{resolve,elements,clusters,cluster-elements,search}` (CDN headers via `lib/cache.ts`: `s-maxage=15s` + `stale-while-revalidate=1d`).
- `search?q=` is global element search across all of Cosmos (Cosmos' `searchElements`, 40/page, cursor-paginated). It's semantic — the upstream expands the query with related concepts and orders by relevance, so results must never be re-sorted by date, and a nonsense query still returns matches rather than nothing. Cosmos exposes no way to scope search to one user (its `userId` filter needs auth and returns empty), so search is always global.

The mac app mirrors these types in `apps/mac/Sources/Odyssey/Models.swift` and hits the routes via `API.swift`. If you change an API response shape, update both sides.

## Conventions

- **Web**: Tailwind only, no component libraries, minimal DOM. Reuse existing components (`Button`, `Card`, etc.). Watch for hydration issues.
- **Mac**: 1000% native — always use native Swift/SwiftUI components, never reinvent them. Lean hard into Liquid Glass (`.glassEffect`, `glassEffectID`, glass button styles, etc.) throughout the UI. SwiftUI + `@Observable`. `API.baseURL` defaults to the deployed URL; point at `http://localhost:3000` for local dev.
  - **Design tokens are the single source of truth.** All color, font, and spacing live in `Theme.swift` — never hardcode a raw color/size in a view. Change it once there.
  - **Componentize everything.** One-word-named, display-only components (`SearchField`, `Glass`, `Logo`, `Masonry`, `Lightbox`, `Splash`, `Sidebar`, `Gallery`). If an element could appear twice, make it a component with props. Logic/state lives in `GalleryModel`.
  - **Zero layout shift, always.** Reserve exact space for async media — tiles size to their API `width`/`height` aspect ratio before images load. The masonry uses the native `Layout` protocol (`Masonry.swift`), never `GeometryReader`, so sidebar toggles and resizes animate smoothly with no reflow jump.
  - Motion uses one shared bouncy-but-fast spring, `Theme.spring` — reuse it for every interaction animation (never inline timings). Continuous spinners are the exception.
  - **Trackpad haptics on every discrete action** — zoom, cluster change, image open/close, modal open/close. Always fire through the `Haptic` helper, never call `NSHapticFeedbackManager` directly.
  - **Modals are the `Modal` component** — dimmed + 2px-blurred backdrop, click-outside or Esc to close, rounded to `Theme.corner`. Content-only views (e.g. `Account`) go inside it; the close control is the reusable `IconButton`.
  - **Keyboard shortcuts** — ⌘, settings, ⌘F or `/` search, ⌘S sidebar, ⌘Z Zen mode (hides all chrome, images only), ⌘+/⌘−/⌘0 zoom. Register in `OdysseyApp` commands, drive state via `GalleryModel`, and list them in the `Account` modal (a `Shortcut` row takes an `or:` combo for alternates).
  - Bare-key shortcuts (no ⌘) can't be menu commands — AppKit matches menu key equivalents before the responder chain, so they'd swallow the character while typing. Use the `.keyShortcut(_:enabled:action:)` modifier in `Keyboard.swift`, which ignores keys while a field is being edited.
  - **Never use a system `ProgressView`/spinner.** Every loading indicator is the spinning Cosmos mark — use the `Spinner` component (or the in-field spinning `CosmosMark`). The logo *is* the loader.
  - **Shipping / releases**: to ship a Mac update, follow this exact flow so the in-app update check works:
    0. Move the `## Unreleased` notes in `apps/mac/CHANGELOG.md` under a new `## <version>` heading, and use them as the GitHub release notes. Keep adding entries under `## Unreleased` as you make changes between releases.
    1. Pick the next **semver** version (`MAJOR.MINOR.PATCH`, e.g. `1.0.1` for fixes, `1.1.0` for features).
    2. Bump `Updater.fallbackVersion` in `Updater.swift` to the same `<version>` (dev builds have no Info.plist and use this as their version).
    3. `apps/mac/scripts/release.sh <version>` — builds, Developer-ID signs, notarizes, staples, and packages `dist/Odyssey.dmg` (that `<version>` is written into the app's `CFBundleShortVersionString`). Creds in `apps/mac/.env.release` (gitignored).
    4. Create a GitHub release tagged **`v<version>`** (the `v` prefix matters — `Updater.swift` strips it) and upload `Odyssey.dmg` as an asset named exactly `Odyssey.dmg`. Publish it as the latest release. The DMG installer window is styled by `scripts/background.swift` + `scripts/dmg.py` (light bg, SF-Symbol drag arrow — macOS forces DMG labels black, so the background must be light).
    5. Keep the release notes body leading with the direct download link (`releases/latest/download/Odyssey.dmg`).
    - The app has **no auto-updater**. On launch `Updater.swift` fetches the latest release tag from the GitHub API and, if it's newer than the running `CFBundleShortVersionString`, shows an "Update available" button in the `Account` modal that opens the releases page for a manual re-download. The web "Download for Mac" button links to `releases/latest`.
    - To re-cut the *same* version (e.g. a fix before anyone downloaded): rebuild with the same `<version>`, delete the old release asset, and re-upload — keep the tag `v<version>`.
  - Public data only (no auth) — all data comes through the Odyssey web API.
- Don't start dev servers — one is usually running.

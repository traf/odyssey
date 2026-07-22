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
- Public routes: `app/api/[username]/[[...cluster]]` (README-documented, in-memory cached 5m).
- Internal routes used by the frontend + mac app: `app/api/cosmos/{resolve,elements,clusters,cluster-elements}` (CDN headers via `lib/cache.ts`: `s-maxage=15s` + `stale-while-revalidate=1d`).

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
  - **Keyboard shortcuts** — ⌘, settings, ⌘S sidebar, ⌘Z Zen mode (hides all chrome, images only), ⌘+/⌘−/⌘0 zoom. Register in `OdysseyApp` commands, drive state via `GalleryModel`, and list them in the `Account` modal.
  - **Never use a system `ProgressView`/spinner.** Every loading indicator is the spinning Cosmos mark — use the `Spinner` component (or the in-field spinning `CosmosMark`). The logo *is* the loader.
  - **Shipping**: `apps/mac/scripts/release.sh [version]` builds, Developer-ID signs, notarizes, and packages `dist/Odyssey.dmg`. Upload it to a GitHub release; the web "Download for Mac" button links to `releases/latest`. Creds in `apps/mac/.env.release` (gitignored).
  - Public data only (no auth) — all data comes through the Odyssey web API.
- Don't start dev servers — one is usually running.

// Shared CDN cache headers for the public Cosmos proxy routes.
// Short `sMaxAge` keeps content fresh (new elements show within seconds), while
// a long `stale-while-revalidate` serves the cached copy instantly and refreshes
// in the background — so it stays fast without ever feeling stale for long.
export function cacheHeaders(sMaxAge = 15, swr = 86400): HeadersInit {
  return {
    "Cache-Control": `public, s-maxage=${sMaxAge}, stale-while-revalidate=${swr}`,
  };
}

// Shared CDN cache headers for the public Cosmos proxy routes.
// Short `sMaxAge` keeps content fresh (new elements show within seconds), while
// a long `stale-while-revalidate` serves the cached copy instantly and refreshes
// in the background — so it stays fast without ever feeling stale for long.
export function cacheHeaders(sMaxAge = 15, swr = 86400): HeadersInit {
  return {
    "Cache-Control": `public, s-maxage=${sMaxAge}, stale-while-revalidate=${swr}`,
  };
}

// In-memory TTL cache for the public routes, which fan out into many upstream
// requests per call. Best-effort by nature — serverless instances come and go,
// so it's a hot-path optimisation rather than a guarantee.
const TTL = 5 * 60 * 1000;
const store = new Map<string, { data: unknown; ts: number }>();

export function cached<T>(key: string, fn: () => Promise<T>): Promise<T> {
  const hit = store.get(key);
  if (hit && Date.now() - hit.ts < TTL) return Promise.resolve(hit.data as T);
  return fn().then((data) => {
    store.set(key, { data, ts: Date.now() });
    return data;
  });
}

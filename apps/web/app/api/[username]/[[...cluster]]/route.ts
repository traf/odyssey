import { NextRequest, NextResponse } from "next/server";
import {
  resolveUser,
  fetchClusters,
  fetchClusterElements,
  fetchElements,
} from "@/lib/cosmos";

const CACHE_TTL = 5 * 60 * 1000;
const cache = new Map<string, { data: unknown; ts: number }>();

function cached<T>(key: string, fn: () => Promise<T>): Promise<T> {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.ts < CACHE_TTL) return Promise.resolve(hit.data as T);
  return fn().then((data) => {
    cache.set(key, { data, ts: Date.now() });
    return data;
  });
}

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ username: string; cluster?: string[] }> }
) {
  const { username, cluster } = await params;
  const clusterSlug = cluster?.[0];
  const cacheKey = `${username}/${clusterSlug || ""}`;

  try {
    const result = await cached(cacheKey, async () => {
      const { user } = await resolveUser(username);
      const clusters = await fetchClusters(user.id);

      const allUrls: string[] = [];

      if (clusterSlug) {
        const match = clusters.find((c) => c.slug === clusterSlug);
        if (!match) throw new Error("Cluster not found");

        let cursor: string | null = null;
        do {
          const page = await fetchClusterElements(match.id, cursor);
          allUrls.push(...page.elements.filter((e) => e.type === "image").map((e) => e.url));
          cursor = page.nextCursor;
        } while (cursor);

        return { images: allUrls, count: allUrls.length };
      }

      let cursor: string | null = null;
      do {
        const page = await fetchElements(user.id, cursor);
        allUrls.push(...page.elements.filter((e) => e.type === "image").map((e) => e.url));
        cursor = page.nextCursor;
      } while (cursor);

      return {
        user: {
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
        },
        clusters: clusters.map((c) => ({
          name: c.name,
          slug: c.slug,
          count: c.numberOfElements,
        })),
        images: allUrls,
        count: allUrls.length,
      };
    });

    return NextResponse.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    const status = message === "Cluster not found" ? 404 : 500;
    return NextResponse.json({ error: message }, { status });
  }
}

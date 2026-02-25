"use client";

import { useState, useCallback, useEffect } from "react";
import {
  CosmosElement,
  CosmosCluster,
  UserProfile,
  ResolveResponse,
  ElementsResponse,
  ClustersResponse,
} from "@/lib/types";

function updateUrl(path: string) {
  window.history.replaceState(null, "", path);
}

export function useCosmosProfile(initialUsername?: string, initialClusterSlug?: string) {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [elements, setElements] = useState<CosmosElement[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(!!initialUsername);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [clusters, setClusters] = useState<CosmosCluster[]>([]);
  const [selectedCluster, setSelectedCluster] = useState<number | null>(null);
  const [clusterLoading, setClusterLoading] = useState(false);

  const search = useCallback(async (username: string) => {
    setLoading(true);
    setError(null);
    setUser(null);
    setElements([]);
    setNextCursor(null);
    setTotalCount(0);
    setClusters([]);
    setSelectedCluster(null);

    try {
      const res = await fetch(
        `/api/cosmos/resolve?username=${encodeURIComponent(username)}`
      );
      if (!res.ok) {
        const body = await res.json().catch(() => ({ error: "Request failed" }));
        throw new Error(body.error || `HTTP ${res.status}`);
      }

      const data: ResolveResponse = await res.json();
      setUser(data.user);
      setElements(data.elements);
      setNextCursor(data.nextCursor);
      setTotalCount(data.totalCount);

      updateUrl(`/${data.user.username}`);

      fetch(`/api/cosmos/clusters?userId=${data.user.id}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((d: ClustersResponse | null) => {
          if (d?.clusters) setClusters(d.clusters);
        })
        .catch(() => {});
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  }, []);

  const selectCluster = useCallback(
    async (clusterId: number | null) => {
      if (!user) return;
      setSelectedCluster(clusterId);

      if (clusterId === null) {
        updateUrl(`/${user.username}`);
      } else {
        const cluster = clusters.find((c) => c.id === clusterId);
        if (cluster) updateUrl(`/${user.username}/${cluster.slug}`);
      }

      try {
        if (clusterId === null) {
          const res = await fetch(
            `/api/cosmos/resolve?username=${encodeURIComponent(user.username)}`
          );
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          const data: ResolveResponse = await res.json();
          setElements(data.elements);
          setNextCursor(data.nextCursor);
          setTotalCount(data.totalCount);
        } else {
          const res = await fetch(
            `/api/cosmos/cluster-elements?clusterId=${clusterId}`
          );
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          const data: ElementsResponse = await res.json();
          setElements(data.elements);
          setNextCursor(data.nextCursor ?? null);
          const cluster = clusters.find((c) => c.id === clusterId);
          setTotalCount(cluster?.numberOfElements ?? data.elements.length);
        }
      } catch {
        // Keep current state on error
      }
    },
    [user, clusters]
  );

  const loadMore = useCallback(async () => {
    if (!user || !nextCursor || loadingMore) return;

    setLoadingMore(true);
    try {
      let url: string;
      if (selectedCluster !== null) {
        const params = new URLSearchParams({
          clusterId: String(selectedCluster),
          cursor: nextCursor,
        });
        url = `/api/cosmos/cluster-elements?${params}`;
      } else {
        const params = new URLSearchParams({
          userId: user.id,
          cursor: nextCursor,
        });
        url = `/api/cosmos/elements?${params}`;
      }

      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const data: ElementsResponse = await res.json();
      setElements((prev) => {
        const existingIds = new Set(prev.map((e) => e.id));
        const newElements = data.elements.filter((e) => !existingIds.has(e.id));
        return [...prev, ...newElements];
      });
      setNextCursor(data.nextCursor ?? null);
    } catch {
      // Silently fail
    } finally {
      setLoadingMore(false);
    }
  }, [user, nextCursor, loadingMore, selectedCluster]);

  // Auto-load from URL params on mount
  useEffect(() => {
    if (!initialUsername) return;

    let cancelled = false;

    async function load() {
      try {
        const res = await fetch(
          `/api/cosmos/resolve?username=${encodeURIComponent(initialUsername!)}`
        );
        if (!res.ok) {
          const body = await res.json().catch(() => ({ error: "Request failed" }));
          throw new Error(body.error || `HTTP ${res.status}`);
        }

        const data: ResolveResponse = await res.json();
        if (cancelled) return;

        setUser(data.user);
        setElements(data.elements);
        setNextCursor(data.nextCursor);
        setTotalCount(data.totalCount);

        const clustersRes = await fetch(`/api/cosmos/clusters?userId=${data.user.id}`);
        if (clustersRes.ok) {
          const clustersData: ClustersResponse = await clustersRes.json();
          if (cancelled) return;
          if (clustersData.clusters) {
            setClusters(clustersData.clusters);

            if (initialClusterSlug) {
              const match = clustersData.clusters.find(
                (c) => c.slug === initialClusterSlug
              );
              if (match) {
                setSelectedCluster(match.id);
                setClusterLoading(true);

                const clusterRes = await fetch(
                  `/api/cosmos/cluster-elements?clusterId=${match.id}`
                );
                if (clusterRes.ok) {
                  const clusterData: ElementsResponse = await clusterRes.json();
                  if (cancelled) return;
                  setElements(clusterData.elements);
                  setNextCursor(clusterData.nextCursor ?? null);
                  setTotalCount(match.numberOfElements);
                }
                setClusterLoading(false);
              }
            }
          }
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Something went wrong");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => { cancelled = true; };
  }, [initialUsername, initialClusterSlug]);

  return {
    user,
    elements,
    loading,
    loadingMore,
    error,
    hasMore: !!nextCursor,
    search,
    loadMore,
    clusters,
    selectedCluster,
    selectCluster,
  };
}

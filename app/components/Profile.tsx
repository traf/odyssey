"use client";

import { useCosmosProfile } from "@/hooks/useCosmosProfile";
import Search from "@/components/Search";
import Nav from "@/components/Nav";
import Grid from "@/components/Grid";
import Skeleton from "@/components/Skeleton";

export default function Profile({
  initialUsername,
  initialClusterSlug,
}: {
  initialUsername?: string;
  initialClusterSlug?: string;
} = {}) {
  const {
    user,
    elements,
    loading,
    loadingMore,
    error,
    hasMore,
    search,
    loadMore,
    clusters,
    selectedCluster,
    selectCluster,
  } = useCosmosProfile(initialUsername, initialClusterSlug);

  const idle = !user && !loading && !error;
  const hasResults = !!user && !loading;

  if (idle) {
    return (
      <main className="flex items-center justify-center min-h-screen px-4">
        <Search onSearch={search} loading={loading} />
      </main>
    );
  }

  return (
    <main className="min-h-screen">
      <Nav
        user={hasResults ? user : null}
        loading={loading}
        onSearch={search}
        initialValue={initialUsername}
        clusters={hasResults ? clusters : []}
        selectedCluster={selectedCluster}
        onSelectCluster={selectCluster}
      />

      <div className="w-full px-1.5 py-1.5">
        {loading && <Skeleton />}

        {error && (
          <div className="flex items-center justify-center py-40">
            <p className="text-red-400/80 text-sm">{error}</p>
          </div>
        )}

        {hasResults && (
          <Grid
            elements={elements}
            onLoadMore={loadMore}
            hasMore={hasMore}
            loadingMore={loadingMore}
          />
        )}
      </div>
    </main>
  );
}

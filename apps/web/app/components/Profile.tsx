"use client";

import { useCosmosProfile } from "@/hooks/useCosmosProfile";
import Nav from "@/components/Nav";
import Grid from "@/components/Grid";
import Skeleton from "@/components/Skeleton";
import Landing from "@/components/Landing";

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

  const splash = !user && !loading;
  const hasResults = !!user && !loading;

  if (splash) {
    return <Landing onSearch={search} loading={loading} error={error} />;
  }

  return (
    <main className="min-h-screen">
      <Nav
        user={hasResults ? user : null}
        loading={loading}
        onSearch={search}
        initialValue={user?.username ?? initialUsername}
        clusters={hasResults ? clusters : []}
        selectedCluster={selectedCluster}
        onSelectCluster={selectCluster}
      />

      <div className="w-full px-1.5 py-1.5">
        {loading && <Skeleton />}

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

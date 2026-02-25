"use client";

import { useState } from "react";
import { UserProfile, CosmosCluster } from "@/lib/types";
import Search from "@/components/Search";
import Clusters from "@/components/Clusters";
import Button from "@/components/Button";

interface NavProps {
  user: UserProfile | null;
  loading: boolean;
  onSearch: (username: string) => void;
  initialValue?: string;
  clusters: CosmosCluster[];
  selectedCluster: number | null;
  onSelectCluster: (clusterId: number | null) => void;
}

export default function Nav({
  user,
  loading,
  onSearch,
  initialValue,
  clusters,
  selectedCluster,
  onSelectCluster,
}: NavProps) {
  const [copied, setCopied] = useState(false);

  function handleCopy() {
    if (!user) return;
    const cluster = selectedCluster !== null
      ? clusters.find((c) => c.id === selectedCluster)
      : null;
    const path = cluster
      ? `/api/${user.username}/${cluster.slug}`
      : `/api/${user.username}`;
    navigator.clipboard.writeText(`${window.location.origin}${path}`).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  return (
    <header className="sticky top-0 z-50 bg-black/80 backdrop-blur-xl border-b border-white/5">
      <div className="w-full px-4 py-3 flex items-center gap-3">
        {user && (
          <div className="flex items-center gap-2 shrink-0">
            {user.avatarUrl && (
              <img
                src={`${user.avatarUrl}?format=webp&w=64`}
                alt=""
                className="w-7 h-7 rounded-full"
              />
            )}
            <div className="hidden sm:block">
              <p className="text-xs font-medium leading-tight">{user.displayName}</p>
            </div>
          </div>
        )}
        <div className="flex-1 min-w-0">
          <Search onSearch={onSearch} loading={loading} compact initialValue={initialValue} />
        </div>
      </div>
      {user && clusters.length > 0 && (
        <div className="px-4 pb-3 flex items-center gap-3 overflow-x-auto no-scrollbar">
          <Clusters
            clusters={clusters}
            selected={selectedCluster}
            onSelect={onSelectCluster}
          />
          <div className="w-px h-5 bg-white/20 shrink-0" />
          <Button size="sm" active={copied} onClick={handleCopy}>
            {copied ? "Copied" : "API"}
          </Button>
        </div>
      )}
    </header>
  );
}

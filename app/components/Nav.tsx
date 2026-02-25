"use client";

import { UserProfile, CosmosCluster } from "@/lib/types";
import Search from "@/components/Search";
import Clusters from "@/components/Clusters";
import Button from "@/components/Button";
import API from "@/components/Api";

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
  return (
    <header className="sticky top-0 z-50 bg-black/90 backdrop-blur-lg -mb-1">
      <div className="w-full px-4 py-3 flex items-center gap-2">
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
        <div className="flex items-center gap-1.5 shrink-0">
          {user && clusters.length > 0 && (
            <Clusters
              clusters={clusters}
              selected={selectedCluster}
              onSelect={onSelectCluster}
            />
          )}
          <API />
          <a href="https://github.com/traf/ace" target="_blank" rel="noopener noreferrer">
            <Button size="sm">GitHub</Button>
          </a>
        </div>
      </div>
    </header>
  );
}

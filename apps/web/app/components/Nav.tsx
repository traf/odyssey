"use client";

import { UserProfile, CosmosCluster } from "@/lib/types";
import Search from "@/components/Search";
import Clusters from "@/components/Clusters";
import Button from "@/components/Button";
import Logo from "@/components/Logo";
import API from "@/components/Api";

interface NavProps {
  user?: UserProfile | null;
  loading?: boolean;
  onSearch?: (username: string) => void;
  initialValue?: string;
  clusters?: CosmosCluster[];
  selectedCluster?: number | null;
  onSelectCluster?: (clusterId: number | null) => void;
  showSearch?: boolean;
}

export default function Nav({
  user = null,
  loading = false,
  onSearch,
  initialValue,
  clusters = [],
  selectedCluster = null,
  onSelectCluster,
  showSearch = true,
}: NavProps) {
  return (
    <header className="sticky top-0 z-50 bg-background/90 backdrop-blur-lg -mb-1">
      <div className="w-full px-4 py-3 flex items-center gap-2">
        {showSearch ? (
          <>
            <div className="shrink-0 h-9 w-9 rounded-full border border-white/10 bg-white/10 overflow-hidden">
              {user?.avatarUrl && (
                <img
                  src={`${user.avatarUrl}?format=webp&w=64`}
                  alt=""
                  className="h-full w-full object-cover"
                />
              )}
            </div>
            <div className="flex-1 min-w-0 flex items-center gap-1.5">
              <Search onSearch={onSearch!} loading={loading} initialValue={initialValue} />
              {user && clusters.length > 0 && (
                <Clusters
                  clusters={clusters}
                  selected={selectedCluster}
                  onSelect={onSelectCluster!}
                />
              )}
            </div>
          </>
        ) : (
          <div className="flex-1 min-w-0">
            <Logo className="h-8 w-auto text-white" />
          </div>
        )}
        <div className="flex items-center gap-1.5 shrink-0">
          <API />
          <a href="https://github.com/traf/odyssey/releases/latest" target="_blank" rel="noopener noreferrer">
            <Button size="sm">Download for Mac</Button>
          </a>
          <a href="https://github.com/traf/odyssey" target="_blank" rel="noopener noreferrer">
            <Button size="sm">GitHub</Button>
          </a>
        </div>
      </div>
    </header>
  );
}

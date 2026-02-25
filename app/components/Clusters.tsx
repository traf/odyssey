"use client";

import { CosmosCluster } from "@/lib/types";
import Button from "@/components/Button";

interface ClustersProps {
  clusters: CosmosCluster[];
  selected: number | null;
  onSelect: (clusterId: number | null) => void;
}

export default function Clusters({ clusters, selected, onSelect }: ClustersProps) {
  if (clusters.length === 0) return null;

  return (
    <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar">
      <Button size="sm" active={selected === null} onClick={() => onSelect(null)}>
        All
      </Button>
      {clusters.map((cluster) => (
        <Button
          key={cluster.id}
          size="sm"
          active={selected === cluster.id}
          onClick={() => onSelect(cluster.id)}
        >
          {cluster.name}
          <span className="ml-1 opacity-50">{cluster.numberOfElements}</span>
        </Button>
      ))}
    </div>
  );
}

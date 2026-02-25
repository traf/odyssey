"use client";

import { useState, useRef, useEffect } from "react";
import { CosmosCluster } from "@/lib/types";
import Button from "@/components/Button";

interface ClustersProps {
  clusters: CosmosCluster[];
  selected: number | null;
  onSelect: (clusterId: number | null) => void;
}

export default function Clusters({ clusters, selected, onSelect }: ClustersProps) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function close(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, [open]);

  if (clusters.length === 0) return null;

  const label = selected === null
    ? "All"
    : clusters.find((c) => c.id === selected)?.name ?? "All";

  return (
    <div className="relative" ref={ref}>
      <Button size="sm" active={open} onClick={() => setOpen(!open)}>
        {label}
        <span className="ml-1.5 opacity-50">▾</span>
      </Button>
      {open && (
        <div className="absolute right-0 top-full mt-1.5 min-w-40 rounded-xl bg-neutral-900 border border-white/10 p-1 shadow-xl z-50">
          <button
            className={`w-full text-left px-3 py-2 text-xs rounded-lg cursor-pointer ${
              selected === null ? "text-white bg-white/10" : "text-neutral-400 hover:text-white hover:bg-white/5"
            }`}
            onClick={() => { onSelect(null); setOpen(false); }}
          >
            All
          </button>
          {clusters.map((cluster) => (
            <button
              key={cluster.id}
              className={`w-full text-left px-3 py-2 text-xs rounded-lg cursor-pointer ${
                selected === cluster.id ? "text-white bg-white/10" : "text-neutral-400 hover:text-white hover:bg-white/5"
              }`}
              onClick={() => { onSelect(cluster.id); setOpen(false); }}
            >
              {cluster.name}
              <span className="ml-1.5 opacity-50">{cluster.numberOfElements}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

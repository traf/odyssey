"use client";

import { useRef, useEffect, useCallback, useMemo } from "react";
import { CosmosElement } from "@/lib/types";
import { useColumnCount } from "@/hooks/useColumnCount";
import Card from "@/components/Card";
import Spinner from "@/components/Spinner";

interface GridProps {
  elements: CosmosElement[];
  onLoadMore: () => void;
  hasMore: boolean;
  loadingMore: boolean;
}

function distribute(items: CosmosElement[], numCols: number): CosmosElement[][] {
  const columns: CosmosElement[][] = Array.from({ length: numCols }, () => []);
  const heights = new Array(numCols).fill(0);

  for (const item of items) {
    let minIdx = 0;
    for (let i = 1; i < numCols; i++) {
      if (heights[i] < heights[minIdx]) minIdx = i;
    }
    columns[minIdx].push(item);
    const ratio = item.width && item.height ? item.height / item.width : 1;
    heights[minIdx] += ratio;
  }

  return columns;
}

export default function Grid({ elements, onLoadMore, hasMore, loadingMore }: GridProps) {
  const sentinelRef = useRef<HTMLDivElement>(null);
  const numCols = useColumnCount();
  const onLoadMoreStable = useCallback(onLoadMore, [onLoadMore]);

  useEffect(() => {
    if (!hasMore || loadingMore) return;
    const sentinel = sentinelRef.current;
    if (!sentinel) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) onLoadMoreStable();
      },
      { rootMargin: "800px" }
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [hasMore, loadingMore, onLoadMoreStable]);

  const images = useMemo(
    () => elements.filter((el) => el.type === "image"),
    [elements]
  );

  const columns = useMemo(
    () => distribute(images, numCols),
    [images, numCols]
  );

  return (
    <>
      <div className="flex gap-2">
        {columns.map((col, i) => (
          <div key={i} className="flex-1 min-w-0">
            {col.map((el) => (
              <Card key={el.id} element={el} />
            ))}
          </div>
        ))}
      </div>

      <div ref={sentinelRef} className="h-1" />

      {loadingMore && (
        <div className="flex justify-center py-8">
          <Spinner className="h-5 w-5 text-neutral-400" />
        </div>
      )}

      {!hasMore && images.length > 0 && (
        <p className="text-center text-neutral-600 text-xs py-10 tracking-wide">
          {images.length} images
        </p>
      )}
    </>
  );
}

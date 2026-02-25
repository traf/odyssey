"use client";

import { useColumnCount } from "@/hooks/useColumnCount";

export default function Skeleton() {
  const numCols = useColumnCount();

  return (
    <div className="flex gap-1.5">
      {Array.from({ length: numCols }).map((_, col) => (
        <div key={col} className="flex-1 min-w-0">
          {Array.from({ length: 4 }).map((_, row) => (
            <div
              key={row}
              className="mb-1.5 bg-neutral-900 rounded-md animate-pulse"
              style={{ height: `${180 + ((col * 3 + row) * 47 % 160)}px` }}
            />
          ))}
        </div>
      ))}
    </div>
  );
}

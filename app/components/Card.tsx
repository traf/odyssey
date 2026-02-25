"use client";

import { useState } from "react";
import { CosmosElement } from "@/lib/types";

export default function Card({ element }: { element: CosmosElement }) {
  const [loaded, setLoaded] = useState(false);

  const src = `${element.url}?format=webp&w=600`;
  const aspectRatio =
    element.width && element.height
      ? `${element.width} / ${element.height}`
      : undefined;

  return (
    <a href={`https://www.cosmos.so/e/${element.id}`} target="_blank" rel="noopener noreferrer" className="block mb-1.5">
      <div
        className="relative overflow-hidden rounded-md bg-neutral-900"
        style={{ aspectRatio }}
      >
        {!loaded && <div className="absolute inset-0 bg-neutral-900 animate-pulse" />}
        <img
          src={src}
          alt=""
          width={element.width ?? undefined}
          height={element.height ?? undefined}
          loading="lazy"
          onLoad={() => setLoaded(true)}
          className={`w-full h-full object-cover duration-500 ${
            loaded ? "opacity-100" : "opacity-0"
          }`}
        />
      </div>
    </a>
  );
}

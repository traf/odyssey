"use client";

import { useState } from "react";

const BASE_URL = "https://odyssey-hq.vercel.app";

const endpoints = [
  { key: "all", label: "All images", display: `GET ${BASE_URL}/api/{username}`, copy: `${BASE_URL}/api/{username}` },
  { key: "cluster", label: "Cluster images", display: `GET ${BASE_URL}/api/{username}/{cluster}`, copy: `${BASE_URL}/api/{username}/{cluster}` },
  { key: "example", label: "Example", display: `curl ${BASE_URL}/api/traf/systems`, copy: `curl ${BASE_URL}/api/traf/systems` },
];

export default function Endpoints() {
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  function copyUrl(key: string, url: string) {
    navigator.clipboard.writeText(url).then(() => {
      setCopiedKey(key);
      setTimeout(() => setCopiedKey(null), 1000);
    });
  }

  return (
    <div className="space-y-4">
      {endpoints.map((endpoint) => (
        <div key={endpoint.key}>
          <p className="text-xs text-neutral-500 mb-1.5">{endpoint.label}</p>
          <button
            className={`w-full text-left text-xs font-mono bg-white/5 hover:bg-white/10 rounded-lg px-3 py-2.5 cursor-pointer transition-colors ${copiedKey === endpoint.key ? "text-green-500" : "text-neutral-300"}`}
            onClick={() => copyUrl(endpoint.key, endpoint.copy)}
          >
            {endpoint.display}
          </button>
        </div>
      ))}

      <pre className="text-xs font-mono bg-white/5 rounded-lg px-3 py-2.5 text-neutral-400 overflow-x-auto">
{`{
  "images": ["https://cdn.cosmos.so/...", "..."],
  "count": 75
}`}
      </pre>

      <p className="text-xs text-neutral-500">Responses are cached for up to 5 minutes.</p>
    </div>
  );
}

"use client";

import { useState } from "react";
import Button from "@/components/Button";
import Modal from "@/components/Modal";

const BASE_URL = "https://ace-hq.vercel.app";

export default function Api() {
  const [open, setOpen] = useState(false);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  function copyUrl(key: string, url: string) {
    navigator.clipboard.writeText(url).then(() => {
      setCopiedKey(key);
      setTimeout(() => setCopiedKey(null), 1000);
    });
  }

  return (
    <>
      <Button size="sm" onClick={() => setOpen(true)}>API</Button>

      <Modal open={open} onClose={() => setOpen(false)}>
        <h2 className="text-sm font-semibold mb-1">Ace</h2>
        <p className="text-xs text-neutral-400 mb-5">
          A simple, unofficial <a href="https://cosmos.so" target="_blank" rel="noopener noreferrer" className="underline">Cosmos</a> API for fetching images from profiles & clusters.
        </p>

        <div className="space-y-4">
          <div>
            <p className="text-xs text-neutral-500 mb-1.5">All images</p>
            <button
              className={`w-full text-left text-xs font-mono bg-white/5 hover:bg-white/10 rounded-lg px-3 py-2.5 cursor-pointer transition-colors ${copiedKey === "all" ? "text-green-500" : "text-neutral-300"}`}
              onClick={() => copyUrl("all", `${BASE_URL}/api/{username}`)}
            >
              GET {BASE_URL}/api/&#123;username&#125;
            </button>
          </div>

          <div>
            <p className="text-xs text-neutral-500 mb-1.5">Cluster images</p>
            <button
              className={`w-full text-left text-xs font-mono bg-white/5 hover:bg-white/10 rounded-lg px-3 py-2.5 cursor-pointer transition-colors ${copiedKey === "cluster" ? "text-green-500" : "text-neutral-300"}`}
              onClick={() => copyUrl("cluster", `${BASE_URL}/api/{username}/{cluster}`)}
            >
              GET {BASE_URL}/api/&#123;username&#125;/&#123;cluster&#125;
            </button>
          </div>

          <div>
            <p className="text-xs text-neutral-500 mb-1.5">Example</p>
            <button
              className={`w-full text-left text-xs font-mono bg-white/5 hover:bg-white/10 rounded-lg px-3 py-2.5 cursor-pointer transition-colors ${copiedKey === "example" ? "text-green-500" : "text-neutral-300"}`}
              onClick={() => copyUrl("example", `curl ${BASE_URL}/api/traf/systems`)}
            >
              curl {BASE_URL}/api/traf/systems
            </button>
          </div>

          <pre className="text-xs font-mono bg-white/5 rounded-lg px-3 py-2.5 text-neutral-400 overflow-x-auto">
{`{
  "images": ["https://cdn.cosmos.so/...", "..."],
  "count": 75
}`}
          </pre>

          <p className="text-xs text-neutral-500">Responses are cached for 5 minutes.</p>
        </div>
      </Modal>
    </>
  );
}

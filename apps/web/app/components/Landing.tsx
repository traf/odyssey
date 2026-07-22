"use client";

import Search from "@/components/Search";
import Mark from "@/components/Mark";
import Odyssey from "@/components/Odyssey";
import Button from "@/components/Button";
import Apple from "@/components/Apple";
import Link from "@/components/Link";
import Api from "@/components/Api";

interface LandingProps {
  onSearch: (username: string) => void;
  loading: boolean;
  error: string | null;
}

export default function Landing({ onSearch, loading, error }: LandingProps) {
  return (
    <main className="min-h-screen grid md:grid-cols-2">
      <section className="flex items-center justify-center px-8 py-20 border-b border-white/10 shadow-[0_1px_0_#000] md:border-b-0 md:border-r md:shadow-[1px_0_0_#000]">
        <div className="w-full max-w-xs flex flex-col items-center text-center scale-110">
          <div className="h-9 flex items-center justify-center">
            <Mark className="h-9 w-auto text-white" />
          </div>
          <h1 className="mt-6 text-3xl font-semibold tracking-tight">API</h1>
          <p className="mt-2 h-12 text-base text-neutral-400 leading-relaxed text-balance">
            An unofficial <Link href="https://cosmos.so">Cosmos</Link> API for any profile or cluster.
          </p>
          <Search onSearch={onSearch} loading={loading} size="large" className="mt-8" />
          {error && <p className="mt-3 text-neutral-500 text-sm">{error}</p>}
          <Api label="API reference" variant="link" className="mt-5" />
        </div>
      </section>

      <section className="flex items-center justify-center px-8 py-20">
        <div className="w-full max-w-xs flex flex-col items-center text-center scale-110">
          <div className="h-9 flex items-center justify-center">
            <Odyssey className="h-9 w-auto text-white" />
          </div>
          <h1 className="mt-6 text-3xl font-semibold tracking-tight">Mac app</h1>
          <p className="mt-2 h-12 text-base text-neutral-400 leading-relaxed text-balance">
            A native mac app to browse your Cosmos from your desktop.
          </p>
          <a href="https://github.com/traf/odyssey/releases/latest/download/Odyssey.dmg" className="mt-8">
            <Button size="lg" active className="flex items-center gap-2">
              <Apple className="h-5 w-5" />
              Download for Mac
            </Button>
          </a>
          <Link href="https://github.com/traf/odyssey" className="mt-5 text-sm">
            View on GitHub
          </Link>
        </div>
      </section>
    </main>
  );
}

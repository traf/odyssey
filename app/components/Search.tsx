"use client";

import { useState, FormEvent } from "react";
import Button from "@/components/Button";
import Spinner from "@/components/Spinner";

interface SearchProps {
  onSearch: (username: string) => void;
  loading: boolean;
  compact?: boolean;
  initialValue?: string;
}

export default function Search({ onSearch, loading, compact, initialValue }: SearchProps) {
  const [value, setValue] = useState(initialValue ?? "");

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const username = value.trim().replace(/^.*cosmos\.so\//, "").replace(/\/$/, "");
    if (username) onSearch(username);
  }

  return (
    <form
      onSubmit={handleSubmit}
      className={`flex items-center gap-3 ${compact ? "w-full max-w-xs" : "w-full max-w-md"}`}
    >
      <div className="flex items-center flex-1 bg-white/10 border border-white/10 rounded-full overflow-hidden focus-within:border-white/40">
        <span className="pl-5 pr-0.5 text-neutral-500 text-sm select-none whitespace-nowrap">
          cosmos.so/
        </span>
        <input
          type="text"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="username"
          disabled={loading}
          className={`flex-1 bg-transparent pr-5 text-white text-sm outline-none placeholder:text-neutral-600 disabled:opacity-50 ${
            compact ? "h-9" : "h-10"
          }`}
          autoFocus
        />
      </div>
      <Button
        type="submit"
        active
        disabled={loading || !value.trim()}
        size="sm"
      >
        {loading ? <Spinner /> : "View"}
      </Button>
    </form>
  );
}

"use client";

import { useState, useEffect, useRef } from "react";
import Mark from "@/components/Mark";
import Spinner from "@/components/Spinner";

interface SearchProps {
  onSearch: (username: string) => void;
  loading: boolean;
  size?: "compact" | "large";
  initialValue?: string;
  className?: string;
}

export default function Search({ onSearch, loading, size = "compact", initialValue, className = "" }: SearchProps) {
  const [value, setValue] = useState(initialValue ?? "");
  const [edited, setEdited] = useState(false);
  const synced = useRef(initialValue ?? "");

  // Sync the field to a newly-loaded profile, but never clobber what the user is typing.
  useEffect(() => {
    const next = initialValue ?? "";
    if (next && next !== synced.current && !edited) {
      synced.current = next;
      setValue(next);
    }
  }, [initialValue, edited]);

  function submit() {
    const username = value.trim().replace(/^.*cosmos\.so\//, "").replace(/\/$/, "");
    if (username) {
      setEdited(false);
      synced.current = username;
      setValue(username);
      onSearch(username);
    }
  }

  const large = size === "large";

  return (
    <form
      onSubmit={(e) => { e.preventDefault(); submit(); }}
      className={`flex items-center ${large ? "w-full max-w-[250px] mx-auto" : "w-full max-w-[220px]"} ${className}`}
    >
      <div
        className={`flex items-center flex-1 bg-white/10 border border-white/10 rounded-full overflow-hidden transition-colors focus-within:bg-white/[0.12] ${
          large ? "h-14 px-5 text-base" : "h-9 pl-5 text-sm"
        }`}
      >
        {large && (
          <Mark className={`shrink-0 h-5 w-auto mr-3 text-white ${loading ? "animate-spin" : ""}`} />
        )}
        <span className={`shrink-0 select-none whitespace-nowrap ${large ? "text-white" : "text-neutral-500 pr-0.5"}`}>
          cosmos.so/
        </span>
        <input
          type="search"
          name="q"
          value={value}
          onChange={(e) => { setValue(e.target.value); setEdited(true); }}
          onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); submit(); } }}
          placeholder="handle"
          autoComplete="off"
          autoCorrect="off"
          autoCapitalize="off"
          spellCheck={false}
          data-1p-ignore
          data-lpignore="true"
          data-form-type="other"
          className={`flex-1 min-w-0 h-full bg-transparent text-white outline-none placeholder:text-neutral-600 ${
            large ? "" : "pr-3"
          }`}
          autoFocus
        />
        {!large && loading && <span className="shrink-0 pr-4"><Spinner /></span>}
        {edited && value.trim() && (
          <span className={`shrink-0 text-neutral-600 select-none ${large ? "pr-1" : "pr-4 text-sm"}`}>⏎</span>
        )}
      </div>
    </form>
  );
}

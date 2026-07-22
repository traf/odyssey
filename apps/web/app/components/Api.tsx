"use client";

import { useState } from "react";
import Button from "@/components/Button";
import Modal from "@/components/Modal";
import Endpoints from "@/components/Endpoints";
import { linkStyle } from "@/components/Link";

export default function Api({
  label = "API",
  variant = "button",
  className = "",
}: {
  label?: string;
  variant?: "button" | "link";
  className?: string;
}) {
  const [open, setOpen] = useState(false);

  return (
    <>
      {variant === "link" ? (
        <button
          onClick={() => setOpen(true)}
          className={`text-sm ${linkStyle} ${className}`}
        >
          {label}
        </button>
      ) : (
        <Button size="sm" onClick={() => setOpen(true)}>{label}</Button>
      )}

      <Modal open={open} onClose={() => setOpen(false)}>
        <h2 className="text-sm font-semibold mb-1">Odyssey</h2>
        <p className="text-xs text-neutral-400 mb-5">
          A simple, unofficial <a href="https://cosmos.so" target="_blank" rel="noopener noreferrer" className="underline">Cosmos</a> API for fetching images from profiles & clusters.
        </p>

        <Endpoints />
      </Modal>
    </>
  );
}

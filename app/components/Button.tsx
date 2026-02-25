"use client";

import { ButtonHTMLAttributes } from "react";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  active?: boolean;
  size?: "sm" | "md";
}

export default function Button({
  active,
  size = "md",
  className = "",
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={`shrink-0 rounded-full font-medium cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed ${
        size === "sm" ? "h-9 px-4 text-xs" : "h-10 px-5 text-sm"
      } ${
        active
          ? "bg-white text-black"
          : "bg-white/10 text-neutral-400 hover:text-neutral-200"
      } ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}

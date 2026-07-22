"use client";

import { ButtonHTMLAttributes } from "react";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  active?: boolean;
  size?: "sm" | "md" | "lg";
}

const sizes = {
  sm: "h-9 px-4 text-sm",
  md: "h-10 px-5 text-sm",
  lg: "h-14 px-7 text-base",
};

export default function Button({
  active,
  size = "md",
  className = "",
  children,
  ...props
}: ButtonProps) {
  return (
    <button
      className={`shrink-0 rounded-full border font-medium cursor-pointer disabled:opacity-30 disabled:cursor-not-allowed ${sizes[size]} ${
        active
          ? "bg-white border-white text-black"
          : "bg-white/10 border-white/10 text-neutral-400 hover:text-neutral-200"
      } ${className}`}
      {...props}
    >
      {children}
    </button>
  );
}

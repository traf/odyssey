import { AnchorHTMLAttributes } from "react";

export const linkStyle = "underline underline-offset-2 text-neutral-400 hover:text-white transition-colors cursor-pointer";

export default function Link({ className = "", children, ...props }: AnchorHTMLAttributes<HTMLAnchorElement>) {
  return (
    <a
      target="_blank"
      rel="noopener noreferrer"
      className={`${linkStyle} ${className}`}
      {...props}
    >
      {children}
    </a>
  );
}

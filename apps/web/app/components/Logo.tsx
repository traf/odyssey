export default function Logo({ className = "h-9 w-auto" }: { className?: string }) {
  return <img src="/logo.png" alt="Odyssey" className={className} />;
}

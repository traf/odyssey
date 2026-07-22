import type { Metadata } from "next";
import { Geist } from "next/font/google";
import "./globals.css";

const geist = Geist({
  variable: "--font-geist",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://odyssey-hq.vercel.app"),
  title: "Odyssey",
  description: "Unofficial Cosmos API & native mac app",
  openGraph: {
    title: "Odyssey",
    description: "Unofficial Cosmos API & native mac app",
    url: "https://odyssey-hq.vercel.app",
    siteName: "Odyssey",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Odyssey",
    description: "Unofficial Cosmos API & native mac app",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${geist.variable} font-sans bg-background text-foreground min-h-screen antialiased`}
      >
        {children}
      </body>
    </html>
  );
}

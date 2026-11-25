import React from "react";
import Image from "next/image";
import Link from "next/link";
import { Download } from "lucide-react";
import { GITHUB_RELEASE_URL, ROUTES } from "../../utils/main.util";

/**
 * Compact header used by the legal pages. It mirrors the landing page header
 * (same max width, padding, colours and download button) without the
 * scroll-driven navigation that only makes sense on the one-pager.
 */
export function SiteHeader({ active }: { active?: "privacy" | "terms" }) {
  const linkClass = (isActive: boolean) =>
    `transition-colors ${isActive ? "text-white" : "hover:text-white"}`;

  return (
    <header className="sticky top-0 z-40 backdrop-blur-md bg-black/80 border-b border-[#262626]/80 px-6 sm:px-10">
      <div className="max-w-7xl mx-auto py-4 flex items-center justify-between">
        <Link href={ROUTES.home} className="flex items-center gap-3">
          <div className="relative w-9 h-9 rounded-md overflow-hidden border border-[#262626] bg-[#141414] p-1 flex items-center justify-center shadow-lg shadow-black/50">
            <Image
              src="/habitme_logo_svg.svg"
              alt="HabitMe Logo"
              width={32}
              height={32}
              className="object-contain rounded-sm"
            />
          </div>
          <span className="font-bold text-lg tracking-tight flex items-center gap-2">
            HabitMe
            <span className="hidden sm:inline text-[10px] font-semibold uppercase tracking-wider bg-[#22C55E]/15 text-[#22C55E] px-2 py-0.5 rounded-full border border-[#22C55E]/30">
              Keep the habit alive.
            </span>
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-8 text-sm text-[#8A8A8A]">
          <Link href={ROUTES.home} className="hover:text-white transition-colors">
            Home
          </Link>
          <Link
            href={ROUTES.homeFeatures}
            className="hover:text-white transition-colors"
          >
            Features
          </Link>
          <Link
            href={ROUTES.privacy}
            className={linkClass(active === "privacy")}
          >
            Privacy
          </Link>
          <Link href={ROUTES.terms} className={linkClass(active === "terms")}>
            Terms
          </Link>
        </nav>

        <div className="flex items-center gap-3">
          <Link
            href={GITHUB_RELEASE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold bg-[#22C55E] text-black hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Download APK</span>
          </Link>
        </div>
      </div>
    </header>
  );
}

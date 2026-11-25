"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Download, Menu as MenuIcon, X } from "lucide-react";
import { scrollToSection, queueSection } from "../../utils/section.util";
import { GITHUB_RELEASE_URL, ROUTES } from "../../utils/main.util";

/**
 * Compact header used by the legal pages. It mirrors the landing page header
 * (same max width, padding, colours and download button) without the
 * scroll-driven navigation that only makes sense on the one-pager.
 */
export function SiteHeader({ active }: { active?: "privacy" | "terms" }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const router = useRouter();
  const linkClass = (isActive: boolean) =>
    `transition-colors ${isActive ? "text-white" : "hover:text-white"}`;

  const goToFeatures = () => {
    setMenuOpen(false);
    if (scrollToSection("features")) return;
    queueSection("features");
    router.push(ROUTES.home);
  };

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMenuOpen(false);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return (
    <header className="sticky top-0 z-40 backdrop-blur-md bg-black/80 border-b border-[#262626]/80 px-4 sm:px-10">
      <div className="max-w-7xl mx-auto py-3 sm:py-4 flex items-center justify-between gap-3">
        <Link href={ROUTES.home} className="flex items-center gap-3">
          <div className="relative w-8 h-8 sm:w-9 sm:h-9 shrink-0 rounded-md overflow-hidden border border-[#262626] bg-[#141414] p-1 flex items-center justify-center shadow-lg shadow-black/50">
            <Image
              src="/habitme_logo_svg.svg"
              alt="HabitMe Logo"
              width={32}
              height={32}
              className="object-contain rounded-sm"
            />
          </div>
          <span className="font-bold text-base sm:text-lg tracking-tight flex items-center gap-2">
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
          <button
            type="button"
            onClick={goToFeatures}
            className="hover:text-white transition-colors"
          >
            Features
          </button>
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

        <div className="flex items-center gap-2 sm:gap-3">
          <Link
            href={GITHUB_RELEASE_URL}
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Download the latest HabitMe APK"
            className="inline-flex items-center justify-center gap-2 px-3 sm:px-4 py-2 rounded-xl text-xs font-semibold bg-[#22C55E] text-black hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20"
          >
            <Download className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Download APK</span>
          </Link>
          <button
            type="button"
            onClick={() => setMenuOpen((open) => !open)}
            aria-expanded={menuOpen}
            aria-controls="legal-mobile-nav"
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            className="md:hidden inline-flex h-9 w-9 items-center justify-center rounded-xl border border-[#262626] bg-[#141414] text-white transition hover:bg-[#1c1c1c]"
          >
            {menuOpen ? <X className="w-4 h-4" /> : <MenuIcon className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Mobile navigation for the legal pages */}
      <div
        id="legal-mobile-nav"
        className={`md:hidden absolute inset-x-0 top-full overflow-hidden border-b border-[#262626]/80 bg-black/95 shadow-lg shadow-black/40 backdrop-blur-md transition-[max-height,opacity] duration-300 ease-out ${
          menuOpen
            ? "max-h-72 opacity-100"
            : "pointer-events-none max-h-0 opacity-0"
        }`}
      >
        <nav className="flex flex-col gap-1 px-2 py-2 text-sm text-[#8A8A8A]">
          <Link
            href={ROUTES.home}
            onClick={() => setMenuOpen(false)}
            className="rounded-xl px-3 py-3 hover:bg-[#141414] hover:text-white transition-colors"
          >
            Home
          </Link>
          <button
            type="button"
            onClick={goToFeatures}
            className="rounded-xl px-3 py-3 text-left hover:bg-[#141414] hover:text-white transition-colors"
          >
            Features
          </button>
          <Link
            href={ROUTES.privacy}
            onClick={() => setMenuOpen(false)}
            className={`rounded-xl px-3 py-3 hover:bg-[#141414] hover:text-white transition-colors ${
              active === "privacy" ? "text-white" : ""
            }`}
          >
            Privacy
          </Link>
          <Link
            href={ROUTES.terms}
            onClick={() => setMenuOpen(false)}
            className={`rounded-xl px-3 py-3 hover:bg-[#141414] hover:text-white transition-colors ${
              active === "terms" ? "text-white" : ""
            }`}
          >
            Terms
          </Link>
        </nav>
      </div>
    </header>
  );
}

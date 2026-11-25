"use client";

import React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { GithubIcon } from "./utils/GithubIcon";
import { scrollToSection, queueSection, SiteSection } from "../../utils/section.util";
import { GITHUB_RELEASE_URL, MADE_BY_URL, ROUTES } from "../../utils/main.util";

/** Shared footer so every page keeps identical margins and link set. */
export function SiteFooter() {
  const router = useRouter();

  /**
   * Footer section buttons glide exactly like the navbar. On legal pages the
   * section is not mounted yet, so we go home and let the page scroll to it
   * once its ref registers — no #hash is ever used.
   */
  const goToSection = (name: SiteSection) => {
    if (scrollToSection(name)) return;
    queueSection(name);
    router.push(ROUTES.home);
  };

  return (
    <footer className="border-t border-[#262626] py-10 px-6 sm:px-10 text-xs text-[#8A8A8A]">
      <div className="max-w-7xl mx-auto flex flex-col items-center justify-between gap-6 sm:gap-4">
        <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-3">
          <Link
            href={MADE_BY_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-white transition-colors"
          >
            itsmeprince.com
          </Link>
          <Link
            href={GITHUB_RELEASE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-white transition-colors flex items-center gap-1"
          >
            <GithubIcon className="w-3.5 h-3.5" />
            <span>GitHub Release</span>
          </Link>
          <button
            type="button"
            onClick={() => goToSection("features")}
            className="hover:text-white transition-colors"
          >
            Features
          </button>
          <button
            type="button"
            onClick={() => goToSection("demo")}
            className="hover:text-white transition-colors"
          >
            App UI Demo
          </button>
          <Link href={ROUTES.privacy} className="hover:text-white transition-colors">
            Privacy Policy
          </Link>
          <Link href={ROUTES.terms} className="hover:text-white transition-colors">
            Terms &amp; Conditions
          </Link>
        </div>

        <div className="flex items-center gap-2">
          <span>© 2026 HabitMe.</span>
          <span>All rights reserved.</span>
        </div>
      </div>
    </footer>
  );
}

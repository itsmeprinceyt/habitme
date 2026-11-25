import React from "react";
import Link from "next/link";
import { ArrowLeft, FileText } from "lucide-react";
import { SiteHeader } from "./SiteHeader";
import { SiteFooter } from "./SiteFooter";
import { ROUTES } from "../../utils/main.util";

export interface LegalSection {
  id: string;
  title: string;
  body: React.ReactNode;
}

interface LegalPageProps {
  active: "privacy" | "terms";
  eyebrow: string;
  title: string;
  intro: string;
  updated: string;
  sections: LegalSection[];
}

/**
 * Shared shell for the legal documents: same background glow, max width,
 * horizontal padding and card styling as the landing page sections.
 */
export function LegalPage({
  active,
  eyebrow,
  title,
  intro,
  updated,
  sections,
}: LegalPageProps) {
  return (
    <div className="min-h-screen bg-black text-white selection:bg-[#22C55E]/20 flex flex-col">
      <div className="fixed inset-0 pointer-events-none bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(34,197,94,0.12),rgba(255,255,255,0))]" />

      <SiteHeader active={active} />

      <main className="flex-1 relative z-10 pt-14 sm:pt-20 pb-20 px-6 sm:px-10">
        <div className="max-w-4xl mx-auto">
          <Link
            href={ROUTES.home}
            className="inline-flex items-center gap-1.5 text-xs text-[#8A8A8A] hover:text-white transition-colors mb-8"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            Back to HabitMe
          </Link>

          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-[#262626] bg-[#0D0D0D] text-xs text-[#8A8A8A] mb-6 shadow-inner">
            <FileText className="w-3.5 h-3.5 text-[#22C55E]" />
            <span>{eyebrow}</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-extrabold tracking-tight leading-[1.15] mb-4">
            {title}
          </h1>
          <p className="text-base sm:text-lg text-[#8A8A8A] leading-relaxed max-w-2xl mb-3">
            {intro}
          </p>
          <p className="text-xs text-[#8A8A8A] mb-10">Last updated: {updated}</p>

          {/* On this page */}
          <nav
            aria-label="On this page"
            className="mb-8 p-5 sm:p-6 rounded-2xl bg-[#0D0D0D] border border-[#262626]"
          >
            <div className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#22C55E] mb-3">
              On this page
            </div>
            <ol className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 text-sm text-[#8A8A8A]">
              {sections.map((section, index) => (
                <li key={section.id}>
                  <Link
                    href={`#${section.id}`}
                    className="hover:text-white transition-colors"
                  >
                    <span className="text-[#22C55E] mr-1.5 font-mono text-xs">
                      {String(index + 1).padStart(2, "0")}
                    </span>
                    {section.title}
                  </Link>
                </li>
              ))}
            </ol>
          </nav>

          <div className="space-y-5">
            {sections.map((section) => (
              <section
                key={section.id}
                id={section.id}
                className="scroll-mt-24 p-6 sm:p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626]"
              >
                <h2 className="text-lg sm:text-xl font-bold mb-3">
                  {section.title}
                </h2>
                <div className="text-sm sm:text-[15px] text-[#8A8A8A] leading-relaxed space-y-3 [&_a]:text-[#22C55E] [&_a:hover]:underline [&_strong]:text-white [&_ul]:list-disc [&_ul]:pl-5 [&_ul]:space-y-1.5">
                  {section.body}
                </div>
              </section>
            ))}
          </div>

          <p className="text-xs text-[#8A8A8A] mt-8 leading-relaxed">
            This document is written in plain language for clarity. If anything
            here is unclear, reach out and we will explain it.
          </p>
        </div>
      </main>

      <SiteFooter />
    </div>
  );
}

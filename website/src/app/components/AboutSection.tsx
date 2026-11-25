import React from "react";
import Image from "next/image";
import Link from "next/link";
import { Download, ExternalLink } from "lucide-react";
import { GITHUB_RELEASE_URL, MADE_BY_URL } from "../../utils/main.util";

export function AboutSection() {
  return (
    <section id="about" className="py-24 px-6 sm:px-10">
      <div className="max-w-7xl mx-auto">
        {/* Why HabitMe exists — mirrors the app's Guide page */}
        <div data-reveal className="text-center max-w-3xl mx-auto mb-16">
          <span className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#22C55E]">
            Why HabitMe Exists
          </span>
          <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight mt-4 mb-6">
            Habits are easy to start. Breaks are what break them.
          </h2>
          <p className="text-sm sm:text-base text-[#8A8A8A] leading-relaxed mb-4">
            We repeat the same things day after day — and that is exactly how
            they become our habits. But the moment you take a break, that habit
            starts to distort. One skipped day turns into a skipped week, and
            things quietly slip out of your hands.
          </p>
          <p className="text-sm sm:text-base text-[#8A8A8A] leading-relaxed">
            HabitMe was built so you can create habits for yourself, stay
            consistent even after a pause, and remain obedient to your goals and
            your own betterment — without missing a beat.
          </p>
        </div>

        <div
          data-reveal
          className="p-10 sm:p-16 rounded-3xl bg-linear-to-b from-[#141414] to-[#0D0D0D] border border-[#262626] relative overflow-hidden text-center flex flex-col items-center"
        >
          <div className="w-16 h-16 rounded-2xl bg-black border border-[#262626] p-2 flex items-center justify-center mb-6 shadow-xl">
            <Image
              src="/habitme_logo_svg.svg"
              alt="HabitMe"
              width={48}
              height={48}
              className="rounded-lg"
            />
          </div>

          <h2 className="text-2xl sm:text-4xl font-extrabold tracking-tight mb-4">
            Keep the habit alive.
          </h2>
          <p className="text-sm sm:text-base text-[#8A8A8A] max-w-xl mb-8">
            Download the latest APK release from GitHub and pick your habits
            back up today. No account setup, no cloud sync, and your habit data
            stays on your device.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-4">
            <Link
              href={GITHUB_RELEASE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3.5 rounded-xl bg-[#22C55E] text-black font-semibold text-sm hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20 flex items-center gap-2"
            >
              <Download className="w-4 h-4" />
              <span>Download Latest Release</span>
            </Link>
            <Link
              href={MADE_BY_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3.5 rounded-xl bg-black border border-[#262626] text-white font-semibold text-sm hover:bg-[#1c1c1c] transition flex items-center gap-2"
            >
              <ExternalLink className="w-4 h-4 text-[#8A8A8A]" />
              <span>Made By ItsMe Prince</span>
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

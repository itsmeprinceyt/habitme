import React from "react";
import Link from "next/link";
import {
  Download,
  Smartphone,
  WifiOff,
  ShieldCheck,
  Clock,
  Database,
} from "lucide-react";
import { GithubIcon } from "./utils/GithubIcon";
import { GITHUB_RELEASE_URL, GITHUB_REPO_URL } from "../../utils/main.util";

interface HeroSectionProps {
  onNavigateToDemo: () => void;
}

export function HeroSection({ onNavigateToDemo }: HeroSectionProps) {
  return (
    <section className="pt-16 sm:pt-24 pb-16 px-6 sm:px-10">
      <div className="max-w-7xl mx-auto text-center flex flex-col items-center">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-[#262626] bg-[#0D0D0D] text-xs text-[#8A8A8A] mb-8 shadow-inner">
          <span className="w-2 h-2 rounded-full bg-[#22C55E] animate-pulse" />
          <span className="flex items-center gap-1.5">
            <WifiOff className="w-3.5 h-3.5 text-[#22C55E]" />
            No Account • No Cloud Sync • Instant Performance
          </span>
        </div>

        <h1 className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight max-w-4xl leading-[1.1] mb-6">
          Take a break. <br className="hidden sm:inline" />
          <span className="bg-linear-to-r from-white via-zinc-200 to-[#8A8A8A] bg-clip-text text-transparent">
            Don&apos;t lose the habit.
          </span>
        </h1>

        <p className="text-base sm:text-xl text-[#8A8A8A] max-w-2xl font-normal leading-relaxed mb-10">
          We repeat the same things every day — and that is exactly how they
          become our habits. But pause for a while and the habit starts to
          distort, and things quietly slip away. HabitMe keeps you obedient to
          your goals and your own betterment, even after a break. No account, no
          cloud sync, flexible recurrence and exact local reminders.
        </p>

        <div className="flex flex-wrap items-center justify-center gap-4 text-sm font-medium">
          <Link
            href={GITHUB_RELEASE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3.5 rounded-xl bg-[#22C55E] text-black font-semibold hover:bg-[#1eb054] transition flex items-center gap-2 shadow-lg shadow-[#22C55E]/25"
          >
            <Download className="w-4 h-4" />
            <span>Get Latest Release</span>
          </Link>
          <button
            type="button"
            onClick={onNavigateToDemo}
            className="px-6 py-3.5 rounded-xl bg-[#141414] border border-[#262626] text-white hover:bg-[#1c1c1c] transition flex items-center gap-2 cursor-pointer"
          >
            <Smartphone className="w-4 h-4 text-[#22C55E]" />
            <span>Try Live App Mockup</span>
          </button>
          <Link
            href={GITHUB_REPO_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3.5 rounded-xl bg-[#141414] border border-[#262626] text-[#8A8A8A] hover:text-white hover:bg-[#1c1c1c] transition flex items-center gap-2"
          >
            <GithubIcon className="w-4 h-4" />
            <span>Source Code</span>
          </Link>
        </div>

        {/* Quick Metrics Bar */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-16 w-full">
          <div className="p-5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/80 text-left flex flex-col justify-between">
            <div className="flex items-center justify-between text-[#8A8A8A] mb-2">
              <span className="text-xs uppercase tracking-wider font-semibold">
                Account
              </span>
              <WifiOff className="w-4 h-4 text-[#22C55E]" />
            </div>
            <div>
              <div className="text-2xl font-bold text-white mb-0.5">None</div>
              <div className="text-xs text-[#8A8A8A]">
                No Sign-Up Or Cloud Sync
              </div>
            </div>
          </div>

          <div className="p-5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/80 text-left flex flex-col justify-between">
            <div className="flex items-center justify-between text-[#8A8A8A] mb-2">
              <span className="text-xs uppercase tracking-wider font-semibold">
                Telemetry
              </span>
              <ShieldCheck className="w-4 h-4 text-[#22C55E]" />
            </div>
            <div>
              <div className="text-2xl font-bold text-[#22C55E] mb-0.5">
                0 KB
              </div>
              <div className="text-xs text-[#8A8A8A]">
                Habit Data Sent To Us
              </div>
            </div>
          </div>

          <div className="p-5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/80 text-left flex flex-col justify-between">
            <div className="flex items-center justify-between text-[#8A8A8A] mb-2">
              <span className="text-xs uppercase tracking-wider font-semibold">
                Recurrence
              </span>
              <Clock className="w-4 h-4 text-[#FF8A00]" />
            </div>
            <div>
              <div className="text-2xl font-bold text-[#FF8A00] mb-0.5">
                6 Units
              </div>
              <div className="text-xs text-[#8A8A8A]">
                Minutes, Hours, Days, Months, Years
              </div>
            </div>
          </div>

          <div className="p-5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/80 text-left flex flex-col justify-between">
            <div className="flex items-center justify-between text-[#8A8A8A] mb-2">
              <span className="text-xs uppercase tracking-wider font-semibold">
                Storage
              </span>
              <Database className="w-4 h-4 text-white" />
            </div>
            <div>
              <div className="text-2xl font-bold text-white mb-0.5">SQLite</div>
              <div className="text-xs text-[#8A8A8A]">
                Direct SQL Export & Import
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

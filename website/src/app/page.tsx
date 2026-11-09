"use client";

import React, { useState, useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { Download } from "lucide-react";
import { GithubIcon } from "./components/utils/GithubIcon";
import { HeroSection } from "./components/HeroSection";
import { DemoSection, MockHabit } from "./components/DemoSection";
import { FeaturesSection } from "./components/FeaturesSection";
import { AboutSection } from "./components/AboutSection";

const GITHUB_RELEASE_URL = "https://github.com/itsmeprinceyt/habitme/releases";

export default function Home() {
  const demoRef = useRef<HTMLDivElement>(null);
  const featuresRef = useRef<HTMLDivElement>(null);
  const aboutRef = useRef<HTMLDivElement>(null);

  const scrollTo = (ref: React.RefObject<HTMLDivElement | null>) => {
    if (ref.current) {
      ref.current.scrollIntoView({ behavior: "smooth" });
    }
  };

  // Interactive habits inside the phone mockup demo
  const [habits, setHabits] = useState<MockHabit[]>([
    {
      id: "1",
      name: "Morning Meditation & Breathing",
      type: "recurring",
      recurrenceLabel: "Every 1 day • 07:00 AM",
      isDone: false,
      dueText: "Due today 7:00 AM",
    },
    {
      id: "2",
      name: "Drink 2.5L Water",
      type: "recurring",
      recurrenceLabel: "Every 2 hours",
      isDone: false,
      dueText: "Next interval at 3:00 PM",
    },
    {
      id: "3",
      name: "Review Monthly Finances",
      type: "one-time",
      recurrenceLabel: "One-time habit",
      isDone: false,
      dueText: "Scheduled for Nov 10",
    },
    {
      id: "4",
      name: "30 Min Strength Training",
      type: "recurring",
      recurrenceLabel: "Every 1 day",
      isDone: true,
      dueText: "Resets in 3h 56m",
    },
  ]);

  // Handle toggling habit completion in interactive mockup
  const toggleHabit = (id: string) => {
    setHabits((prev) =>
      prev.map((h) => {
        if (h.id === id) {
          const nextDone = !h.isDone;
          return {
            ...h,
            isDone: nextDone,
            dueText: nextDone ? "Resets in 23h 59m" : "Due today",
          };
        }
        return h;
      }),
    );
  };

  return (
    <div className="min-h-screen bg-black text-white selection:bg-[#22C55E]/20 flex flex-col">
      {/* Background radial glow */}
      <div className="fixed inset-0 pointer-events-none bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(34,197,94,0.12),rgba(255,255,255,0))]" />

      {/* Top Navbar */}
      <header className="sticky top-0 z-40 backdrop-blur-md bg-black/80 border-b border-[#262626]/80 px-6 sm:px-10">
        <div className="max-w-7xl mx-auto py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="relative w-9 h-9 rounded-md overflow-hidden border border-[#262626] bg-[#141414] p-1 flex items-center justify-center shadow-lg shadow-black/50">
              <Image
                src="/habitme_logo_svg.svg"
                alt="HabitMe Logo"
                width={32}
                height={32}
                className="object-contain rounded-sm"
                priority
              />
            </div>
            <div>
              <span className="font-bold text-lg tracking-tight flex items-center gap-2">
                HabitMe
                <span className="text-[10px] font-semibold uppercase tracking-wider bg-[#22C55E]/15 text-[#22C55E] px-2 py-0.5 rounded-full border border-[#22C55E]/30">
                  Your Day. Your Habits.
                </span>
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm text-[#8A8A8A]">
            <Link
              href="#features"
              onClick={(e) => {
                e.preventDefault();
                scrollTo(featuresRef);
              }}
              className="hover:text-white transition-colors"
            >
              Features
            </Link>
            <Link
              href="#demo"
              onClick={(e) => {
                e.preventDefault();
                scrollTo(demoRef);
              }}
              className="hover:text-white transition-colors"
            >
              Interactive UI
            </Link>
            <Link
              href="#about"
              onClick={(e) => {
                e.preventDefault();
                scrollTo(aboutRef);
              }}
              className="hover:text-white transition-colors"
            >
              Download
            </Link>
          </nav>

          <div className="flex items-center gap-3">
            <Link
              href="https://www.itsmeprince.com"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex text-xs text-[#8A8A8A] hover:text-white transition-colors"
            >
              Made by{" "}
              <span className="text-white ml-1 font-medium">ItsMe Prince</span>
            </Link>
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

      {/* Main Content */}
      <main className="flex-1 relative z-10">
        {/* HERO SECTION */}
        <HeroSection
          githubReleaseUrl={GITHUB_RELEASE_URL}
          onNavigateToDemo={() => scrollTo(demoRef)}
        />

        {/* INTERACTIVE FLUTTER APP MOCKUP SECTION */}
        <div ref={demoRef}>
          <DemoSection habits={habits} onToggleHabit={toggleHabit} />
        </div>

        {/* CORE APP FEATURES GRID */}
        <div ref={featuresRef}>
          <FeaturesSection />
        </div>

        {/* CALL TO ACTION / DEVELOPER SECTION */}
        <div ref={aboutRef}>
          <AboutSection githubReleaseUrl={GITHUB_RELEASE_URL} />
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#262626] py-10 px-6 sm:px-10 text-xs text-[#8A8A8A]">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span>© 2026 HabitMe.</span>
            <span>All rights reserved.</span>
          </div>

          <div className="flex items-center gap-6">
            <Link
              href="https://www.itsmeprince.com"
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
            <Link
              href="#features"
              onClick={(e) => {
                e.preventDefault();
                scrollTo(featuresRef);
              }}
              className="hover:text-white transition-colors"
            >
              Features
            </Link>
            <Link
              href="#demo"
              onClick={(e) => {
                e.preventDefault();
                scrollTo(demoRef);
              }}
              className="hover:text-white transition-colors"
            >
              App UI Demo
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

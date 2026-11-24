"use client";

import React, { useState, useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { Download } from "lucide-react";
import { GithubIcon } from "./components/utils/GithubIcon";
import { HeroSection } from "./components/HeroSection";
import { DemoSection, MockHabit, NewHabitInput } from "./components/DemoSection";
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

  // Interactive habits inside the phone mockup demo, mirroring the Flutter app
  const [habits, setHabits] = useState<MockHabit[]>([
    {
      id: "1",
      name: "Morning Meditation & Breathing",
      type: "recurring",
      recurrenceLabel: "Every 1 day",
      isDone: false,
      labelId: "mind",
      notify: true,
      dueAt: "2026-11-24T07:00:00",
      dueLabel: "Tue, 24 Nov 2026 · 07:00 AM",
      days: [2, 3, 5, 8, 12, 15, 20, 24, 27, 29],
    },
    {
      id: "2",
      name: "Drink 2.5L Water",
      type: "recurring",
      recurrenceLabel: "Every 2 hours",
      isDone: false,
      labelId: "health",
      notify: true,
      dueAt: "2026-11-24T15:00:00",
      dueLabel: "Tue, 24 Nov 2026 · 03:00 PM",
      days: [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26],
    },
    {
      id: "3",
      name: "Review Monthly Finances",
      type: "one-time",
      recurrenceLabel: "One-time habit",
      isDone: false,
      labelId: "work",
      notify: false,
      dueAt: "2026-11-26T18:00:00",
      dueLabel: "Thu, 26 Nov 2026 · 06:00 PM",
      days: [26],
    },
    {
      id: "4",
      name: "Read 20 Pages",
      type: "recurring",
      recurrenceLabel: "Every 1 day",
      isDone: false,
      labelId: "mind",
      notify: true,
      dueAt: "2026-11-24T21:30:00",
      dueLabel: "Tue, 24 Nov 2026 · 09:30 PM",
      days: [1, 2, 4, 5, 6, 7, 9, 10, 11, 13, 14, 16, 17, 18, 20, 21, 23, 24, 25, 27, 28, 30],
    },
    {
      id: "5",
      name: "30 Min Strength Training",
      type: "recurring",
      recurrenceLabel: "Every 2 days",
      isDone: true,
      labelId: "health",
      notify: true,
      dueAt: "2026-11-25T06:30:00",
      dueLabel: "Wed, 25 Nov 2026 · 06:30 AM",
      days: [2, 4, 7, 9, 11, 14, 16, 18, 21, 23],
    },
    {
      id: "6",
      name: "Submit Project Proposal",
      type: "one-time",
      recurrenceLabel: "One-time habit",
      isDone: true,
      labelId: "work",
      notify: false,
      completedLabel: "Mon, 23 Nov 2026 · 04:12 PM",
      days: [19],
    },
  ]);

  // Completing a recurring habit rolls it to its next occurrence, as the app does
  const nextOccurrence = (habit: MockHabit) => {
    const base = habit.dueAt ? new Date(habit.dueAt) : new Date(2026, 10, 24, 8, 0);
    base.setDate(base.getDate() + 1);
    const pad = (value: number) => String(value).padStart(2, "0");
    const hours = base.getHours();
    const suffix = hours >= 12 ? "PM" : "AM";
    const displayHour = hours % 12 === 0 ? 12 : hours % 12;
    return {
      dueAt: `${base.getFullYear()}-${pad(base.getMonth() + 1)}-${pad(
        base.getDate(),
      )}T${pad(hours)}:${pad(base.getMinutes())}:00`,
      dueLabel: `${new Intl.DateTimeFormat("en-GB", {
        weekday: "short",
        day: "numeric",
        month: "short",
        year: "numeric",
      }).format(base)} · ${pad(displayHour)}:${pad(base.getMinutes())} ${suffix}`,
    };
  };

  // Handle toggling habit completion in interactive mockup
  const toggleHabit = (id: string) => {
    setHabits((prev) =>
      prev.map((h) => {
        if (h.id !== id) return h;
        const isDone = !h.isDone;
        if (isDone && h.type === "recurring") {
          return { ...h, isDone, ...nextOccurrence(h) };
        }
        return { ...h, isDone };
      }),
    );
  };

  const addHabit = (input: NewHabitInput) => {
    setHabits((prev) => [
      {
        id: `custom-${Date.now()}`,
        ...input,
        isDone: false,
        dueAt: "2026-11-24T20:00:00",
        dueLabel: "Tue, 24 Nov 2026 · 08:00 PM",
        days: [24, 25, 26, 27, 28, 29, 30],
      },
      ...prev,
    ]);
  };

  const updateHabit = (id: string, input: NewHabitInput) => {
    setHabits((prev) =>
      prev.map((h) => (h.id === id ? { ...h, ...input } : h)),
    );
  };

  const deleteHabit = (id: string) => {
    setHabits((prev) => prev.filter((h) => h.id !== id));
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
          <DemoSection
            habits={habits}
            onToggleHabit={toggleHabit}
            onAddHabit={addHabit}
            onUpdateHabit={updateHabit}
            onDeleteHabit={deleteHabit}
          />
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

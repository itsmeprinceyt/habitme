"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";
import Link from "next/link";
import { Download, Menu as MenuIcon, X } from "lucide-react";
import { HeroSection } from "./components/HeroSection";
import { DemoSection, MockHabit, NewHabitInput } from "./components/DemoSection";
import { FeaturesSection } from "./components/FeaturesSection";
import { AboutSection } from "./components/AboutSection";
import { SiteFooter } from "./components/SiteFooter";
import { SiteMotion } from "./components/SiteMotion";
import { smoothScrollToElement } from "../utils/scroll.util";
import { registerSection } from "../utils/section.util";
import { GITHUB_RELEASE_URL, MADE_BY_URL } from "../utils/main.util";

export default function Home() {
  const demoRef = useRef<HTMLDivElement>(null);
  const featuresRef = useRef<HTMLDivElement>(null);
  const aboutRef = useRef<HTMLDivElement>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const scrollTo = (ref: React.RefObject<HTMLDivElement | null>) => {
    smoothScrollToElement(ref.current);
  };

  // Escape closes the mobile menu, and growing past the breakpoint clears it
  // so the desktop nav never starts hidden behind a stale open state.
  // Sections are registered by ref so the navbar, footer and legal header can
  // glide to them without ever putting a #hash in the URL.
  useEffect(() => {
    registerSection("features", featuresRef.current);
    registerSection("demo", demoRef.current);
    registerSection("about", aboutRef.current);
    return () => {
      registerSection("features", null);
      registerSection("demo", null);
      registerSection("about", null);
    };
  }, []);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setMobileMenuOpen(false);
    };
    const desktop = window.matchMedia("(min-width: 768px)");
    const onChange = () => {
      if (desktop.matches) setMobileMenuOpen(false);
    };

    window.addEventListener("keydown", onKeyDown);
    desktop.addEventListener("change", onChange);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
      desktop.removeEventListener("change", onChange);
    };
  }, []);

  // Interactive habits inside the phone mockup demo, mirroring the Flutter app
  const [habits, setHabits] = useState<MockHabit[]>([
    {
      id: "1",
      name: "Morning Meditation & Breathing",
      type: "recurring",
      recurrenceLabel: "Every day",
      isDone: false,
      labelId: "mind",
      notify: true,
      description: "Five minutes of quiet before the day starts.",
      recurInterval: 1,
      recurUnit: "days",
      repeatCount: null,
      remainingCount: null,
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
      recurInterval: 2,
      recurUnit: "hours",
      repeatCount: null,
      remainingCount: null,
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
      recurInterval: 1,
      recurUnit: "days",
      repeatCount: null,
      remainingCount: null,
      dueAt: "2026-11-26T18:00:00",
      dueLabel: "Thu, 26 Nov 2026 · 06:00 PM",
      days: [26],
    },
    {
      id: "4",
      name: "Read 20 Pages",
      type: "recurring",
      recurrenceLabel: "Every day",
      isDone: false,
      labelId: "mind",
      notify: true,
      recurInterval: 1,
      recurUnit: "days",
      repeatCount: 30,
      remainingCount: 24,
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
      recurInterval: 2,
      recurUnit: "days",
      repeatCount: 12,
      remainingCount: 8,
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
      recurInterval: 1,
      recurUnit: "days",
      repeatCount: null,
      remainingCount: null,
      completedLabel: "Mon, 23 Nov 2026 · 04:12 PM",
      days: [19],
    },
  ]);

  // Completing a recurring habit rolls it to its next occurrence, as the app does
  const nextOccurrence = (habit: MockHabit) => {
    const base = habit.dueAt ? new Date(habit.dueAt) : new Date(2026, 10, 24, 8, 0);
    const step = habit.recurInterval ?? 1;
    if (habit.recurUnit === "hours") base.setHours(base.getHours() + step);
    else if (habit.recurUnit === "months") base.setMonth(base.getMonth() + step);
    else base.setDate(base.getDate() + step);
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
          // A limited series stops rolling once its last occurrence is done.
          const remaining =
            h.repeatCount == null
              ? null
              : Math.max(0, (h.remainingCount ?? h.repeatCount) - 1);
          if (remaining === 0) return { ...h, isDone, remainingCount: 0 };
          return { ...h, isDone, remainingCount: remaining, ...nextOccurrence(h) };
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
        remainingCount: input.repeatCount,
        dueAt: "2026-11-24T20:00:00",
        dueLabel: "Tue, 24 Nov 2026 · 08:00 PM",
        days: [24, 25, 26, 27, 28, 29, 30],
      },
      ...prev,
    ]);
  };

  const updateHabit = (id: string, input: NewHabitInput) => {
    setHabits((prev) =>
      prev.map((h) => {
        if (h.id !== id) return h;
        const remainingCount =
          input.repeatCount == null
            ? null
            : Math.min(input.repeatCount, h.remainingCount ?? input.repeatCount);
        return { ...h, ...input, remainingCount };
      }),
    );
  };

  const deleteHabit = (id: string) => {
    setHabits((prev) => prev.filter((h) => h.id !== id));
  };

  return (
    <div className="min-h-screen bg-black text-white selection:bg-[#22C55E]/20 flex flex-col">
      {/* Background radial glow */}
      <div
        data-anim="glow"
        className="fixed inset-0 pointer-events-none bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(34,197,94,0.12),rgba(255,255,255,0))]"
      />

      {/* Top Navbar */}
      <header className="sticky top-0 z-40 backdrop-blur-md bg-black/80 border-b border-[#262626]/80 px-4 sm:px-10">
        <div className="max-w-7xl mx-auto py-3 sm:py-4 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="relative w-8 h-8 sm:w-9 sm:h-9 shrink-0 rounded-md overflow-hidden border border-[#262626] bg-[#141414] p-1 flex items-center justify-center shadow-lg shadow-black/50">
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
              <span className="font-bold text-base sm:text-lg tracking-tight flex items-center gap-2">
                HabitMe
                <span className="hidden sm:inline text-[10px] font-semibold uppercase tracking-wider bg-[#22C55E]/15 text-[#22C55E] px-2 py-0.5 rounded-full border border-[#22C55E]/30">
                  Keep the habit alive.
                </span>
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm text-[#8A8A8A]">
            <button
              type="button"
              onClick={() => scrollTo(featuresRef)}
              className="hover:text-white transition-colors"
            >
              Features
            </button>
            <button
              type="button"
              onClick={() => scrollTo(demoRef)}
              className="hover:text-white transition-colors"
            >
              Interactive UI
            </button>
            <button
              type="button"
              onClick={() => scrollTo(aboutRef)}
              className="hover:text-white transition-colors"
            >
              Download
            </button>
          </nav>

          <div className="flex items-center gap-2 sm:gap-3">
            <Link
              href={MADE_BY_URL}
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
              aria-label="Download the latest HabitMe APK"
              className="inline-flex items-center justify-center gap-2 px-3 sm:px-4 py-2 rounded-xl text-xs font-semibold bg-[#22C55E] text-black hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20"
            >
              <Download className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Download APK</span>
            </Link>
            <button
              type="button"
              onClick={() => setMobileMenuOpen((open) => !open)}
              aria-expanded={mobileMenuOpen}
              aria-controls="mobile-nav"
              aria-label={mobileMenuOpen ? "Close menu" : "Open menu"}
              className="md:hidden inline-flex h-9 w-9 items-center justify-center rounded-xl border border-[#262626] bg-[#141414] text-white transition hover:bg-[#1c1c1c]"
            >
              {mobileMenuOpen ? (
                <X className="w-4 h-4" />
              ) : (
                <MenuIcon className="w-4 h-4" />
              )}
            </button>
          </div>
        </div>

        {/* Mobile navigation: same smooth glide as the desktop nav */}
        <div
          id="mobile-nav"
          className={`md:hidden absolute inset-x-0 top-full overflow-hidden border-b border-[#262626]/80 bg-black/95 shadow-lg shadow-black/40 backdrop-blur-md transition-[max-height,opacity] duration-300 ease-out ${
            mobileMenuOpen
              ? "max-h-80 opacity-100"
              : "pointer-events-none max-h-0 opacity-0"
          }`}
        >
          <nav className="flex flex-col gap-1 px-2 py-2 text-sm text-[#8A8A8A]">
            <button
              type="button"
              onClick={() => {
                setMobileMenuOpen(false);
                scrollTo(featuresRef);
              }}
              className="rounded-xl px-3 py-3 text-left hover:bg-[#141414] hover:text-white transition-colors"
            >
              Features
            </button>
            <button
              type="button"
              onClick={() => {
                setMobileMenuOpen(false);
                scrollTo(demoRef);
              }}
              className="rounded-xl px-3 py-3 text-left hover:bg-[#141414] hover:text-white transition-colors"
            >
              Interactive UI
            </button>
            <button
              type="button"
              onClick={() => {
                setMobileMenuOpen(false);
                scrollTo(aboutRef);
              }}
              className="rounded-xl px-3 py-3 text-left hover:bg-[#141414] hover:text-white transition-colors"
            >
              Download
            </button>
            <Link
              href={MADE_BY_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-xl px-3 py-3 hover:bg-[#141414] hover:text-white transition-colors sm:hidden"
            >
              Made by ItsMe Prince
            </Link>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 relative z-10">
        {/* HERO SECTION */}
        <HeroSection onNavigateToDemo={() => scrollTo(demoRef)} />

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
          <AboutSection />
        </div>
      </main>

      {/* Footer */}
      <SiteFooter />

      {/* GSAP runs inside the page tree, after the content it animates, so it
          only touches inline styles once hydration has finished. */}
      <SiteMotion />
    </div>
  );
}

"use client";

import React, { useState } from "react";
import Image from "next/image";
import {
  Menu,
  X,
  Calendar as CalendarIcon,
  List as ListIcon,
  Plus,
  Check,
  ChevronDown,
  Download,
  Upload,
  ExternalLink,
  ShieldCheck,
  Zap,
  Database,
  Smartphone,
  Bell,
  Clock,
  Sparkles,
  WifiOff,
  Code2,
} from "lucide-react";

function GithubIcon({ className = "w-4 h-4" }: { className?: string }) {
  return (
    <svg className={className} fill="currentColor" viewBox="0 0 24 24">
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"
      />
    </svg>
  );
}

interface MockHabit {
  id: string;
  name: string;
  type: "recurring" | "one-time";
  recurrenceLabel?: string;
  isDone: boolean;
  dueText?: string;
}

const GITHUB_RELEASE_URL = "https://github.com/itsmeprinceyt/habitme/releases";

export default function Home() {
  const [activeTab, setActiveTab] = useState<"list" | "calendar">("list");
  const [selectedDay, setSelectedDay] = useState<number>(5);
  const [isFormOpen, setIsFormOpen] = useState<boolean>(false);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);

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

  const activeHabits = habits.filter((h) => !h.isDone);
  const completedHabits = habits.filter((h) => h.isDone);

  return (
    <div className="min-h-screen bg-black text-white selection:bg-[#22C55E]/20 flex flex-col">
      {/* Background radial glow */}
      <div className="fixed inset-0 pointer-events-none bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(34,197,94,0.12),rgba(255,255,255,0))]" />

      {/* Top Navbar */}
      <header className="sticky top-0 z-40 backdrop-blur-md bg-black/80 border-b border-[#262626]/80 px-6 sm:px-10">
        <div className="max-w-7xl mx-auto py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="relative w-9 h-9 rounded-xl overflow-hidden border border-[#262626] bg-[#141414] p-1 flex items-center justify-center shadow-lg shadow-black/50">
              <Image
                src="/habitme_logo_rounded.png"
                alt="HabitMe Logo"
                width={32}
                height={32}
                className="object-contain"
                priority
              />
            </div>
            <div>
              <span className="font-bold text-lg tracking-tight flex items-center gap-2">
                HabitMe
                <span className="text-[10px] font-semibold uppercase tracking-wider bg-[#22C55E]/15 text-[#22C55E] px-2 py-0.5 rounded-full border border-[#22C55E]/30">
                  v1.0 Preview
                </span>
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm text-[#8A8A8A]">
            <a href="#features" className="hover:text-white transition-colors">
              Features
            </a>
            <a href="#demo" className="hover:text-white transition-colors">
              Interactive UI
            </a>
            <a
              href="#architecture"
              className="hover:text-white transition-colors"
            >
              Offline First
            </a>
            <a href="#about" className="hover:text-white transition-colors">
              Developer
            </a>
          </nav>

          <div className="flex items-center gap-3">
            <a
              href="https://www.itsmeprince.com"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex text-xs text-[#8A8A8A] hover:text-white transition-colors"
            >
              Made by{" "}
              <span className="text-white ml-1 font-medium">ItsMe Prince</span>
            </a>
            <a
              href={GITHUB_RELEASE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold bg-[#22C55E] text-black hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download APK</span>
            </a>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 relative z-10">
        {/* HERO SECTION */}
        <section className="pt-16 sm:pt-24 pb-16 px-6 sm:px-10">
          <div className="max-w-7xl mx-auto text-center flex flex-col items-center">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full border border-[#262626] bg-[#0D0D0D] text-xs text-[#8A8A8A] mb-8 shadow-inner">
              <span className="w-2 h-2 rounded-full bg-[#22C55E] animate-pulse"></span>
              <span className="flex items-center gap-1.5">
                <WifiOff className="w-3.5 h-3.5 text-[#22C55E]" />
                100% Offline • Zero Tracking • Instant Performance
              </span>
            </div>

            <h1 className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight max-w-4xl leading-[1.1] mb-6">
              Your day. <br className="hidden sm:inline" />
              <span className="bg-gradient-to-r from-white via-zinc-200 to-[#8A8A8A] bg-clip-text text-transparent">
                Your habits.
              </span>
            </h1>

            <p className="text-base sm:text-xl text-[#8A8A8A] max-w-2xl font-normal leading-relaxed mb-10">
              A minimalist habit tracker built with zero internet permissions.
              Engineered with a high-contrast dark palette, flexible recurring
              cycles, exact local alarm notifications, and full SQL data
              sovereignty.
            </p>

            <div className="flex flex-wrap items-center justify-center gap-4 text-sm font-medium">
              <a
                href={GITHUB_RELEASE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="px-6 py-3.5 rounded-xl bg-[#22C55E] text-black font-semibold hover:bg-[#1eb054] transition flex items-center gap-2 shadow-lg shadow-[#22C55E]/25"
              >
                <Download className="w-4 h-4" />
                <span>Get Latest Release</span>
              </a>
              <a
                href="#demo"
                className="px-6 py-3.5 rounded-xl bg-[#141414] border border-[#262626] text-white hover:bg-[#1c1c1c] transition flex items-center gap-2"
              >
                <Smartphone className="w-4 h-4 text-[#22C55E]" />
                <span>Try Live App Mockup</span>
              </a>
              <a
                href="https://github.com/itsmeprinceyt/habitme"
                target="_blank"
                rel="noopener noreferrer"
                className="px-6 py-3.5 rounded-xl bg-[#141414] border border-[#262626] text-[#8A8A8A] hover:text-white hover:bg-[#1c1c1c] transition flex items-center gap-2"
              >
                <GithubIcon className="w-4 h-4" />
                <span>Source Code</span>
              </a>
            </div>

            {/* Quick Metrics Bar */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-16 w-full">
              <div className="p-5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/80 text-left flex flex-col justify-between">
                <div className="flex items-center justify-between text-[#8A8A8A] mb-2">
                  <span className="text-xs uppercase tracking-wider font-semibold">
                    Mode
                  </span>
                  <WifiOff className="w-4 h-4 text-[#22C55E]" />
                </div>
                <div>
                  <div className="text-2xl font-bold text-white mb-0.5">
                    100%
                  </div>
                  <div className="text-xs text-[#8A8A8A]">
                    Local & Offline Only
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
                    Data Leaves Your Device
                  </div>
                </div>
              </div>

              <div className="p-5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/80 text-left flex flex-col justify-between">
                <div className="flex items-center justify-between text-[#8A8A8A] mb-2">
                  <span className="text-xs uppercase tracking-wider font-semibold">
                    Intervals
                  </span>
                  <Clock className="w-4 h-4 text-[#FF8A00]" />
                </div>
                <div>
                  <div className="text-2xl font-bold text-[#FF8A00] mb-0.5">
                    6 Units
                  </div>
                  <div className="text-xs text-[#8A8A8A]">
                    Minutes, Hours, Days, etc.
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
                  <div className="text-2xl font-bold text-white mb-0.5">
                    SQLite
                  </div>
                  <div className="text-xs text-[#8A8A8A]">
                    Direct SQL Export & Import
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* INTERACTIVE FLUTTER APP MOCKUP SECTION */}
        <section
          id="demo"
          className="py-20 px-6 sm:px-10 border-y border-[#262626] bg-[#0A0A0A]/60"
        >
          <div className="max-w-7xl mx-auto flex flex-col items-center">
            <div className="text-center mb-12">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#141414] border border-[#262626] text-xs text-[#22C55E] font-medium mb-3">
                <Smartphone className="w-3.5 h-3.5" />
                <span>Real App UI Replication</span>
              </div>
              <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
                Experience the Mobile App UI
              </h2>
              <p className="text-sm sm:text-base text-[#8A8A8A] max-w-lg mt-2 mx-auto">
                Built matching the exact design tokens, typography, dark theme
                palette, and layout of the Flutter application. Tap checkmarks
                to toggle habits!
              </p>
              <p className="text-[10px] text-[#8A8A8A] mt-2 italic">
                *Does not represent the final product*
              </p>
            </div>

            {/* Mobile Device Frame */}
            <div className="relative w-full max-w-[380px] rounded-[44px] p-3 bg-gradient-to-b from-[#262626] via-[#141414] to-[#121212] border border-[#333] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.9)]">
              {/* Phone Speaker & Camera Notch */}
              <div className="absolute top-5 left-1/2 -translate-x-1/2 w-28 h-4 bg-black rounded-full z-30 flex items-center justify-center">
                <div className="w-10 h-1 bg-[#262626] rounded-full mr-2"></div>
                <div className="w-2.5 h-2.5 bg-[#141414] rounded-full border border-[#262626]"></div>
              </div>

              {/* Phone Inner Screen */}
              <div className="relative w-full h-[680px] bg-black rounded-[36px] overflow-hidden flex flex-col border border-black select-none text-white font-sans">
                {/* Status Bar */}
                <div className="h-10 pt-2 px-6 flex items-center justify-between text-[11px] text-[#8A8A8A] font-semibold">
                  <span>9:41</span>
                  <div className="flex items-center gap-1.5 text-white">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#22C55E]"></span>
                    <div className="w-4 h-2 border border-white rounded-sm p-0.5 flex items-center">
                      <div className="h-full w-full bg-[#22C55E] rounded-2xs"></div>
                    </div>
                  </div>
                </div>

                {/* Flutter AppBar */}
                <div className="h-14 px-4 flex items-center justify-between border-b border-[#262626]/50 bg-black">
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => setIsDrawerOpen(!isDrawerOpen)}
                      className="p-2 -ml-1 text-white hover:bg-[#141414] rounded-lg transition"
                      title="Menu"
                    >
                      <Menu className="w-5 h-5" />
                    </button>
                    <span className="font-bold text-lg tracking-tight">
                      HabitMe
                    </span>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() =>
                        setActiveTab(activeTab === "list" ? "calendar" : "list")
                      }
                      className="p-2 text-white hover:bg-[#141414] rounded-lg transition"
                      title={
                        activeTab === "list" ? "Show calendar" : "Show list"
                      }
                    >
                      {activeTab === "list" ? (
                        <CalendarIcon className="w-5 h-5 text-white" />
                      ) : (
                        <ListIcon className="w-5 h-5 text-white" />
                      )}
                    </button>
                  </div>
                </div>

                {/* Simulated Drawer Overlay */}
                {isDrawerOpen && (
                  <div className="absolute inset-0 z-40 bg-black/60 flex animate-fade-in">
                    <div className="w-[82%] h-full bg-[#121212] border-r border-[#262626] p-5 flex flex-col justify-between shadow-2xl">
                      <div>
                        <div className="flex items-center justify-between pb-4 border-b border-[#262626]">
                          <div className="flex items-center gap-2.5">
                            <Image
                              src="/habitme_logo_rounded.png"
                              alt="Logo"
                              width={28}
                              height={28}
                              className="rounded-lg"
                            />
                            <span className="font-bold text-base">HabitMe</span>
                          </div>
                          <button
                            onClick={() => setIsDrawerOpen(false)}
                            className="p-1 rounded-lg text-[#8A8A8A] hover:text-white hover:bg-[#262626]"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </div>

                        <div className="mt-6 space-y-2">
                          <div className="text-[11px] font-semibold text-[#8A8A8A] uppercase tracking-wider px-2">
                            Data & Storage
                          </div>
                          <button
                            onClick={() =>
                              alert(
                                "Simulated: Export habits to .sql backup file",
                              )
                            }
                            className="w-full flex items-center gap-3 px-3 py-2.5 text-xs font-medium rounded-xl hover:bg-[#1f1f1f] text-left transition"
                          >
                            <Download className="w-4 h-4 text-[#22C55E]" />
                            <span>Export Backup (SQL)</span>
                          </button>
                          <button
                            onClick={() =>
                              alert("Simulated: Import habits from .sql backup")
                            }
                            className="w-full flex items-center gap-3 px-3 py-2.5 text-xs font-medium rounded-xl hover:bg-[#1f1f1f] text-left transition"
                          >
                            <Upload className="w-4 h-4 text-[#FF8A00]" />
                            <span>Import Backup (SQL)</span>
                          </button>
                        </div>
                      </div>

                      <div className="pt-4 border-t border-[#262626] text-xs text-[#8A8A8A]">
                        <p className="font-medium text-white">HabitMe v1.0.0</p>
                        <p className="mt-1 flex items-center gap-1">
                          Made by{" "}
                          <a
                            href="https://www.itsmeprince.com"
                            target="_blank"
                            rel="noreferrer"
                            className="text-[#22C55E] hover:underline flex items-center gap-0.5"
                          >
                            ItsMe Prince
                            <ExternalLink className="w-2.5 h-2.5 inline" />
                          </a>
                        </p>
                      </div>
                    </div>
                    <div
                      className="flex-1"
                      onClick={() => setIsDrawerOpen(false)}
                    />
                  </div>
                )}

                {/* Screen Content - LIST OR CALENDAR VIEW */}
                <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4">
                  {activeTab === "list" ? (
                    <>
                      {/* Active Habits Section */}
                      <div>
                        <div className="flex items-center justify-between text-xs font-bold text-[#8A8A8A] uppercase tracking-wider mb-2.5 px-1">
                          <span>Active ({activeHabits.length})</span>
                          <span className="text-[10px] text-[#22C55E] font-medium lowercase">
                            tap to complete
                          </span>
                        </div>

                        <div className="space-y-2.5">
                          {activeHabits.map((h) => (
                            <div
                              key={h.id}
                              className="group p-3.5 rounded-2xl bg-[#141414] border border-[#262626] hover:border-[#383838] transition flex items-start gap-3 relative"
                            >
                              {/* Custom Checkbox */}
                              <button
                                onClick={() => toggleHabit(h.id)}
                                className="mt-0.5 w-6 h-6 rounded-lg border-2 border-[#262626] group-hover:border-[#22C55E] flex items-center justify-center transition shrink-0"
                              >
                                <Check className="w-3.5 h-3.5 opacity-0 group-hover:opacity-60 text-[#22C55E]" />
                              </button>

                              <div className="flex-1 min-w-0">
                                <div className="text-sm font-semibold text-white truncate">
                                  {h.name}
                                </div>
                                <div className="text-[11px] text-[#8A8A8A] flex items-center gap-1.5 mt-0.5">
                                  <span
                                    className={`w-1.5 h-1.5 rounded-full ${
                                      h.type === "recurring"
                                        ? "bg-[#22C55E]"
                                        : "bg-[#FF8A00]"
                                    }`}
                                  />
                                  <span>{h.recurrenceLabel}</span>
                                </div>
                                {h.dueText && (
                                  <div className="text-[10px] text-[#8A8A8A]/80 mt-1 font-mono flex items-center gap-1">
                                    <Clock className="w-2.5 h-2.5" />
                                    {h.dueText}
                                  </div>
                                )}
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>

                      {/* Completed Habits Section */}
                      {completedHabits.length > 0 && (
                        <div className="pt-2">
                          <div className="flex items-center justify-between text-xs font-bold text-[#8A8A8A] uppercase tracking-wider mb-2.5 px-1">
                            <span>Completed ({completedHabits.length})</span>
                            <span className="text-[10px] text-[#FF8A00] font-medium lowercase">
                              recurring resets live
                            </span>
                          </div>

                          <div className="space-y-2.5">
                            {completedHabits.map((h) => (
                              <div
                                key={h.id}
                                className="p-3.5 rounded-2xl bg-[#0D0D0D] border border-[#262626]/60 flex items-start gap-3 opacity-80"
                              >
                                <button
                                  onClick={() => toggleHabit(h.id)}
                                  className="mt-0.5 w-6 h-6 rounded-lg bg-[#22C55E] text-black font-bold flex items-center justify-center shrink-0 shadow-sm shadow-[#22C55E]/40"
                                >
                                  <Check className="w-3.5 h-3.5 stroke-[3]" />
                                </button>
                                <div className="flex-1 min-w-0">
                                  <div className="text-sm font-semibold text-zinc-400 line-through truncate">
                                    {h.name}
                                  </div>
                                  <div className="text-[11px] text-[#8A8A8A] mt-0.5">
                                    {h.recurrenceLabel}
                                  </div>
                                  {h.dueText && (
                                    <div className="text-[10px] text-[#FF8A00] font-mono mt-1 flex items-center gap-1.5">
                                      <span className="w-1.5 h-1.5 rounded-full bg-[#FF8A00] animate-ping" />
                                      {h.dueText}
                                    </div>
                                  )}
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </>
                  ) : (
                    /* CALENDAR VIEW */
                    <div className="space-y-4 pt-1">
                      {/* Mini Month Header */}
                      <div className="flex items-center justify-between px-1">
                        <span className="font-bold text-sm">November 2026</span>
                        <div className="text-xs text-[#22C55E] font-medium">
                          Today
                        </div>
                      </div>

                      {/* Calendar Grid */}
                      <div className="bg-[#141414] border border-[#262626] rounded-2xl p-3">
                        <div className="grid grid-cols-7 gap-1 text-center text-[10px] font-semibold text-[#8A8A8A] mb-2">
                          <span>M</span>
                          <span>T</span>
                          <span>W</span>
                          <span>T</span>
                          <span>F</span>
                          <span>S</span>
                          <span>S</span>
                        </div>
                        <div className="grid grid-cols-7 gap-1 text-center text-xs">
                          {[...Array(30)].map((_, i) => {
                            const day = i + 1;
                            const isCurrent = day === selectedDay;
                            const hasCompletions = [
                              2, 3, 5, 8, 12, 15, 20,
                            ].includes(day);

                            return (
                              <button
                                key={day}
                                onClick={() => setSelectedDay(day)}
                                className={`h-8 rounded-lg flex flex-col items-center justify-center relative transition ${
                                  isCurrent
                                    ? "bg-[#22C55E] text-black font-bold"
                                    : "hover:bg-[#262626] text-white"
                                }`}
                              >
                                <span>{day}</span>
                                {hasCompletions && !isCurrent && (
                                  <span className="w-1 h-1 bg-[#22C55E] rounded-full absolute bottom-1"></span>
                                )}
                              </button>
                            );
                          })}
                        </div>
                      </div>

                      {/* Day summary */}
                      <div className="p-3 bg-[#0D0D0D] border border-[#262626] rounded-xl text-xs space-y-1.5">
                        <div className="font-semibold text-white">
                          Day {selectedDay} Schedule
                        </div>
                        <p className="text-[#8A8A8A] text-[11px]">
                          2 habits scheduled on this date. Filter by one-time or
                          recurring to review consistency streaks.
                        </p>
                      </div>
                    </div>
                  )}
                </div>

                {/* FAB (Floating Action Button) */}
                <div className="absolute bottom-5 right-5 z-20">
                  <button
                    onClick={() => setIsFormOpen(true)}
                    className="h-12 px-4 rounded-2xl bg-[#22C55E] text-black font-bold text-xs flex items-center gap-2 shadow-lg shadow-[#22C55E]/40 hover:scale-105 transition"
                  >
                    <Plus className="w-4 h-4 stroke-[3]" />
                    <span>New Habit</span>
                  </button>
                </div>

                {/* Modal Form Preview */}
                {isFormOpen && (
                  <div className="absolute inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-end animate-fade-in">
                    <div className="w-full bg-[#141414] border-t border-[#262626] rounded-t-3xl p-5 space-y-4">
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-sm">Add New Habit</span>
                        <button
                          onClick={() => setIsFormOpen(false)}
                          className="p-1 rounded-lg text-[#8A8A8A] hover:text-white"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>

                      <div className="space-y-3 text-xs">
                        <div>
                          <label className="text-[10px] text-[#8A8A8A] font-medium block mb-1">
                            HABIT NAME
                          </label>
                          <input
                            type="text"
                            placeholder="e.g. Read 20 pages"
                            className="w-full bg-black border border-[#262626] rounded-xl px-3 py-2 text-white placeholder-zinc-600 focus:outline-none focus:border-[#22C55E]"
                            defaultValue="Read 20 pages"
                          />
                        </div>

                        <div>
                          <label className="text-[10px] text-[#8A8A8A] font-medium block mb-1">
                            TYPE
                          </label>
                          <div className="grid grid-cols-2 gap-2">
                            <button className="py-2 rounded-xl bg-[#22C55E]/20 border border-[#22C55E] text-[#22C55E] font-semibold text-center">
                              Recurring
                            </button>
                            <button className="py-2 rounded-xl bg-black border border-[#262626] text-[#8A8A8A] font-semibold text-center">
                              One-time
                            </button>
                          </div>
                        </div>

                        <div className="p-2.5 rounded-xl bg-[#0D0D0D] border border-[#262626] text-[11px] text-[#8A8A8A]">
                          Cycle interval: Every{" "}
                          <span className="text-white font-bold">1</span> day at{" "}
                          <span className="text-[#22C55E] font-bold">
                            08:00 AM
                          </span>
                        </div>

                        <button
                          onClick={() => setIsFormOpen(false)}
                          className="w-full py-2.5 rounded-xl bg-[#22C55E] text-black font-bold text-center mt-2"
                        >
                          Save Habit
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </section>

        {/* CORE APP FEATURES GRID */}
        <section id="features" className="py-24 px-6 sm:px-10">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight mb-4">
                Designed for ruthless discipline.
              </h2>
              <p className="text-base sm:text-lg text-[#8A8A8A] max-w-xl mx-auto">
                Every detail is engineered to help you build habits without
                distractions, accounts, or unnecessary complexities.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Feature 1 */}
              <div className="p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626] hover:border-[#383838] transition flex flex-col justify-between">
                <div>
                  <div className="w-12 h-12 rounded-2xl bg-[#141414] border border-[#262626] flex items-center justify-center mb-6 text-[#22C55E]">
                    <Zap className="w-6 h-6" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">
                    Live Recurrence Resets
                  </h3>
                  <p className="text-sm text-[#8A8A8A] leading-relaxed">
                    Recurring habits automatically transition to completed with
                    a live countdown. Once the cycle finishes, they reset back
                    to active and notify you immediately.
                  </p>
                </div>
                <div className="mt-8 pt-4 border-t border-[#262626] text-xs font-mono text-[#22C55E] flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5" />
                  Lazy scheduler reconciliation
                </div>
              </div>

              {/* Feature 2 */}
              <div className="p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626] hover:border-[#383838] transition flex flex-col justify-between">
                <div>
                  <div className="w-12 h-12 rounded-2xl bg-[#141414] border border-[#262626] flex items-center justify-center mb-6 text-[#FF8A00]">
                    <ShieldCheck className="w-6 h-6" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">
                    Zero Network Permissions
                  </h3>
                  <p className="text-sm text-[#8A8A8A] leading-relaxed">
                    No tracking scripts, no cloud logins, and no internet access
                    declared in the Android manifest. Your personal routines
                    stay strictly on your phone.
                  </p>
                </div>
                <div className="mt-8 pt-4 border-t border-[#262626] text-xs font-mono text-[#FF8A00] flex items-center gap-1.5">
                  <WifiOff className="w-3.5 h-3.5" />
                  100% Privacy by design
                </div>
              </div>

              {/* Feature 3 */}
              <div className="p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626] hover:border-[#383838] transition flex flex-col justify-between">
                <div>
                  <div className="w-12 h-12 rounded-2xl bg-[#141414] border border-[#262626] flex items-center justify-center mb-6 text-white">
                    <Database className="w-6 h-6" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">
                    Native SQL Dump & Restore
                  </h3>
                  <p className="text-sm text-[#8A8A8A] leading-relaxed">
                    Export complete SQLite database dumps anytime. Import or
                    merge your backups across devices without relying on any
                    subscription cloud locker.
                  </p>
                </div>
                <div className="mt-8 pt-4 border-t border-[#262626] text-xs font-mono text-white flex items-center gap-1.5">
                  <Download className="w-3.5 h-3.5" />
                  Full data ownership
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* CALL TO ACTION / DEVELOPER SECTION */}
        <section id="about" className="py-24 px-6 sm:px-10">
          <div className="max-w-7xl mx-auto">
            <div className="p-10 sm:p-16 rounded-3xl bg-gradient-to-b from-[#141414] to-[#0D0D0D] border border-[#262626] relative overflow-hidden text-center flex flex-col items-center">
              <div className="w-16 h-16 rounded-2xl bg-black border border-[#262626] p-2 flex items-center justify-center mb-6 shadow-xl">
                <Image
                  src="/habitme_logo_rounded.png"
                  alt="HabitMe"
                  width={48}
                  height={48}
                  className="rounded-xl"
                />
              </div>

              <h2 className="text-2xl sm:text-4xl font-extrabold tracking-tight mb-4">
                Ready to build distraction-free habits?
              </h2>
              <p className="text-sm sm:text-base text-[#8A8A8A] max-w-xl mb-8">
                Download the latest APK release from GitHub. No account setup,
                zero data collection, and completely open source.
              </p>

              <div className="flex flex-wrap items-center justify-center gap-4">
                <a
                  href={GITHUB_RELEASE_URL}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-6 py-3.5 rounded-xl bg-[#22C55E] text-black font-semibold text-sm hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20 flex items-center gap-2"
                >
                  <Download className="w-4 h-4" />
                  <span>Download Latest Release</span>
                </a>
                <a
                  href="https://www.itsmeprince.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-6 py-3.5 rounded-xl bg-black border border-[#262626] text-white font-semibold text-sm hover:bg-[#1c1c1c] transition flex items-center gap-2"
                >
                  <ExternalLink className="w-4 h-4 text-[#8A8A8A]" />
                  <span>Visit ItsMe Prince</span>
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#262626] py-10 px-6 sm:px-10 text-xs text-[#8A8A8A]">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span>© 2026 HabitMe.</span>
            <span>All rights reserved.</span>
          </div>

          <div className="flex items-center gap-6">
            <a
              href="https://www.itsmeprince.com"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-white transition-colors"
            >
              itsmeprince.com
            </a>
            <a
              href={GITHUB_RELEASE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-white transition-colors flex items-center gap-1"
            >
              <GithubIcon className="w-3.5 h-3.5" />
              <span>GitHub Release</span>
            </a>
            <a href="#features" className="hover:text-white transition-colors">
              Features
            </a>
            <a href="#demo" className="hover:text-white transition-colors">
              App UI Demo
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}

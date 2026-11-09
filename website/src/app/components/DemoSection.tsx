import React from "react";
import Image from "next/image";
import Link from "next/link";
import {
  Menu,
  X,
  Calendar as CalendarIcon,
  List as ListIcon,
  Plus,
  Check,
  Download,
  Upload,
  ExternalLink,
  Smartphone,
  Clock,
} from "lucide-react";

export interface MockHabit {
  id: string;
  name: string;
  type: "recurring" | "one-time";
  recurrenceLabel?: string;
  isDone: boolean;
  dueText?: string;
}

interface DemoSectionProps {
  habits: MockHabit[];
  onToggleHabit: (id: string) => void;
}

export function DemoSection({ habits, onToggleHabit }: DemoSectionProps) {
  const [activeTab, setActiveTab] = React.useState<"list" | "calendar">("list");
  const [selectedDay, setSelectedDay] = React.useState<number>(5);
  const [isFormOpen, setIsFormOpen] = React.useState<boolean>(false);
  const [isDrawerOpen, setIsDrawerOpen] = React.useState<boolean>(false);

  const activeHabits = habits.filter((h) => !h.isDone);
  const completedHabits = habits.filter((h) => h.isDone);

  return (
    <section
      id="demo"
      className="py-20 px-6 sm:px-10 border-y border-[#262626] bg-[#0A0A0A]/60"
    >
      <div className="max-w-7xl mx-auto flex flex-col items-center">
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#141414] border border-[#262626] text-xs text-[#22C55E] font-medium mb-3">
            <Smartphone className="w-3.5 h-3.5" />
            <span>App Functionality Sample</span>
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
            <div className="w-10 h-1 bg-[#262626] rounded-full mr-2" />
            <div className="w-2.5 h-2.5 bg-[#141414] rounded-full border border-[#262626]" />
          </div>

          {/* Phone Inner Screen */}
          <div className="relative w-full h-[680px] bg-black rounded-[36px] overflow-hidden flex flex-col border border-black select-none text-white font-sans">
            {/* Status Bar */}
            <div className="h-10 pt-2 px-6 flex items-center justify-between text-[11px] text-[#8A8A8A] font-semibold">
              <span>9:41</span>
              <div className="flex items-center gap-1.5 text-white">
                <span className="w-1.5 h-1.5 rounded-full bg-[#22C55E]" />
                <div className="w-4 h-2 border border-white rounded-sm p-0.5 flex items-center">
                  <div className="h-full w-full bg-[#22C55E] rounded-2xs" />
                </div>
              </div>
            </div>

            {/* Flutter AppBar */}
            <div className="h-14 px-4 flex items-center justify-between border-b border-[#262626]/50 bg-black">
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={() => setIsDrawerOpen(!isDrawerOpen)}
                  className="p-2 -ml-1 text-white hover:bg-[#141414] rounded-lg transition cursor-pointer"
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
                  type="button"
                  onClick={() =>
                    setActiveTab(activeTab === "list" ? "calendar" : "list")
                  }
                  className="p-2 text-white hover:bg-[#141414] rounded-lg transition cursor-pointer"
                  title={activeTab === "list" ? "Show calendar" : "Show list"}
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
                        type="button"
                        onClick={() => setIsDrawerOpen(false)}
                        className="p-1 rounded-lg text-[#8A8A8A] hover:text-white hover:bg-[#262626] cursor-pointer"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>

                    <div className="mt-6 space-y-2">
                      <div className="text-[11px] font-semibold text-[#8A8A8A] uppercase tracking-wider px-2">
                        Data & Storage
                      </div>
                      <button
                        type="button"
                        onClick={() =>
                          alert("Simulated: Export habits to .sql backup file")
                        }
                        className="w-full flex items-center gap-3 px-3 py-2.5 text-xs font-medium rounded-xl hover:bg-[#1f1f1f] text-left transition cursor-pointer"
                      >
                        <Download className="w-4 h-4 text-[#22C55E]" />
                        <span>Export Backup (SQL)</span>
                      </button>
                      <button
                        type="button"
                        onClick={() =>
                          alert("Simulated: Import habits from .sql backup")
                        }
                        className="w-full flex items-center gap-3 px-3 py-2.5 text-xs font-medium rounded-xl hover:bg-[#1f1f1f] text-left transition cursor-pointer"
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
                      <Link
                        href="https://www.itsmeprince.com"
                        target="_blank"
                        rel="noreferrer"
                        className="text-[#22C55E] hover:underline flex items-center gap-0.5"
                      >
                        ItsMe Prince
                        <ExternalLink className="w-2.5 h-2.5 inline" />
                      </Link>
                    </p>
                  </div>
                </div>
                <div
                  className="flex-1 cursor-pointer"
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
                            type="button"
                            onClick={() => onToggleHabit(h.id)}
                            className="mt-0.5 w-6 h-6 rounded-lg border-2 border-[#262626] group-hover:border-[#22C55E] flex items-center justify-center transition shrink-0 cursor-pointer"
                          >
                            <Check className="w-3.5 h-3.5 opacity-0 group-hover:opacity-60 text-[#22C55E]" />
                          </button>

                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-semibold text-white truncate">
                              {h.name}
                            </div>
                            <div className="text-[11px] text-[#8A8A8A] flex items-center gap-1.5 mt-0.5">
                              <span
                                className={`w-1.5 h-1.5 rounded-full ${h.type === "recurring"
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
                              type="button"
                              onClick={() => onToggleHabit(h.id)}
                              className="mt-0.5 w-6 h-6 rounded-lg bg-[#22C55E] text-black font-bold flex items-center justify-center shrink-0 shadow-sm shadow-[#22C55E]/40 cursor-pointer"
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
                            type="button"
                            key={day}
                            onClick={() => setSelectedDay(day)}
                            className={`h-8 rounded-lg flex flex-col items-center justify-center relative transition cursor-pointer ${isCurrent
                              ? "bg-[#22C55E] text-black font-bold"
                              : "hover:bg-[#262626] text-white"
                              }`}
                          >
                            <span>{day}</span>
                            {hasCompletions && !isCurrent && (
                              <span className="w-1 h-1 bg-[#22C55E] rounded-full absolute bottom-1" />
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
                type="button"
                onClick={() => setIsFormOpen(true)}
                className="h-12 px-4 rounded-2xl bg-[#22C55E] text-black font-bold text-xs flex items-center gap-2 shadow-lg shadow-[#22C55E]/40 hover:scale-105 transition cursor-pointer"
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
                      type="button"
                      onClick={() => setIsFormOpen(false)}
                      className="p-1 rounded-lg text-[#8A8A8A] hover:text-white cursor-pointer"
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
                        <button type="button" className="py-2 rounded-xl bg-[#22C55E]/20 border border-[#22C55E] text-[#22C55E] font-semibold text-center cursor-pointer">
                          Recurring
                        </button>
                        <button type="button" className="py-2 rounded-xl bg-black border border-[#262626] text-[#8A8A8A] font-semibold text-center cursor-pointer">
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
                      type="button"
                      onClick={() => setIsFormOpen(false)}
                      className="w-full py-2.5 rounded-xl bg-[#22C55E] text-black font-bold text-center mt-2 cursor-pointer"
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
  );
}


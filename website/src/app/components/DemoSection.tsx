"use client";
import Image from "next/image";
import Link from "next/link";
import {
  Menu,
  X,
  CalendarDays,
  List,
  Plus,
  Download,
  Upload,
  Smartphone,
  Clock,
  Repeat,
  Flag,
  Pencil,
  Info,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  BookOpen,
  Tags,
  Bug,
  Heart,
  ArrowUpRight,
  CheckCircle2,
  Trash2,
  BellRing,
  BellOff,
  CalendarClock,
  Tag,
} from "lucide-react";
import { GITHUB_RELEASE_URL, MADE_BY_URL } from "../../utils/main.util";
import { useEffect, useState } from "react";

export type HabitType = "recurring" | "one-time";

export interface MockHabit {
  id: string;
  name: string;
  type: HabitType;
  recurrenceLabel: string;
  isDone: boolean;
  labelId: string | null;
  notify: boolean;
  /** Optional note shown inside the expanded tile. */
  description?: string;
  /** Total times a limited recurring series repeats; absent means forever. */
  repeatCount?: number | null;
  /** Occurrences left in a limited series (decrements as you complete it). */
  remainingCount?: number | null;
  recurInterval?: number;
  recurUnit?: "days" | "hours" | "months";
  /** Local ISO timestamp used by the live countdown, e.g. 2026-11-24T07:00:00 */
  dueAt?: string;
  /** Pre-formatted target, mirrors the app's date formatting */
  dueLabel?: string;
  completedLabel?: string;
  /** Day numbers of November 2026 this habit occurs on (calendar heatmap) */
  days?: number[];
}

export interface NewHabitInput {
  name: string;
  type: HabitType;
  labelId: string | null;
  recurrenceLabel: string;
  notify: boolean;
  description?: string;
  repeatCount: number | null;
  recurInterval: number;
  recurUnit: "days" | "hours" | "months";
}

export interface MockLabel {
  id: string;
  name: string;
  color: string;
}

/** The label palette from the app's drawer → Manage Labels sheet. */
export const DEMO_LABELS: MockLabel[] = [
  { id: "health", name: "Health", color: "#2BD673" },
  { id: "mind", name: "Mind", color: "#86B49A" },
  { id: "work", name: "Work", color: "#D9A45B" },
];

const C = {
  black: "#0A0E0B",
  surface: "#141B16",
  surfaceLight: "#1F2922",
  card: "#1A231D",
  border: "#2E3B32",
  borderStrong: "#3E4D42",
  white: "#EDF3EC",
  muted: "#8E9C90",
  faint: "#5F6E63",
  accent: "#2BD673",
  accentDeep: "#16A34A",
  green: "#86B49A",
  orange: "#D9A45B",
  red: "#E0655F",
};

const themeVars = {
  "--hm-black": C.black,
  "--hm-surface": C.surface,
  "--hm-surface-light": C.surfaceLight,
  "--hm-card": C.card,
  "--hm-border": C.border,
  "--hm-border-strong": C.borderStrong,
  "--hm-white": C.white,
  "--hm-muted": C.muted,
  "--hm-faint": C.faint,
  "--hm-accent": C.accent,
  "--hm-accent-deep": C.accentDeep,
  "--hm-green": C.green,
  "--hm-orange": C.orange,
  "--hm-red": C.red,
  fontFamily: 'Roboto, "Helvetica Neue", Arial, Helvetica, sans-serif',
} as React.CSSProperties;

const RAISED_SHADOW =
  "0 5px 14px rgba(0,0,0,0.45), 0 -1px 3px rgba(255,255,255,0.08)";
const RAISED_SHADOW_SMALL =
  "0 3px 8px rgba(0,0,0,0.35), 0 -1px 2px rgba(255,255,255,0.06)";

/* ------------------------------------------------------------------ */
/* Helpers                                                             */
/* ------------------------------------------------------------------ */

function tint(color: string, percent: number) {
  return `color-mix(in srgb, ${color} ${percent}%, ${C.card})`;
}

function hexToRgb(hex: string): [number, number, number] {
  const value = hex.replace("#", "");
  return [
    parseInt(value.slice(0, 2), 16),
    parseInt(value.slice(2, 4), 16),
    parseInt(value.slice(4, 6), 16),
  ];
}

/** Blend an accent over the card colour and report whether the result is light. */
function isLightFill(accent: string, alpha: number) {
  const [ar, ag, ab] = hexToRgb(accent);
  const [br, bg, bb] = hexToRgb(C.card);
  const channels = [ar, ag, ab].map((channel, index) => {
    const base = [br, bg, bb][index];
    return channel * alpha + base * (1 - alpha);
  });
  const [r, g, b] = channels.map((value) => value / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.42;
}

/** Mirrors DurationFormat.formatCountdown: leading zero units are dropped. */
function formatCountdown(target: number, now: number) {
  const diff = target - now;
  const overdue = diff < 0;
  const ms = Math.abs(diff);

  const days = Math.floor(ms / 86_400_000);
  const hours = Math.floor((ms % 86_400_000) / 3_600_000);
  const minutes = Math.floor((ms % 3_600_000) / 60_000);
  const seconds = Math.floor((ms % 60_000) / 1000);

  const parts: string[] = [];
  let started = false;
  for (const [value, suffix] of [
    [days, "d"],
    [hours, "h"],
    [minutes, "m"],
    [seconds, "s"],
  ] as const) {
    if (value > 0) started = true;
    if (started) parts.push(`${value}${suffix}`);
  }

  if (parts.length === 0) return overdue ? "Overdue" : "Due now";
  return overdue ? `Overdue by ${parts.join(" ")}` : parts.join(" ");
}

function useTick(enabled: boolean) {
  const [now, setNow] = useState<number | null>(null);

  useEffect(() => {
    const load = () => {
      if (!enabled) {
        setNow(null);
        return;
      }
      setNow(Date.now());
      const timer = window.setInterval(() => setNow(Date.now()), 1000);
      return () => window.clearInterval(timer);
    };
    load();
  }, [enabled]);

  return now;
}

function labelFor(labels: MockLabel[], id: string | null) {
  if (!id) return null;
  return labels.find((label) => label.id === id) ?? null;
}

/* ------------------------------------------------------------------ */
/* Shared controls                                                     */
/* ------------------------------------------------------------------ */

function AppSwitch({
  value,
  onChange,
  label,
}: {
  value: boolean;
  onChange: () => void;
  label: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={value}
      aria-label={label}
      onClick={(event) => {
        event.stopPropagation();
        onChange();
      }}
      className={`relative h-6.75 w-11.5 shrink-0 rounded-full p-0.75 transition-all duration-300 cursor-pointer ${
        value
          ? "bg-linear-to-br from-[#43D17C] to-[#128A44] shadow-[0_0_12px_-2px_rgba(43,214,115,0.55)]"
          : "bg-(--hm-surface-light) shadow-[0_3px_8px_rgba(0,0,0,0.35)]"
      }`}
    >
      <span
        className={`block h-5.25 w-5.25 rounded-full transition-transform duration-300 ease-out ${
          value
            ? "translate-x-4.75 bg-(--hm-black)"
            : "translate-x-0 bg-(--hm-muted)"
        }`}
        style={{ boxShadow: "0 2px 4px rgba(0,0,0,0.4)" }}
      />
    </button>
  );
}

function SectionHeader({
  title,
  count,
  accent,
  expanded,
  onToggle,
}: {
  title: string;
  count: number;
  accent: string;
  expanded: boolean;
  onToggle: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className="flex w-full items-center gap-2.5 py-2 text-left cursor-pointer"
    >
      <span
        className="h-4 w-1 rounded-full"
        style={{ backgroundColor: accent }}
      />
      <span className="flex flex-1 items-center gap-2.5">
        <span className="text-[13px] font-bold tracking-[1.4px] text-(--hm-white)">
          {title.toUpperCase()}
        </span>
        <span
          className="rounded-[10px] px-2 py-0.5 text-xs font-bold"
          style={{ backgroundColor: `${accent}29`, color: accent }}
        >
          {count}
        </span>
      </span>
      <span
        className="rounded-lg bg-(--hm-surface-light) p-1"
        style={{ boxShadow: RAISED_SHADOW_SMALL }}
      >
        <ChevronDown
          className={`h-4.5 w-4.5 text-(--hm-muted) transition-transform duration-200 ${
            expanded ? "rotate-180" : ""
          }`}
        />
      </span>
    </button>
  );
}

function LabelSubheader({
  label,
  count,
  expanded,
  onToggle,
}: {
  label: MockLabel | null;
  count: number;
  expanded: boolean;
  onToggle: () => void;
}) {
  const color = label?.color ?? C.muted;
  return (
    <button
      type="button"
      onClick={onToggle}
      className="flex w-full items-center gap-2 px-1 py-2 text-left cursor-pointer"
    >
      <span
        className="h-2 w-2 shrink-0 rounded-full"
        style={{ backgroundColor: color }}
      />
      <span
        className={`text-[13px] font-semibold tracking-[0.2px] ${
          label ? "text-(--hm-white)" : "text-(--hm-muted)"
        }`}
      >
        {label?.name ?? "No Label"}
      </span>
      <span
        className="rounded-lg px-1.5 py-px text-[11px] font-bold"
        style={{ backgroundColor: `${color}26`, color }}
      >
        {count}
      </span>
      <span className="flex-1" />
      <ChevronDown
        className={`h-4.25 w-4.25 text-(--hm-muted) transition-transform duration-200 ${
          expanded ? "rotate-180" : ""
        }`}
      />
    </button>
  );
}

/* ------------------------------------------------------------------ */
/* Habit tile                                                          */
/* ------------------------------------------------------------------ */

function HabitTile({
  habit,
  label,
  onToggle,
  onEdit,
}: {
  habit: MockHabit;
  label: MockLabel | null;
  onToggle: () => void;
  onEdit: () => void;
}) {
  const [expanded, setExpanded] = useState(false);
  const now = useTick(expanded);

  const themeColor = label?.color ?? C.accentDeep;
  const done = habit.isDone;
  const strike = done && habit.type === "one-time";
  const target = habit.dueAt ? new Date(habit.dueAt).getTime() : null;
  const countdown =
    now !== null && target !== null ? formatCountdown(target, now) : null;
  const countdownOverdue = countdown?.startsWith("Overdue") ?? false;
  const remaining = habit.remainingCount ?? null;
  const limitPill =
    habit.type === "recurring"
      ? remaining == null
        ? "∞"
        : remaining === 0
          ? "Complete"
          : `${remaining}×`
      : null;

  return (
    <div
      onClick={() => setExpanded((value) => !value)}
      className="cursor-pointer rounded-2xl p-[14px_10px_12px_14px] transition-colors duration-200"
      style={{
        backgroundImage: label
          ? `linear-gradient(90deg, ${tint(themeColor, 16)} 0%, ${tint(
              themeColor,
              16,
            )} 60%, ${tint(themeColor, 6)} 84%, ${C.card} 100%)`
          : undefined,
        backgroundColor: label ? undefined : C.card,
        boxShadow: RAISED_SHADOW,
      }}
    >
      <div className="flex items-center gap-3">
        <span
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[13px]"
          style={{
            backgroundImage: done
              ? `linear-gradient(135deg, ${C.surfaceLight}, ${C.surface})`
              : `linear-gradient(135deg, ${themeColor}4d, ${themeColor}1a)`,
            boxShadow: RAISED_SHADOW_SMALL,
          }}
        >
          {habit.type === "recurring" ? (
            <Repeat
              className="h-5 w-5"
              style={{ color: done ? C.muted : themeColor }}
            />
          ) : (
            <Flag
              className="h-5 w-5"
              style={{ color: done ? C.muted : themeColor }}
            />
          )}
        </span>

        <div className="min-w-0 flex-1">
          <div className="flex min-w-0 items-center gap-1.5">
            <span
              className="truncate text-[16px] font-semibold leading-tight"
              style={{
                color: done ? C.muted : C.white,
                textDecoration: strike ? "line-through" : undefined,
                textDecorationColor: C.muted,
              }}
            >
              {habit.name}
            </span>
            {limitPill && (
              <span
                className="flex shrink-0 items-center gap-0.75 rounded-md border px-1.5 py-0.5 text-[10px] font-bold leading-none"
                style={{
                  color: themeColor,
                  borderColor: `${themeColor}59`,
                  backgroundColor: `${themeColor}1f`,
                }}
              >
                {remaining == null ? (
                  <Repeat className="h-2.75 w-2.75" />
                ) : remaining === 0 ? (
                  <CheckCircle2 className="h-2.75 w-2.75" />
                ) : (
                  <Repeat className="h-2.75 w-2.75" />
                )}
                {limitPill}
              </span>
            )}
          </div>
          <div className="mt-0.75 truncate text-[12.5px] leading-tight text-(--hm-white)">
            {habit.recurrenceLabel}
          </div>
          {label && (
            <span
              className="mt-1.25 inline-flex items-center gap-1 rounded-md px-1.75 py-0.5 text-[11px] font-semibold"
              style={{
                backgroundColor: `${label.color}24`,
                color: label.color,
              }}
            >
              <Tag className="h-2.75 w-2.75" />
              {label.name}
            </span>
          )}
        </div>

        <button
          type="button"
          title="Edit habit"
          aria-label={`Edit ${habit.name}`}
          onClick={(event) => {
            event.stopPropagation();
            onEdit();
          }}
          className="rounded-lg p-1.5 text-(--hm-white) transition-colors hover:bg-white/5 cursor-pointer"
        >
          <Pencil className="h-4.75 w-4.75" />
        </button>

        <AppSwitch
          value={done}
          onChange={onToggle}
          label={`Complete ${habit.name}`}
        />
      </div>

      {expanded && (
        <div className="mt-3">
          <div
            className="rounded-[14px] p-px"
            style={{
              backgroundImage: `linear-gradient(160deg, ${C.borderStrong}, ${C.border} 55%, transparent)`,
            }}
          >
            <div
              className="rounded-[13px] p-3.25"
              style={{
                backgroundImage: label
                  ? `linear-gradient(180deg, ${tint(themeColor, 14).replace(
                      C.card,
                      "#1B2620",
                    )}, #141C17)`
                  : `linear-gradient(180deg, #1B2620, #141C17)`,
              }}
            >
              {label && (
                <div className="mb-2 flex items-center gap-1.5">
                  <Tag
                    className="h-3.75 w-3.75"
                    style={{ color: label.color }}
                  />
                  <span className="text-xs font-semibold text-(--hm-muted)">
                    Label:
                  </span>
                  <span
                    className="truncate text-[12.5px] font-bold"
                    style={{ color: label.color }}
                  >
                    {label.name}
                  </span>
                </div>
              )}

              {habit.dueLabel && !(done && habit.type === "one-time") ? (
                <>
                  <div className="flex items-center gap-1.5">
                    <CalendarClock
                      className="h-3.75 w-3.75"
                      style={{ color: themeColor }}
                    />
                    <span className="text-xs font-semibold text-(--hm-muted)">
                      {habit.type === "recurring"
                        ? done
                          ? "Next occurrence:"
                          : "Due date:"
                        : "Scheduled date:"}
                    </span>
                    <span className="truncate text-[12.5px] font-semibold text-(--hm-white)">
                      {habit.dueLabel}
                    </span>
                  </div>

                  <div className="mt-2 flex flex-wrap items-center gap-1.5">
                    <span className="flex items-center gap-1.5">
                      <Clock
                        className="h-3.75 w-3.75"
                        style={{ color: themeColor }}
                      />
                      <span className="text-xs font-semibold text-(--hm-muted)">
                        Countdown:
                      </span>
                    </span>
                    <span
                      className="text-[12.5px] font-bold tabular-nums"
                      style={{ color: countdownOverdue ? C.orange : C.accent }}
                    >
                      {countdown ?? "…"}
                    </span>
                  </div>
                </>
              ) : done && habit.completedLabel ? (
                <div className="flex items-center gap-1.5">
                  <CheckCircle2
                    className="h-3.75 w-3.75"
                    style={{ color: C.green }}
                  />
                  <span className="text-xs font-semibold text-(--hm-muted)">
                    Completed at:
                  </span>
                  <span className="truncate text-[12.5px] font-semibold text-(--hm-white)">
                    {habit.completedLabel}
                  </span>
                </div>
              ) : (
                <div className="flex items-center gap-1.5">
                  <Info className="h-3.75 w-3.75 text-(--hm-muted)" />
                  <span className="text-xs text-(--hm-muted)">
                    No specific target time set
                  </span>
                </div>
              )}

              {habit.type === "recurring" && (
                <>
                  <div className="mt-2 flex items-center gap-1.5">
                    <Repeat
                      className="h-3.75 w-3.75"
                      style={{ color: themeColor }}
                    />
                    <span className="text-xs font-semibold text-(--hm-muted)">
                      Repeats:
                    </span>
                    <span className="truncate text-[12.5px] font-semibold text-(--hm-white)">
                      {habit.recurrenceLabel}
                    </span>
                  </div>
                  <div className="mt-1.5 flex items-center gap-1.5">
                    <CalendarClock
                      className="h-3.75 w-3.75"
                      style={{ color: themeColor }}
                    />
                    <span className="text-xs font-semibold text-(--hm-muted)">
                      Remaining:
                    </span>
                    <span className="truncate text-[12.5px] font-semibold text-(--hm-white)">
                      {habit.repeatCount == null || remaining == null
                        ? "Unlimited"
                        : remaining === 0
                          ? `Series complete · ${habit.repeatCount} of ${habit.repeatCount}`
                          : `${remaining} of ${habit.repeatCount} occurrences`}
                    </span>
                  </div>
                </>
              )}

              {habit.description && (
                <div className="mt-2 flex items-start gap-1.5">
                  <Info className="mt-px h-3.5 w-3.5 shrink-0 text-(--hm-muted)" />
                  <span className="text-[11.5px] leading-snug text-(--hm-muted)">
                    {habit.description}
                  </span>
                </div>
              )}

              {habit.notify && (
                <div className="mt-2 flex items-center gap-1.5">
                  <BellRing
                    className="h-3.5 w-3.5"
                    style={{ color: C.green }}
                  />
                  <span
                    className="text-[11.5px] font-medium"
                    style={{ color: C.green }}
                  >
                    Notifications enabled for this habit
                  </span>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Calendar view                                                       */
/* ------------------------------------------------------------------ */

const MONTH_TITLE = "November 2026";
const FIRST_WEEKDAY_INDEX = 6; // Monday-start offset for 1 Nov 2026 (Sunday)
const DAYS_IN_MONTH = 30;
const TODAY = 24;

function HeatDay({
  day,
  count,
  selected,
  isToday,
  onClick,
}: {
  day: number;
  count: number;
  selected: boolean;
  isToday: boolean;
  onClick: () => void;
}) {
  const level = Math.min(count / 10, 1);
  const baseAlpha = count > 0 ? 0.14 + 0.64 * level : 0;
  const alpha = selected
    ? count > 0
      ? Math.min(Math.max(baseAlpha + 0.14, 0.3), 0.9)
      : 0.18
    : baseAlpha;
  const fill =
    count > 0 || selected ? `rgba(43,214,115,${alpha})` : "transparent";
  const light = alpha > 0 && isLightFill(C.accent, alpha);
  const glow = count > 0 ? Math.min(0.14 + 0.045 * count, 0.5) : 0;

  return (
    <button
      type="button"
      onClick={onClick}
      className="mx-auto flex h-8.5 w-8.5 items-center justify-center rounded-[10px] transition-all duration-200 cursor-pointer"
      style={{
        backgroundColor: fill,
        boxShadow:
          [
            glow > 0 ? `0 0 10px 1px rgba(43,214,115,${glow})` : null,
            isToday ? "0 0 14px 1.5px rgba(43,214,115,0.55)" : null,
            selected ? "0 0 0 2px rgba(237,243,236,0.55)" : null,
          ]
            .filter(Boolean)
            .join(", ") || undefined,
      }}
      aria-pressed={selected}
    >
      <span
        className="text-[13px]"
        style={{
          color: light ? C.black : C.white,
          fontWeight: isToday || selected ? 700 : 500,
          textShadow: light ? undefined : "0 1px 3px rgba(0,0,0,0.45)",
        }}
      >
        {day}
      </span>
    </button>
  );
}

function CalendarView({
  habits,
  labels,
  onToggleHabit,
  onEditHabit,
}: {
  habits: MockHabit[];
  labels: MockLabel[];
  onToggleHabit: (id: string) => void;
  onEditHabit: (habit: MockHabit) => void;
}) {
  const [selectedDay, setSelectedDay] = useState(TODAY);
  const [showOneTime, setShowOneTime] = useState(true);
  const [showRecurring, setShowRecurring] = useState(true);

  const visible = habits.filter((habit) =>
    habit.type === "recurring" ? showRecurring : showOneTime,
  );
  const countFor = (day: number) =>
    visible.filter((habit) => habit.days?.includes(day)).length;

  const selectedHabits = visible.filter((habit) =>
    habit.days?.includes(selectedDay),
  );
  const recurring = selectedHabits.filter(
    (habit) => habit.type === "recurring",
  );
  const oneTime = selectedHabits.filter((habit) => habit.type === "one-time");

  const monthName = new Intl.DateTimeFormat("en-GB", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(2026, 10, selectedDay));

  const cells: (number | null)[] = [
    ...Array.from({ length: FIRST_WEEKDAY_INDEX }, () => null),
    ...Array.from({ length: DAYS_IN_MONTH }, (_, index) => index + 1),
  ];
  while (cells.length % 7 !== 0) cells.push(null);

  const dayList = (list: MockHabit[], title: string, accent: string) =>
    list.length > 0 && (
      <div className="mb-2.5">
        <div className="mb-2 flex items-center gap-1.5">
          <span
            className="h-3 w-0.75 rounded-full"
            style={{ backgroundColor: accent }}
          />
          <span className="text-xs font-bold text-(--hm-white)">{title}</span>
        </div>
        <div className="space-y-2">
          {list.map((habit) => {
            const label = labelFor(labels, habit.labelId);
            const color = label?.color ?? C.accentDeep;
            return (
              <div
                key={habit.id}
                className="flex items-center gap-2.5 rounded-xl px-2.5 py-2"
                style={{
                  backgroundColor: C.surface,
                  border: `1px solid ${C.border}`,
                }}
              >
                <span
                  className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg"
                  style={{ backgroundColor: `${color}26` }}
                >
                  {habit.type === "recurring" ? (
                    <Repeat className="h-3.5 w-3.5" style={{ color }} />
                  ) : (
                    <Flag className="h-3.5 w-3.5" style={{ color }} />
                  )}
                </span>
                <div className="min-w-0 flex-1">
                  <div
                    className="truncate text-[11.5px] font-semibold"
                    style={{ color: habit.isDone ? C.muted : C.white }}
                  >
                    {habit.name}
                  </div>
                  <div className="truncate text-[10px] text-(--hm-muted)">
                    {label?.name ?? "No Label"} · {habit.recurrenceLabel}
                  </div>
                </div>
                <button
                  type="button"
                  aria-label={`Toggle ${habit.name}`}
                  onClick={() => onToggleHabit(habit.id)}
                  className="rounded-md p-0.5 cursor-pointer"
                >
                  <CheckCircle2
                    className="h-4.5 w-4.5"
                    style={{ color: habit.isDone ? C.accent : C.faint }}
                  />
                </button>
                <button
                  type="button"
                  aria-label={`Edit ${habit.name}`}
                  onClick={() => onEditHabit(habit)}
                  className="rounded-md p-0.5 text-(--hm-muted) cursor-pointer"
                >
                  <Pencil className="h-3.5 w-3.5" />
                </button>
              </div>
            );
          })}
        </div>
      </div>
    );

  return (
    <div className="space-y-3 pt-1">
      <div
        className="rounded-2xl py-2"
        style={{ backgroundColor: C.card, boxShadow: RAISED_SHADOW }}
      >
        <div className="flex items-center justify-between px-3 py-1">
          <button
            type="button"
            aria-label="Previous month"
            className="rounded-lg p-1 text-(--hm-white) hover:bg-white/5 cursor-pointer"
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <span className="text-[16px] font-bold text-(--hm-white)">
            {MONTH_TITLE}
          </span>
          <button
            type="button"
            aria-label="Next month"
            className="rounded-lg p-1 text-(--hm-white) hover:bg-white/5 cursor-pointer"
          >
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>

        <div className="grid grid-cols-7 px-2 pt-1">
          {["M", "T", "W", "T", "F", "S", "S"].map((day, index) => (
            <span
              key={`${day}-${index}`}
              className="py-1 text-center text-xs font-semibold text-(--hm-muted)"
            >
              {day}
            </span>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-y-1 px-2 pb-1">
          {cells.map((day, index) =>
            day === null ? (
              <span key={`blank-${index}`} />
            ) : (
              <HeatDay
                key={day}
                day={day}
                count={countFor(day)}
                selected={day === selectedDay}
                isToday={day === TODAY}
                onClick={() => setSelectedDay(day)}
              />
            ),
          )}
        </div>
      </div>

      <div className="flex gap-2.5">
        {[
          {
            label: "One-Time",
            icon: Flag,
            active: showOneTime,
            toggle: () => setShowOneTime((v) => !v),
          },
          {
            label: "Recurring",
            icon: Repeat,
            active: showRecurring,
            toggle: () => setShowRecurring((v) => !v),
          },
        ].map(({ label, icon: Icon, active, toggle }) => (
          <button
            key={label}
            type="button"
            onClick={toggle}
            aria-pressed={active}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-xl px-2.5 py-2.5 text-[13px] transition-all duration-200 cursor-pointer ${
              active
                ? "bg-linear-to-br from-[#43D17C] to-[#128A44] font-bold text-[#0A0E0B] shadow-[0_4px_14px_rgba(43,214,115,0.3)]"
                : "font-medium text-(--hm-muted)"
            }`}
            style={
              active
                ? undefined
                : { backgroundColor: C.card, boxShadow: RAISED_SHADOW_SMALL }
            }
          >
            <Icon className="h-4 w-4" />
            <span className="truncate">{label}</span>
            {active ? (
              <CheckCircle2 className="h-3.5 w-3.5" />
            ) : (
              <span className="h-3.5 w-3.5 rounded-full border border-current" />
            )}
          </button>
        ))}
      </div>

      <div
        className="rounded-2xl p-4"
        style={{ backgroundColor: C.card, boxShadow: RAISED_SHADOW }}
      >
        <div className="mb-3 flex items-center justify-between gap-2">
          <span className="text-[13px] font-bold leading-tight text-(--hm-white)">
            {monthName}
          </span>
          <span
            className="shrink-0 rounded-[10px] px-2 py-0.75 text-[11.5px] font-semibold text-(--hm-muted)"
            style={{ backgroundColor: C.surfaceLight }}
          >
            {selectedHabits.length} habits
          </span>
        </div>

        {selectedHabits.length === 0 ? (
          <p className="py-3 text-center text-[13px] leading-relaxed text-(--hm-muted)">
            {!showOneTime && !showRecurring
              ? "Both filters are off. Turn on One-Time or Recurring above."
              : "No scheduled habits on this day."}
          </p>
        ) : (
          <>
            {dayList(recurring, "Recurring Habits", C.accent)}
            {dayList(oneTime, "One-Time Habits", C.orange)}
          </>
        )}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Habit form (centre dialog, like the Flutter app)                    */
/* ------------------------------------------------------------------ */

const PRESETS = [
  { label: "Daily", interval: 1, unit: "days" as const },
  { label: "Weekly", interval: 7, unit: "days" as const },
  { label: "Monthly", interval: 1, unit: "months" as const },
  { label: "Every 2 days", interval: 2, unit: "days" as const },
  { label: "Hourly", interval: 1, unit: "hours" as const },
];

function recurrenceText(interval: number, unit: "days" | "hours" | "months") {
  const singular = unit.slice(0, -1);
  return interval === 1
    ? `Every ${singular}`
    : `Every ${interval} ${unit}`;
}

function HabitForm({
  habit,
  onClose,
  onSave,
  onDelete,
}: {
  habit: MockHabit | null;
  onClose: () => void;
  onSave: (input: NewHabitInput) => void;
  onDelete: () => void;
}) {
  const [name, setName] = useState(habit?.name ?? "");
  const [labelId, setLabelId] = useState<string | null>(habit?.labelId ?? null);
  const [isRecurring, setIsRecurring] = useState(
    habit ? habit.type === "recurring" : true,
  );
  const [interval, setIntervalValue] = useState(habit?.recurInterval ?? 1);
  const [unit, setUnit] = useState<"days" | "hours" | "months">(
    habit?.recurUnit ?? "days",
  );
  const [preset, setPreset] = useState(
    PRESETS.find(
      (item) =>
        item.interval === (habit?.recurInterval ?? 1) &&
        item.unit === (habit?.recurUnit ?? "days"),
    )?.label ?? "",
  );
  const [repeatCount, setRepeatCount] = useState(
    habit?.repeatCount ? String(habit.repeatCount) : "",
  );
  const [description, setDescription] = useState(habit?.description ?? "");
  const [notify, setNotify] = useState(habit?.notify ?? true);
  const [error, setError] = useState("");

  const applyPreset = (next: (typeof PRESETS)[number]) => {
    setPreset(next.label);
    setIntervalValue(next.interval);
    setUnit(next.unit);
  };

  const save = () => {
    const trimmed = name.trim();
    if (!trimmed) {
      setError("Please name your habit");
      return;
    }
    const parsedRepeat = parseInt(repeatCount, 10);
    onSave({
      name: trimmed,
      type: isRecurring ? "recurring" : "one-time",
      labelId,
      recurrenceLabel: isRecurring
        ? recurrenceText(interval, unit)
        : "One-time habit",
      notify,
      description: description.trim() || undefined,
      repeatCount:
        isRecurring && repeatCount.trim() !== ""
          ? Number.isNaN(parsedRepeat) || parsedRepeat < 1
            ? 1
            : parsedRepeat
          : null,
      recurInterval: interval,
      recurUnit: unit,
    });
  };

  return (
    <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/75 p-4 backdrop-blur-[2px]">
      <div
        className="flex max-h-[94%] w-full max-w-[320px] flex-col overflow-hidden rounded-[22px] border"
        style={{ backgroundColor: C.surface, borderColor: C.border }}
      >
        <div
          className="flex items-center gap-3 border-b px-4 py-3"
          style={{ borderColor: C.border }}
        >
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-linear-to-br from-[#43D17C] to-[#128A44]">
            <Plus className="h-5 w-5 stroke-3 text-[#0A0E0B]" />
          </span>
          <span className="flex-1 text-[15px] font-bold text-(--hm-white)">
            {habit ? "Edit Habit" : "Create New Habit"}
          </span>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="rounded-lg p-1.5 text-(--hm-muted) hover:text-(--hm-white) cursor-pointer"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="flex-1 space-y-3 overflow-y-auto px-4 py-3">
          <div>
            <label className="text-[10px] font-bold tracking-[1.1px] text-(--hm-muted)">
              HABIT TITLE
            </label>
            <input
              value={name}
              onChange={(event) => {
                setName(event.target.value);
                setError("");
              }}
              placeholder="e.g. Drink 2L water, Morning run"
              className="mt-2 w-full rounded-xl px-3.5 py-2.5 text-[13.5px] text-(--hm-white) placeholder:text-(--hm-muted) focus:outline-none"
              style={{
                backgroundColor: C.card,
                border: `1px solid ${error ? C.orange : "transparent"}`,
              }}
            />
            {error && (
              <p className="mt-1 text-[11px]" style={{ color: C.orange }}>
                {error}
              </p>
            )}
          </div>

          <div>
            <label className="text-[10px] font-bold tracking-[1.1px] text-(--hm-muted)">
              DESCRIPTION / NOTES (OPTIONAL)
            </label>
            <textarea
              value={description}
              onChange={(event) => setDescription(event.target.value.slice(0, 300))}
              rows={2}
              placeholder="Why this matters, or a short reminder note"
              className="mt-2 w-full resize-none rounded-xl px-3.5 py-2.5 text-[13px] text-(--hm-white) placeholder:text-(--hm-muted) focus:outline-none"
              style={{ backgroundColor: C.card }}
            />
          </div>

          <div>
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold tracking-[1.1px] text-(--hm-muted)">
                LABEL / GROUP
              </span>
              <span className="flex items-center gap-1 text-[11px] font-bold text-(--hm-white)">
                <Plus className="h-3 w-3" /> New Label
              </span>
            </div>
            <div className="mt-2 flex gap-1.5 overflow-x-auto pb-1">
              <button
                type="button"
                onClick={() => setLabelId(null)}
                className="shrink-0 rounded-lg border px-2.5 py-1.5 text-[11.5px]"
                style={{
                  backgroundColor: labelId === null ? `${C.accent}24` : C.card,
                  color: labelId === null ? C.accent : C.muted,
                  fontWeight: labelId === null ? 700 : 500,
                  borderColor: labelId === null ? `${C.accent}59` : "transparent",
                }}
              >
                None
              </button>
              {DEMO_LABELS.map((label) => {
                const active = labelId === label.id;
                return (
                  <button
                    key={label.id}
                    type="button"
                    onClick={() => setLabelId(label.id)}
                    className="flex shrink-0 items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[11.5px]"
                    style={{
                      backgroundColor: active ? `${label.color}24` : C.card,
                      borderColor: active ? `${label.color}59` : "transparent",
                    }}
                  >
                    <span
                      className="h-2 w-2 rounded-full"
                      style={{ backgroundColor: label.color }}
                    />
                    <span
                      style={{
                        color: active ? C.accent : C.muted,
                        fontWeight: active ? 700 : 500,
                      }}
                    >
                      {label.name}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <span className="text-[10px] font-bold tracking-[1.1px] text-(--hm-muted)">
              FREQUENCY
            </span>
            <div className="mt-2 grid grid-cols-2 gap-2.5">
              {[
                {
                  title: "Recurring",
                  subtitle: "Repeats periodically",
                  Icon: Repeat,
                  value: true,
                },
                {
                  title: "One-Time",
                  subtitle: "Single target event",
                  Icon: Flag,
                  value: false,
                },
              ].map(({ title, subtitle, Icon, value }) => {
                const active = isRecurring === value;
                return (
                  <button
                    key={title}
                    type="button"
                    onClick={() => setIsRecurring(value)}
                    className="rounded-xl border p-3 text-left"
                    style={{
                      backgroundColor: active ? `${C.accent}14` : C.card,
                      borderColor: active ? `${C.accent}73` : C.border,
                    }}
                  >
                    <div className="flex items-center">
                      <Icon
                        className="h-4.5 w-4.5"
                        style={{ color: active ? C.accent : C.muted }}
                      />
                      <span className="flex-1" />
                      {active ? (
                        <CheckCircle2
                          className="h-4 w-4"
                          style={{ color: C.accent }}
                        />
                      ) : (
                        <span className="h-4 w-4 rounded-full border border-(--hm-muted)" />
                      )}
                    </div>
                    <div
                      className="mt-2 text-sm font-bold"
                      style={{ color: active ? C.white : C.muted }}
                    >
                      {title}
                    </div>
                    <div className="mt-0.5 text-[11px] text-(--hm-muted)">
                      {subtitle}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {isRecurring && (
            <>
              <div>
                <span className="text-[10px] font-bold tracking-[1.1px] text-(--hm-muted)">
                  HOW OFTEN DOES IT REPEAT?
                </span>
                <div className="mt-2 grid grid-cols-2 gap-1.5">
                  {PRESETS.map((item) => {
                    const active = preset === item.label;
                    return (
                      <button
                        key={item.label}
                        type="button"
                        onClick={() => applyPreset(item)}
                        className="rounded-lg border px-2 py-1.5 text-center text-[11px]"
                        style={{
                          backgroundColor: active
                            ? `${C.accent}24`
                            : C.surfaceLight,
                          borderColor: active ? `${C.accent}59` : "transparent",
                          color: active ? C.accent : C.muted,
                          fontWeight: active ? 700 : 500,
                        }}
                      >
                        {item.label}
                      </button>
                    );
                  })}
                </div>

                <div
                  className="mt-2 flex items-center gap-2 rounded-xl px-3 py-2.5"
                  style={{ backgroundColor: C.surfaceLight }}
                >
                  <span className="text-[13px] font-semibold text-(--hm-muted)">
                    Every
                  </span>
                  <input
                    type="number"
                    min={1}
                    value={interval}
                    onChange={(event) => {
                      const next = parseInt(event.target.value || "1", 10);
                      setIntervalValue(
                        Number.isNaN(next) || next < 1 ? 1 : next,
                      );
                    }}
                    className="w-12 rounded-lg px-2 py-1.5 text-center text-sm font-bold text-(--hm-white) focus:outline-none"
                    style={{ backgroundColor: C.card }}
                  />
                  <select
                    value={unit}
                    onChange={(event) =>
                      setUnit(event.target.value as typeof unit)
                    }
                    className="flex-1 rounded-lg px-2 py-1.5 text-[13px] font-semibold text-(--hm-white) focus:outline-none"
                    style={{ backgroundColor: C.card }}
                  >
                    <option value="days">day(s)</option>
                    <option value="hours">hour(s)</option>
                    <option value="months">month(s)</option>
                  </select>
                </div>

                <div
                  className="mt-2 flex items-center gap-2 rounded-xl px-3 py-2.5"
                  style={{ backgroundColor: C.surfaceLight }}
                >
                  <span className="text-[13px] font-semibold text-(--hm-muted)">
                    Repeat
                  </span>
                  <input
                    type="number"
                    min={1}
                    value={repeatCount}
                    placeholder="∞"
                    onChange={(event) => setRepeatCount(event.target.value)}
                    className="w-12 rounded-lg px-2 py-1.5 text-center text-sm font-bold text-(--hm-white) placeholder:text-(--hm-muted) focus:outline-none"
                    style={{ backgroundColor: C.card }}
                  />
                  <span className="text-[12.5px] font-semibold text-(--hm-muted)">
                    {repeatCount.trim() === "" ? "times" : "times, then it stops"}
                  </span>
                </div>
              </div>

              <div>
                <span className="text-[10px] font-bold tracking-[1.1px] text-(--hm-muted)">
                  FIRST OCCURRENCE / START TIME
                </span>
                <div
                  className="mt-2 flex items-center gap-2.5 rounded-xl border px-3.5 py-2.5"
                  style={{ backgroundColor: C.card, borderColor: C.border }}
                >
                  <CalendarDays
                    className="h-5 w-5"
                    style={{ color: C.accent }}
                  />
                  <span className="flex-1 truncate text-[13px] font-semibold text-(--hm-white)">
                    Tue, 24 Nov 2026 · 08:00 AM
                  </span>
                  <Pencil className="h-4 w-4 text-(--hm-muted)" />
                </div>
              </div>
            </>
          )}

          <div
            className="flex items-center gap-3 rounded-xl border px-3.5 py-2.5"
            style={{ backgroundColor: C.card, borderColor: C.border }}
          >
            <span
              className="flex h-8 w-8 items-center justify-center rounded-lg"
              style={{
                backgroundColor: notify
                  ? "rgba(237,243,236,0.12)"
                  : "rgba(142,156,144,0.12)",
              }}
            >
              {notify ? (
                <BellRing className="h-4.5 w-4.5 text-(--hm-white)" />
              ) : (
                <BellOff className="h-4.5 w-4.5 text-(--hm-muted)" />
              )}
            </span>
            <div className="flex-1">
              <div className="text-sm font-semibold text-(--hm-white)">
                Remind Me
              </div>
              <div className="text-xs text-(--hm-muted)">
                {notify ? "Notification will be sent" : "No notifications"}
              </div>
            </div>
            <AppSwitch
              value={notify}
              onChange={() => setNotify((value) => !value)}
              label="Remind me"
            />
          </div>
        </div>

        <div
          className="flex items-center gap-2.5 px-4 py-3"
          style={{ backgroundColor: C.card }}
        >
          {habit && (
            <button
              type="button"
              onClick={onDelete}
              aria-label="Delete habit"
              className="rounded-xl p-2.5 text-(--hm-muted) cursor-pointer"
              style={{ backgroundColor: C.surfaceLight }}
            >
              <Trash2 className="h-5 w-5" />
            </button>
          )}
          <button
            type="button"
            onClick={save}
            className="flex-1 rounded-xl bg-linear-to-br from-[#43D17C] to-[#128A44] py-3 text-sm font-extrabold text-[#0A0E0B] shadow-[0_6px_16px_rgba(43,214,115,0.25)] cursor-pointer"
          >
            {habit ? "Save Changes" : "Create Habit"}
          </button>
        </div>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Main demo                                                           */
/* ------------------------------------------------------------------ */

interface DemoSectionProps {
  habits: MockHabit[];
  onToggleHabit: (id: string) => void;
  onAddHabit: (input: NewHabitInput) => void;
  onUpdateHabit: (id: string, input: NewHabitInput) => void;
  onDeleteHabit: (id: string) => void;
}

export function DemoSection({
  habits,
  onToggleHabit,
  onAddHabit,
  onUpdateHabit,
  onDeleteHabit,
}: DemoSectionProps) {
  const [activeTab, setActiveTab] = useState<"list" | "calendar">("list");
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [formHabit, setFormHabit] = useState<MockHabit | "new" | null>(null);
  const [openSections, setOpenSections] = useState({
    active: true,
    completed: true,
  });
  const [closedGroups, setClosedGroups] = useState<Record<string, boolean>>({});

  // The demo starts a quiet 30s timer on the first interaction. It keeps
  // running in the background, so anyone actually trying the app gets the
  // "get the real thing" card inside the phone.
  const [engaged, setEngaged] = useState(false);
  const [promoOpen, setPromoOpen] = useState(false);
  const [promoDismissed, setPromoDismissed] = useState(false);

  useEffect(() => {
    if (!engaged || promoDismissed) return;
    const timer = window.setTimeout(() => setPromoOpen(true), 30_000);
    return () => window.clearTimeout(timer);
  }, [engaged, promoDismissed]);

  const activeHabits = habits.filter((habit) => !habit.isDone);
  const completedHabits = habits.filter((habit) => habit.isDone);

  const groupHabits = (list: MockHabit[]) => {
    const groups = new Map<string | null, MockHabit[]>();
    for (const habit of list) {
      const key = habit.labelId;
      groups.set(key, [...(groups.get(key) ?? []), habit]);
    }
    const labelled = DEMO_LABELS.filter((label) => groups.has(label.id)).sort(
      (a, b) => a.name.localeCompare(b.name),
    );
    const result: { label: MockLabel | null; habits: MockHabit[] }[] =
      labelled.map((label) => ({
        label,
        habits: groups.get(label.id) ?? [],
      }));
    if (groups.has(null))
      result.push({ label: null, habits: groups.get(null) ?? [] });
    return result;
  };

  const renderSection = (
    title: string,
    key: "active" | "completed",
    list: MockHabit[],
    accent: string,
  ) => (
    <div>
      <SectionHeader
        title={title}
        count={list.length}
        accent={accent}
        expanded={openSections[key]}
        onToggle={() =>
          setOpenSections((prev) => ({ ...prev, [key]: !prev[key] }))
        }
      />
      {openSections[key] &&
        (list.length === 0 ? (
          <div
            className="rounded-2xl px-4 py-5 text-sm text-(--hm-muted)"
            style={{ backgroundColor: C.card, boxShadow: RAISED_SHADOW_SMALL }}
          >
            {key === "active"
              ? "All caught up. Nothing active right now."
              : "Finished habits show up here."}
          </div>
        ) : (
          <div>
            {groupHabits(list).map(({ label, habits: group }) => {
              const groupKey = `${key}:${label?.id ?? "none"}`;
              const open = !closedGroups[groupKey];
              return (
                <div key={groupKey}>
                  <LabelSubheader
                    label={label}
                    count={group.length}
                    expanded={open}
                    onToggle={() =>
                      setClosedGroups((prev) => ({ ...prev, [groupKey]: open }))
                    }
                  />
                  {open && (
                    <div className="space-y-2.5 pb-1">
                      {group.map((habit) => (
                        <HabitTile
                          key={habit.id}
                          habit={habit}
                          label={labelFor(DEMO_LABELS, habit.labelId)}
                          onToggle={() => onToggleHabit(habit.id)}
                          onEdit={() => setFormHabit(habit)}
                        />
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        ))}
    </div>
  );

  const saveForm = (input: NewHabitInput) => {
    if (formHabit && formHabit !== "new") {
      onUpdateHabit(formHabit.id, input);
    } else {
      onAddHabit(input);
    }
    setFormHabit(null);
  };

  return (
    <section
      id="demo"
      className="py-20 px-6 sm:px-10 border-y border-[#262626] bg-[#0A0A0A]/60"
    >
      <div
        className="max-w-7xl mx-auto flex flex-col items-center"
        style={themeVars}
      >
        <div data-reveal className="text-center mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#141414] border border-[#262626] text-xs text-[#2BD673] font-medium mb-3">
            <Smartphone className="w-3.5 h-3.5" />
            <span>App Functionality Sample</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Experience the Mobile App UI
          </h2>
          <p className="text-sm sm:text-base text-[#8A8A8A] max-w-lg mt-2 mx-auto">
            Try it right here: tap a habit, complete it, and watch it roll
            forward — no download needed.
          </p>
          <p className="text-[10px] text-[#8A8A8A] mt-2 italic">
            *Does not represent the final product*
          </p>
        </div>

        {/* Mobile Device Frame */}
        <div
          data-anim="demo-phone"
          className="relative w-full max-w-95 rounded-[44px] p-3 bg-linear-to-b from-[#262626] via-[#141414] to-[#121212] border border-[#333] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.9)]"
        >
          {/* Phone Speaker & Camera Notch */}
          <div className="absolute top-5 left-1/2 -translate-x-1/2 w-28 h-4 bg-black rounded-full z-30 flex items-center justify-center">
            <div className="w-10 h-1 bg-[#262626] rounded-full mr-2" />
            <div className="w-2.5 h-2.5 bg-[#141414] rounded-full border border-[#262626]" />
          </div>

          {/* Phone Inner Screen */}
          <div
            onPointerDown={() => setEngaged(true)}
            className="relative w-full h-170 rounded-[36px] overflow-hidden flex flex-col border border-black select-none text-(--hm-white)"
            style={{
              backgroundImage: `linear-gradient(180deg, #0E1511 0%, ${C.black} 35%, ${C.black} 100%)`,
            }}
          >
            {/* Status Bar */}
            <div className="h-10 pt-2 px-6 flex items-center justify-between text-[11px] text-(--hm-muted) font-semibold">
              <span>9:41</span>
              <div className="flex items-center gap-1.5 text-(--hm-white)">
                <span className="h-1.5 w-1.5 rounded-full bg-(--hm-accent)" />
                <div className="w-4 h-2 border border-(--hm-white) rounded-sm p-0.5 flex items-center">
                  <div className="h-full w-full rounded-[1px] bg-(--hm-accent)" />
                </div>
              </div>
            </div>

            {/* AppBar */}
            <div className="h-14 px-3 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setIsDrawerOpen(true)}
                  className="p-2 -ml-1 text-(--hm-white) hover:bg-(--hm-surface) rounded-lg transition cursor-pointer"
                  title="Menu"
                  aria-label="Open menu"
                >
                  <Menu className="h-5 w-5" />
                </button>
                <span className="font-extrabold text-[21px] tracking-[0.4px]">
                  HabitMe
                </span>
              </div>

              <button
                type="button"
                onClick={() =>
                  setActiveTab(activeTab === "list" ? "calendar" : "list")
                }
                className="p-2 text-(--hm-white) hover:bg-(--hm-surface) rounded-lg transition cursor-pointer"
                title={activeTab === "list" ? "Show calendar" : "Show list"}
                aria-label={
                  activeTab === "list" ? "Show calendar" : "Show list"
                }
              >
                {activeTab === "list" ? (
                  <CalendarDays className="h-5 w-5" />
                ) : (
                  <List className="h-5 w-5" />
                )}
              </button>
            </div>

            {/* Drawer */}
            {isDrawerOpen && (
              <div className="absolute inset-0 z-40 flex bg-black/60">
                <div
                  className="flex h-full w-[82%] flex-col justify-between border-r px-4 pt-5 shadow-2xl"
                  style={{ backgroundColor: C.surface, borderColor: C.border }}
                >
                  <div>
                    <div className="flex items-start gap-3.5 px-1 pb-5">
                      <Image
                        src="/habitme_logo_rounded.png"
                        alt="HabitMe logo"
                        width={52}
                        height={52}
                        className="rounded-2xl"
                      />
                      <div className="min-w-0 flex-1">
                        <div className="text-[22px] font-extrabold leading-tight">
                          HabitMe
                        </div>
                        <div className="mt-0.5 truncate text-[12.5px] text-(--hm-muted)">
                          Your Day. Your Habits.
                        </div>
                      </div>
                      <button
                        type="button"
                        onClick={() => setIsDrawerOpen(false)}
                        aria-label="Close menu"
                        className="rounded-lg p-1 text-(--hm-muted) hover:bg-white/5 hover:text-white cursor-pointer"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                    <div
                      className="h-px"
                      style={{ backgroundColor: C.border }}
                    />

                    <div className="mt-2 space-y-0.5">
                      {[
                        {
                          icon: BookOpen,
                          title: "Guide",
                          subtitle: "How to use HabitMe & app details",
                        },
                        {
                          icon: Tags,
                          title: "Manage Labels",
                          subtitle: "Create and organize your habit labels",
                        },
                        {
                          icon: Bug,
                          title: "Logs",
                          subtitle: "Live app logs for debugging",
                        },
                        {
                          icon: Upload,
                          title: "Import",
                          subtitle:
                            "Restore habits and labels from a SQL backup",
                        },
                        {
                          icon: Download,
                          title: "Export",
                          subtitle: "Save habits and labels as a SQL file",
                        },
                        {
                          icon: Heart,
                          title: "Support developer",
                          subtitle: "Watch a short ad to support HabitMe",
                        },
                      ].map(({ icon: Icon, title, subtitle }) => (
                        <button
                          key={title}
                          type="button"
                          onClick={() => setIsDrawerOpen(false)}
                          className="flex w-full items-center gap-4 rounded-lg px-3 py-2.5 text-left transition hover:bg-white/5 cursor-pointer"
                        >
                          <Icon className="h-5 w-5 shrink-0 text-(--hm-white)" />
                          <span className="min-w-0">
                            <span className="block text-sm font-medium text-(--hm-white)">
                              {title}
                            </span>
                            <span className="block truncate text-xs text-(--hm-muted)">
                              {subtitle}
                            </span>
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>

                  <Link
                    href={MADE_BY_URL}
                    target="_blank"
                    rel="noreferrer"
                    className="mb-4 flex items-center gap-3 rounded-2xl px-4 py-3.5 transition hover:brightness-125"
                    style={{
                      backgroundColor: C.black,
                      boxShadow: RAISED_SHADOW,
                    }}
                  >
                    <span
                      className="flex h-9 w-9 items-center justify-center rounded-[10px]"
                      style={{ backgroundColor: "rgba(224,101,95,0.14)" }}
                    >
                      <Heart className="h-4.5 w-4.5" style={{ color: C.red }} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-[11.5px] tracking-[0.6px] text-(--hm-muted)">
                        MADE BY
                      </span>
                      <span className="block text-[15px] font-bold text-(--hm-white)">
                        ItsMe Prince
                      </span>
                    </span>
                    <ArrowUpRight className="h-4.5 w-4.5 text-(--hm-muted)" />
                  </Link>
                </div>
                <button
                  type="button"
                  aria-label="Close menu"
                  className="flex-1 cursor-pointer"
                  onClick={() => setIsDrawerOpen(false)}
                />
              </div>
            )}

            {/* Screen Content */}
            <div className="flex-1 overflow-y-auto px-4 pb-24 pt-1">
              {activeTab === "list" ? (
                <div className="space-y-3.5">
                  {renderSection("Active", "active", activeHabits, C.accent)}
                  {renderSection(
                    "Completed",
                    "completed",
                    completedHabits,
                    C.orange,
                  )}
                </div>
              ) : (
                <CalendarView
                  habits={habits}
                  labels={DEMO_LABELS}
                  onToggleHabit={onToggleHabit}
                  onEditHabit={(habit) => setFormHabit(habit)}
                />
              )}
            </div>

            {/* FAB */}
            <div className="absolute bottom-5 right-4 z-20">
              <button
                type="button"
                onClick={() => setFormHabit("new")}
                className="flex h-11.5 items-center gap-2 rounded-[18px] bg-linear-to-br from-[#43D17C] to-[#128A44] px-4 text-xs font-extrabold text-[#0A0E0B] shadow-[0_8px_20px_rgba(43,214,115,0.28)] transition hover:scale-[1.03] cursor-pointer"
              >
                <Plus className="h-4 w-4 stroke-3" />
                <span>New habit</span>
              </button>
            </div>

            {/* In-phone download prompt, started by the interaction timer */}
            {promoOpen && (
              <div className="absolute inset-0 z-60 flex items-center justify-center bg-black/80 p-5 backdrop-blur-[2px]">
                <div
                  className="w-full max-w-[280px] rounded-2xl border p-4 text-center"
                  style={{ backgroundColor: C.surface, borderColor: C.border }}
                >
                  <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-linear-to-br from-[#43D17C] to-[#128A44]">
                    <Download className="h-6 w-6 stroke-3 text-[#0A0E0B]" />
                  </span>
                  <h3 className="mt-3 text-[17px] font-extrabold text-(--hm-white)">
                    Enjoying the demo?
                  </h3>
                  <p className="mt-1.5 text-[12.5px] leading-relaxed text-(--hm-muted)">
                    This is only a preview. Download the HabitMe app to keep
                    your habits, labels and reminders on your phone — and never
                    lose a streak.
                  </p>
                  <Link
                    href={GITHUB_RELEASE_URL}
                    target="_blank"
                    rel="noreferrer"
                    className="mt-4 flex items-center justify-center gap-2 rounded-xl bg-linear-to-br from-[#43D17C] to-[#128A44] py-2.5 text-[13px] font-extrabold text-[#0A0E0B]"
                  >
                    <Download className="h-4 w-4 stroke-3" />
                    Download the app
                  </Link>
                  <button
                    type="button"
                    onClick={() => {
                      setPromoOpen(false);
                      setPromoDismissed(true);
                    }}
                    className="mt-2 w-full rounded-xl py-2 text-[12px] font-bold text-(--hm-muted) transition-colors hover:text-(--hm-white) cursor-pointer"
                  >
                    Keep exploring
                  </button>
                </div>
              </div>
            )}

            {/* Habit form dialog */}
            {formHabit !== null && (
              <HabitForm
                habit={formHabit === "new" ? null : formHabit}
                onClose={() => setFormHabit(null)}
                onSave={saveForm}
                onDelete={() => {
                  if (formHabit !== "new") onDeleteHabit(formHabit.id);
                  setFormHabit(null);
                }}
              />
            )}
          </div>
        </div>

        <p className="mt-8 flex items-center gap-2 text-xs text-[#8A8A8A]">
          <Clock className="h-3.5 w-3.5" />
          Live countdowns, label groups and the calendar heatmap all run in this
          mockup — no app install needed.
        </p>
      </div>
    </section>
  );
}

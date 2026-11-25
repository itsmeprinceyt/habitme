# HabitMe Flutter App — UI / UX Guide

> Project-specific documentation for the Android app's interface. Describes the
> palette, layout rules, screens and interaction patterns that the website's
> phone mockup imitates.
>
> Last updated: 25 November 2026

---

## 1. Feel

A calm, deep green-black personal tool. One accent colour, flat raised cards,
lots of tiny uppercase labels, and motion that explains state instead of
decorating it. The app has **no light theme** and no colour customisation beyond
user labels.

Guiding ideas from the product story (Guide page): habits distort after a break,
so the UI must make the next occurrence obvious, roll forward automatically, and
never hide missed history.

---

## 2. Colour Palette (`core/theme/app_colors.dart`)

| Token | Hex | Usage |
| --- | --- | --- |
| `black` | `#0A0E0B` | scaffold, FAB foreground |
| `surface` | `#141B16` | app bar, drawer, dialogs |
| `surfaceLight` | `#1F2922` | switch off-track, chips, log panels |
| `card` | `#1A231D` | habit tiles, calendar card, inputs |
| `border` | `#2E3B32` | dividers, calendar outside days |
| `borderStrong` | `#3E4D42` | gradients/edges |
| `white` | `#EDF3EC` | primary text |
| `muted` | `#8E9C90` | secondary text, unlabelled accent |
| `faint` | `#5F6E63` | hints, disabled |
| `accent` | `#2BD673` | active section, switches on, today ring, CTAs |
| `accentDeep` | `#16A34A` | unlabelled habit accents |
| `accentDim` | `#3E7C4F` | (sparingly) |
| `green` | `#86B49A` | "completed at", notification hints, default label colour |
| `orange` | `#D9A45B` | completed section, overdue countdown, destructive delete |
| `red` | `#E0655F` | errors, made-by heart |

Gradients:
- `accentGradient`: `#43D17C → #128A44` (FAB, primary buttons, selected filters, switch on).
- `surfaceGradient`: `#1B2620 → #141C17` (expanded tile panel).
- `backdropGradient`: `#0E1511 → #0A0E0B` (scaffold ambience).

Shadows: `raisedShadow` only on main components — habit tiles, cards, dialogs
and primary CTAs. Chips, preset buttons, switches, label swatches, the "Remind
Me" card and form inputs are flat with a 1px border; do not add glows or drop
shadows to small controls. Use `AppTheme`/`AppColors` instead of Material
elevation.

Label colours are user data (8-swatch palette: green, orange, red, blue
`#3B82F6`, purple `#A855F7`, pink `#EC4899`, cyan `#06B6D4`, yellow `#EAB308`).
A labelled habit's icon, tint, chip and expanded panel all inherit that colour.

---

## 3. Typography & Spacing

- Family: platform default `Roboto`, fallback `Roboto, Arial, Helvetica, sans-serif`.
- App bar title: 21px, `w800`, letter-spacing 0.4.
- Section headers: 13px, `w700`, uppercase, letter-spacing 1.4, with a 4×16px
  accent bar and a count pill.
- Label subheaders: 13px, `w600`, colour dot + count pill + chevron.
- Habit name: 16px `w600` (line height 1.25); subtitle 12.5px; label chip 11px.
- Field labels: 11.5px `w700`, uppercase, letter-spacing 1.1.
- Form headings: 17px `w700`; footer buttons 15px `w800`.
- Countdowns: 12.5px `w700`, `FontFeature.tabularFigures()` so digits do not jitter.
- Page padding: `AppConstants.pagePadding = 16`; list bottom padding
  `fabClearance = 96` so the FAB never covers the last tile.
- Cards: radius 16 (tiles, calendar, day card), 12 (items/chips), 20 (dialogs),
  18 (FAB).

---

## 4. Screen Map

```
HomePage (Scaffold)
├─ AppBar("HabitMe") + list/calendar toggle (AnimatedSwitcher, 200ms scale)
├─ Drawer → Guide page, Manage Labels dialog, Logs page, Import, Export,
│           Support developer (rewarded ad), Made by ItsMe Prince (external)
├─ Body: HabitListView ⇄ CalendarView (260ms fade + 2% slide)
└─ FAB "New habit" (accent gradient) → HabitFormSheet.create
```

### Home — List view (`habit_list_view.dart`)
- Active (accent) and Completed (orange) collapsible sections with counts.
- Empty states: "All caught up. Nothing active right now." /
  "Finished habits show up here." / whole-list empty state with icon and
  "Tap New habit to add your first one."
- Habits are grouped by label, labels A→Z, unlabelled last; each group collapses
  independently. Expansion state persists via `ExpansionPreferences`
  (`section_active`, `section_completed`, `<section>_label_<id>`, `tile_<id>`).
- Tiles animate in with a staggered fade+slide (`AnimatedEntrance`, 50ms per item
  up to 8, capped at 400ms).
- Loading: centred accent spinner. Error: orange icon, "Could not load habits",
  raw error text, Retry button (`ref.invalidate`).

### Habit tile (`habit_tile.dart`)
- Two lines + optional label chip + edit pencil + `AppSwitch`.
- Tapping the tile expands it (220ms cross-fade); the switch and pencil are
  independent hit targets.
- Subtitle logic: recurring → recurrence label (plus "· Next: …" when done);
  one-time → "Scheduled: …" or "Completed …" or "One-time habit".
- Recurring habits carry an `∞` / `N×` pill beside the name (`Complete` with a
  check once a limited series is exhausted); tapping it is not a separate action.
- Expanded panel: label row, due/next/scheduled date (`d MMM, h:mm a`), live
  countdown (accent, orange when overdue), `Repeats:` (the recurrence label),
  `Remaining:` (`Unlimited`, `N of M occurrences`, or `Series complete · M of M`),
  the optional description note, "Completed at" for finished one-time habits,
  and a green "Notifications enabled for this habit" line.
- Swipe left (`endToStart`) reveals a delete icon and asks for confirmation;
  the form's delete button does the same with an explicit dialog.

### Home — Calendar view (`calendar_view.dart`)
- `TableCalendar` month-only, Monday-first, range 2020–2100.
- Each day is a 34×34 half-rounded square filled with a **completion heat**:
  `completed ÷ scheduled` for that day (`hasHeat ? 0.14 + 0.60 × ratio : 0`),
  plus a glow that grows with completion, a 0.55-alpha green ring for today and
  a white ring for the selected day. Duplicate toggles count once, completed is
  capped at scheduled. Date text switches to black on light fills.
- Two toggle chips ("One-Time", "Recurring"); off = grey card, on = accent
  gradient with a check.
- Day card: full date + "N habits", then "Recurring" and "One-Time" categories,
  each item tappable (opens edit) with a toggle icon.

### Habit form (`habit_form_sheet.dart` + `recurrence_picker.dart`)
- Centred `Dialog`, max 480×680, scrollable body, header with accent icon tile
  and title (`Create New Habit` / `Edit Habit`), close button.
- Fields, in order: title (max 100, required), optional description/notes
  (max 300, 2–4 lines), label chips (`None` + labels) with inline **New Label**
  dialog, frequency cards (`Recurring` / `One-Time`), `REPEAT` section,
  `STARTS` (recurring) or `SCHEDULED TIME` (one-time), Remind Me switch.
- `REPEAT` has no duplicate summary header. Presets sit **two per row** (Daily,
  Weekly / Monthly, Every 2 days / Hourly), then two shared 48px rows:
  `Every [n] [unit]` and `Repeat [n] times, then it stops`. The repeat field is
  optional: empty shows `times` and means forever; a value shows
  `times, then it stops` live as the user types. Units: minutes, hours, days,
  months, years.
- All small controls (preset chips, label chips, Every/Repeat rows, start-time
  card, Remind Me) are flat with borders; no shadows or glows.
- Saving state disables the footer button and shows a spinner; success snackbar
  (`Habit created` / `Habit updated`), failure snackbar with the error. Invalid
  interval input shows an inline snackbar instead of silently clamping.
- Edit mode adds a delete icon in the footer.
- Changing type, unit/interval/count, or the recurring start time resets the
  schedule and clears completion; otherwise `nextDueAt` is preserved.
- One-time habits with reminders must be scheduled in the future; past dates are
  allowed but warn ("This target time is set in the past") and block saving when
  notify is on.

### Manage Labels (`manage_labels_sheet.dart`)
- Create row (name field + accent add button) with colour swatches; list of
  labels with dot, name, edit and delete. Edit opens a dialog with name + colour
  palette. Delete confirms that habits remain, just unlabelled.
- List rows share one rhythm: 8px above, 8px around the separator, 16px at the
  bottom, `minHeight: 56`, single-line ellipsised names, 36×36 icon buttons and
  a 14px gap before the colour row.

### Guide page (`guide_page.dart`)
- Scroll of cards: "Why HabitMe Exists" (product story), "Creating a Habit",
  "Modes: Recurring vs One-Time", "Repeat Count" (empty = forever; a value
  stops the series after the last occurrence), "Labels & Views", heatmap rules
  and notification actions. It no longer advertises a 60-reminder warning;
  reminders are planned up to the OS budget and refreshed when the app opens.

### Logs page (`log_viewer_page.dart`)
- Two equal panes: live logs (monospace, selectable, 600-line ring) and the
  computed scheduled reminders (numbered, title + `d MMM, h:mm a`).
- App bar actions: copy all logs + schedule to clipboard, clear logs.
- Three banner ad slots (top, middle, bottom SafeArea). Opening this page also
  shows an interstitial first (triggered from the drawer).

### Drawer (`app_drawer.dart`)
- Header: 52px rounded logo, "HabitMe" (22px `w800`), tagline
  "Keep the habit alive.".
- Rows with icon + title + muted subtitle: Guide, Manage Labels, Logs, Import,
  Export, Support developer.
- Bottom "MADE BY / ItsMe Prince" card with heart icon and outbound arrow.

---

## 5. Interaction Feedback

- Switch: 280ms `AnimatedContainer` + `AnimatedAlign` with
  `easeInOutCubicEmphasized` / `easeInOutBack`; on-state uses the accent
  gradient with a soft green glow.
- Section chevrons rotate 180° in 200–240ms; `AnimatedCrossFade` collapses the
  body (200–240ms).
- Calendar day cells animate fill/glow over 180ms on selection.
- Tiles expand with 220ms cross-fade plus an accent-tinted glow when labelled.
- Snackbars are floating (radius 14) and used for every outcome: created,
  updated, deleted, imported counts, export file name, ad watched/skipped,
  permission errors, load failures. Import/export messages stay up to 8s
  because they can include several counts.
- Haptics: none. Sounds: none.

---

## 6. Copy Rules

- Always sentence case in body copy, uppercase micro-labels.
- Reminders: "Remind Me" + "Notification will be sent" / "No notifications".
- Due language: "Due date:", "Next occurrence:", "Scheduled date:",
  "Completed at:".
- Recurrences read naturally: "Every day", "Every 3 days", "Every hour".
- Empty states are short and encouraging, never scolding.
- The Guide page carries the canonical product story — keep other copy
  consistent with it: habits repeat daily, breaks distort them, HabitMe keeps
  you obedient to your goals and your own betterment.

---

## 7. Accessibility Notes

- Most tappable elements have `tooltip` or `Semantics`-visible labels
  (edit, delete, close, toggle status, copy logs, month toggle).
- Colour is never the only signal: active/completed have distinct section
  titles and counts; due/overdue also change the countdown text.
- Contrast: muted `#8E9C90` on `#1A231D` is the smallest accepted body contrast;
  do not use `faint` for anything a user must read.
- The custom `AppSwitch` is a `GestureDetector`, not a Material `Switch`; it
  relies on the surrounding tile and tooltip for semantics. If you extend it,
  add `Semantics(toggled:)`.
- Text scales with the system font size; the habit form is scrollable and the
  calendar cells are fixed 34px, so very large text can clip inside a day cell.

---

## 8. Website Demo Parity

`website/src/app/components/DemoSection.tsx` is the interactive phone mockup in
`#demo` and imitates this guide. It currently mirrors: repeat-count pill and
`Repeats:` / `Remaining:` rows, limited-series completion, optional description
notes, `Every …` / `Repeat … times, then it stops` rows, two presets per row,
flat label/frequency/reminder controls, and the completion heatmap. It also runs
a 30-second timer after the first interaction and shows an in-phone "download
the app" card. Update the mockup whenever these screens change, so visitors see
the latest app rather than an older design.

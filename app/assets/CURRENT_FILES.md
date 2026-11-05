# HabitMe – Project File Map & Current Status

**Package name:** `habit_me`

## Project Structure

```text
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   │
│   ├── logic/
│   │   ├── providers.dart
│   │   ├── habit_controller.dart
│   │   ├── label_controller.dart
│   │   └── habit_scheduler.dart
│   │
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── duration_format.dart
│   │   └── expansion_preferences.dart
│   │
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   │
│   └── ui/
│       ├── drawer/
│       │   ├── app_drawer.dart
│       │   └── manage_labels_sheet.dart
│       │
│       ├── home/
│       │   ├── habit_list_view.dart
│       │   ├── habit_tile.dart
│       │   ├── calendar_view.dart
│       │   └── home_page.dart
│       │
│       ├── habit_form/
│       │   ├── habit_form_sheet.dart
│       │   └── recurrence_picker.dart
│       │
│       └── widgets/
│           ├── section_header.dart
│           ├── label_subheader.dart
│           └── countdown_text.dart
│
└── data/
    ├── db/
    │   └── app_database.dart
    │
    ├── models/
    │   ├── recurrence.dart
    │   ├── label.dart
    │   ├── habit.dart
    │   └── completion.dart
    │
    ├── repositories/
    │   ├── label_repository.dart
    │   └── habit_repository.dart
    │
    └── services/
        ├── notification_service.dart
        ├── backup_service.dart
        └── sql_codec.dart
```

---

## Detailed Step-by-Step Status

### Step 1 – Project Setup, App Theme & Clean Typography
- [x] Flutter project scaffolded with Riverpod state management.
- [x] Pure dark theme design system (`#000000` pitch black, `#0D0D0D` surfaces, `#141414` cards, `#262626` borders).
- [x] Standard font fix: Explicit font family setup (`Roboto` with fallback to standard sans-serifs) across all themes and text elements for uniform look on all devices.
- [x] Redesigned drawer with rounded logo asset, custom tagline, and "Made by ItsMe Prince" card.

### Step 2 – Database & Data Layer (v2 with Grouping/Labels)
- [x] SQLite database version 2 with foreign keys enabled (`PRAGMA foreign_keys = ON`).
- [x] `labels` table: `id`, `name`, `color`, `created_at`.
- [x] `habits` table: added `label_id` foreign key referencing `labels(id) ON DELETE SET NULL`.
- [x] `completions` table: historical completion logs cascade-deleted on habit deletion.
- [x] Models: `Habit`, `HabitLabel`, `Recurrence`, `Completion` with immutable copyWith and map serialization.
- [x] Repositories: `HabitRepository` and `LabelRepository`.

### Step 3 – Habit Management, Dynamic Colors & Label Sub-Grouping
- [x] Dynamic Label Colors: Tile icons and background tints dynamically adopt the habit's assigned label color; unassigned habits use clean neutral grey (`AppColors.muted`).
- [x] Orange Accent Isolation: Confined strictly to the "Completed" section indicator. All habit subheadings/status strings render in clean white.
- [x] A-Z Label Sub-Grouping: Active and Completed sections group habits into alphabetical label sub-sections with interactive subheaders (`LabelSubheader`).
- [x] Single-Label Constraint: Enforced across creation and updates; switching a label cleanly unbinds the previous one.
- [x] Drawer "Manage Labels" modal dialog: Add labels with 8-color palette, rename, and delete without losing existing habits.
- [x] Toggle / Untoggle: Habits can be marked complete and toggled back to active seamlessly.
- [x] Expansion State Persistence: Remembers expanded/collapsed state of sections, label groups, and individual habit tiles across app re-opens via `ExpansionPreferences`.

### Step 4 – Notifications & Custom Icon
- [x] `flutter_local_notifications` with timezone synchronization.
- [x] Exact and inexact alarm permission flows for Android 13+.
- [x] Official app logo icon (`@mipmap/ic_launcher` synced from `assets/habitme_logo_rounded.png`) used for notifications instead of default Flutter icon.
- [x] Lazy reconciliation on app start and resume (`HabitScheduler.reconcile`).
- [x] Pending notification rolling cap (40 per habit, 60 global).

### Step 5 – Center Popup Habit Creation & Editing
- [x] Modern center popup modal dialog replacing bottom sheet (`maxWidth: 480`).
- [x] Conversational repeat builder with one-tap quick presets (Daily, Weekly, Monthly, Every 2 days, Hourly).
- [x] Inline label picker chip list with quick "+ New Label" creation dialog.
- [x] Grey stone black styling for Recurring / One-time selector cards.
- [x] Clean neutral delete confirmation and action styling.

### Step 6 – Date & Countdown Utilities
- [x] `AppDateUtils`: Relative dates (Today, Tomorrow, Yesterday, date & time).
- [x] `DurationFormat`: Formats remaining time into human-friendly countdowns and handles overdue intervals.
- [x] `CountdownText`: Live per-second ticking countdown widget using `FontFeature.tabularFigures()` to prevent jitter.
- [x] Zero-truncation responsive layouts across compact and tablet viewports.

### Step 7 – Calendar Integration
- [x] `TableCalendar` with dynamic habit occurrence mapping.
- [x] Dynamic label-colored dots on calendar days (matching assigned label colors, or neutral grey if unlabelled; dual-color pill when multiple colors meet).
- [x] Independent filter buttons for One-Time and Recurring in grey-stone black styling.
- [x] Interactive day view showing categorized habits with quick completion toggle and edit sheet access.

### Step 8 – SQL Backup & Import/Export (with Labels)
- [x] Full SQL export capturing `labels`, `habits`, and `completions` in a single transaction.
- [x] Share sheet export (`habitme_backup_<timestamp>.sql`) and file picker restore.
- [x] Safe SQL import parser with column and table whitelisting (never executes raw arbitrary SQL).
- [x] Merge logic: updates existing records by ID and inserts new ones while preserving completion histories.

---

## Current Progress Table

| Step | Description                                         | Status   |
| ---- | --------------------------------------------------- | -------- |
| 1    | Project Setup, Clean Dark Theme & Standard Typography | Complete |
| 2    | Data Layer & SQLite v2 (Labels & Habits)            | Complete |
| 3    | List UI, A-Z Label Groups & Color Sync              | Complete |
| 4    | Scheduling, Boot Receiver & Custom Notification Logo | Complete |
| 5    | Habit Creation Center Popup & Preset Picker         | Complete |
| 6    | Date & Live Countdown Utilities                     | Complete |
| 7    | Calendar View with Dynamic Label Markers            | Complete |
| 8    | SQL Backup & Restore (Full Labels Sync)             | Complete |
| 9    | State Persistence & Responsiveness Verification     | Complete |

# HabitMe – Project File Map & Current Status

**Package name:** `habit_me`  
**Version:** `1.0.0+1` · **Dart SDK:** `^3.13.7` · **Database:** `habitme.db` v2

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
│           ├── countdown_text.dart
│           ├── animated_entrance.dart
│           ├── app_switch.dart
│           └── gradient_border.dart
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
        ├── notification_action_handler.dart
        ├── backup_service.dart
        └── sql_codec.dart

test/
├── scheduling_test.dart
├── backup_codec_test.dart
└── timezone_test.dart
```

---

## Detailed Step-by-Step Status

### Step 1 – Project Setup, App Theme & Clean Typography
- [x] Flutter project scaffolded with Riverpod state management.
- [x] Deep green-black dark theme (`#0A0E0B` canvas, `#141B16` surfaces, `#1A231D` cards, `#2E3B32` borders) tinted toward the logo green, plus `accentGradient` / `surfaceGradient` / `backdropGradient` sheens in `AppColors`.
- [x] Standard font fix: `defaultFontFamily` with an explicit `fontFamilyFallback` (`Roboto`, `Arial`, `Helvetica`, `sans-serif`) set in `AppTheme` for uniform look on all devices.
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
- [x] Label Tint Sweep: the tint runs left → right across roughly the first 60% of the card and fades into the card colour by 84%. Every stop is an opaque `alphaBlend` onto `AppColors.card`, so the fade never dips toward transparency.
- [x] Orange Accent Isolation: Confined strictly to the "Completed" section indicator. All habit subheadings/status strings render in clean white.
- [x] A-Z Label Sub-Grouping: Active and Completed sections group habits into alphabetical label sub-sections with interactive subheaders (`LabelSubheader`).
- [x] Single-Label Constraint: Enforced across creation and updates; switching a label cleanly unbinds the previous one.
- [x] Drawer "Manage Labels" modal dialog: Add labels with 8-color palette, rename, and delete without losing existing habits.
- [x] Toggle / Untoggle: Habits can be marked complete and toggled back to active seamlessly.
- [x] Expansion State Persistence: Remembers expanded/collapsed state of sections, label groups, and individual habit tiles across app re-opens via `ExpansionPreferences`.

### Step 4 – Notifications, Timezone & Custom Icon
- [x] `flutter_local_notifications` 22.3.3 with `timezone` initialised from `data/latest_all.dart` so legacy Android ids (`Asia/Calcutta`, `Asia/Saigon`, `Asia/Dacca`) still resolve.
- [x] Always-resolving zone lookup (`NotificationService._resolveLocation`): device id → bundled database → a fixed-offset `tz.Location` built from `DateTime.now().timeZoneOffset`, named with an id Java can parse (`Asia/Calcutta` or `+05:30`). `tz.local` is never left at UTC, which would offset every reminder by the device's distance from Greenwich.
- [x] All schedules truncated to whole minutes (`HabitScheduler._toMinute`, `Recurrence` second-dropping), so what is displayed, stored and armed is always the same minute.
- [x] Stable FNV-1a `stableNotificationId(key)` per habit + target minute, plus a plan-signature diff in `replaceAll`: unchanged reminders keep their alarm, so a re-sync can never drop one that is about to fire.
- [x] Exact and inexact alarm permission flows for Android 12+; when exact alarms are refused the schedule falls back to `inexactAllowWhileIdle` and the failure is logged with a retry. (`NotificationService.exactAlarmsBlocked` and `openExactAlarmSettings()` are implemented but not surfaced in the UI yet.)
- [x] "Done" action on the notification itself — handled in-app (`onDoneAction`) and in a background isolate (`notification_action_handler.dart`), which writes straight to SQLite and re-syncs without Riverpod.
- [x] Official app logo (`@mipmap/ic_launcher`, `drawable/ic_notification.xml`, `drawable-xxxhdpi/notification_logo.png`) used for notifications instead of the default Flutter icon.
- [x] Reconciliation on app start and resume (`HabitScheduler.reconcile`), plus a foreground wake-up timer so a habit rolls over while the app stays open.
- [x] Rolling reminder window: 60 globally, `min(40, max(3, 60 / recurringCount))` per habit, with one-time reminders given priority when the cap is reached.
- [x] Manifest: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` and the plugin's action / scheduling / boot receivers.

### Step 5 – Center Popup Habit Creation & Editing
- [x] Modern center popup modal dialog replacing bottom sheet (`maxWidth: 480`).
- [x] Conversational repeat builder with one-tap quick presets (Daily, Weekly, Monthly, Every 2 days, Hourly).
- [x] Inline label picker chip list with quick "+ New Label" creation dialog.
- [x] Grey stone black styling for Recurring / One-time selector cards.
- [x] Clean neutral delete confirmation and action styling.

### Step 6 – Date & Countdown Utilities
- [x] `AppDateUtils`: Relative dates (Today, Tomorrow, Yesterday, date & time).
- [x] `DurationFormat.formatCountdown`: full precision with leading zero units dropped — `2h 48m 21s`, `48m 21s`, `42s`, `2d 4h 0m 0s`, `Overdue by 15m 0s`; exact zero renders `Due now` / `Overdue` instead of a frozen `0s`.
- [x] `CountdownText`: live per-second ticking widget that re-reads `DateTime.now()` on every rebuild (the timer only drives rebuilds, no cached clock), forces `FontFeature.tabularFigures()` so digits don't jitter, turns orange once past due, and cancels its timer on dispose so collapsed tiles stop rebuilding.
- [x] In-app rollover: `HabitController.refreshDue()` + a boundary-aligned one-shot timer in `app.dart` (`nextDueAt + 300 ms`, 2 s floor, 5 min ceiling, re-armed by `ref.listen`) so toggling a habit or hitting its minute immediately shows the *next* occurrence instead of sticking on "Due now".
- [x] Zero-truncation responsive layouts across compact and tablet viewports.

### Step 7 – Calendar Integration
- [x] `TableCalendar` with dynamic habit occurrence mapping.
- [x] Dynamic label-colored dots on calendar days (matching assigned label colors, or neutral grey if unlabelled; dual-color pill when multiple colors meet).
- [x] Independent filter buttons for One-Time and Recurring in grey-stone black styling.
- [x] Interactive day view showing categorized habits with quick completion toggle and edit sheet access.

### Step 8 – SQL Backup & Import/Export (with Labels)
- [x] Full SQL export of the raw table rows (never a model round-trip, so no column is silently normalised away): `labels`, `habits` (all 14 columns incl. `anchor_at`, `next_due_at`, `recur_unit`) and `completions`, in dependency order inside one transaction.
- [x] Header carries the marker `-- habit-tracker-backup v1`, an export timestamp and row counts; file named `habitme_backup_<yyyyMMdd_HHmmss>.sql` and handed to the share sheet, with the name reported back in the snackbar.
- [x] Import reads bytes through `PlatformFile.readAsBytes()` first (Android content URIs from Downloads/Drive/Files have a null `path`), falling back to `File(path)` only when a real path exists.
- [x] Whitelist codec (`sql_codec.dart`): table + column whitelist, per-column type coercion, re-validation through `HabitLabel` / `Habit` / `Completion`, and `FormatException`s that quote the offending line number and snippet. Tolerates CRLF/BOM, `INSERT OR …`, multi-row `VALUES` and stray `PRAGMA`; refuses unknown tables/columns, NULLs in required columns and non-backup files.
- [x] Safe merge: existing rows updated by id, new rows inserted with `ConflictAlgorithm.ignore`. `replace` is deliberately avoided because `PRAGMA foreign_keys = ON` would cascade a habit delete into its completion history.
- [x] Foreign-key sanitation: a `label_id` that points at a label the file doesn't contain is nulled (upgraded databases carry the column without the FK constraint) rather than failing the whole import.
- [x] `ImportSummary` reports habits / completions / labels written plus `unlabelledHabits` and `orphanCompletions`, and the drawer shows those repair notes instead of a bare "failed to import".

---

### Step 9 – Persistent State, Motion & Component Polish
- [x] `ExpansionPreferences` persists section, label-group and per-tile expansion across restarts, loaded once in `main()` before the app runs.
- [x] `AnimatedEntrance`: one-shot fade + upward slide used to stagger habit rows in the list (capped so long lists don't cascade forever).
- [x] `AppSwitch`: spring-animated stone-themed toggle replacing the Material switch on habit tiles and the notify field of the form.
- [x] `GradientBorder`: subtle sheen frame around elevated panels (the expanded tile detail block).
- [x] Expanded tile detail shows the assigned label, the due / scheduled date with the live countdown (or the completed time, or "No specific target time set"), and a notifications-enabled note — inside a `GradientBorder` panel tinted with the label colour, with `Expanded` text so nothing is ellipsis-truncated.

### Step 10 – Verification & Regression Tests
- [x] `test/scheduling_test.dart`: second-free schedule creation, `nextAfter` strictness (an occurrence exactly on `now` still rolls forward), stable notification ids, and the exact countdown strings.
- [x] `test/backup_codec_test.dart`: round-trip of every column, quote/emoji/semicolon escaping, CRLF + `INSERT OR REPLACE` + multi-row `VALUES` tolerance, and rejection of non-backup files, unknown tables/columns and required-column NULLs.
- [x] `test/timezone_test.dart`: legacy Android ids resolve with the right offset, and a 20:00 reminder in `Asia/Calcutta` maps to the 14:30 UTC instant.
- [x] `dart format lib test` and `flutter analyze` clean; `flutter test` → 18/18 passing.

---

## Current Progress Table

| Step | Description                                         | Status   |
| ---- | --------------------------------------------------- | -------- |
| 1    | Project Setup, Green-Black Theme & Standard Typography | Complete |
| 2    | Data Layer & SQLite v2 (Labels & Habits)            | Complete |
| 3    | List UI, A-Z Label Groups & Color Sync              | Complete |
| 4    | Scheduling, Timezone, Boot Receiver & Notification Actions | Complete |
| 5    | Habit Creation Center Popup & Preset Picker         | Complete |
| 6    | Date & Live Countdown Utilities                     | Complete |
| 7    | Calendar View with Dynamic Label Markers            | Complete |
| 8    | SQL Backup & Restore (Full Labels Sync)             | Complete |
| 9    | State Persistence, Motion & Responsiveness          | Complete |
| 10   | Regression Tests & Static Analysis                  | Complete |

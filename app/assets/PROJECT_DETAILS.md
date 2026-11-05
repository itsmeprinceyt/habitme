# HabitMe – Comprehensive Project Handout & Architecture Spec

## 1. Executive Summary & Rules

- **Application Name:** HabitMe
- **Package Name:** `habit_me`
- **Architecture Philosophy:** 100% Offline, Local-First, Zero Arbitrary Cloud Sync, Deep Green-Black Minimalist UI.
- **Theme Palette (deep green-black, tinted toward the logo green — see `AppColors`):**
  - Canvas / Scaffold: `#0A0E0B`
  - Surface: `#141B16` · Surface Light: `#1F2922`
  - Cards: `#1A231D`
  - Borders: `#2E3B32` (strong: `#3E4D42`)
  - Text: `#EDF3EC`, Muted `#8E9C90`, Faint `#5F6E63`
  - Accents: Primary Green `#2BD673` (deep `#16A34A`, dim `#3E7C4F`); semantic Green `#86B49A`, Completed Orange `#D9A45B`, Danger Red `#E0655F`
  - Gradients: `accentGradient` (`#43D17C` → `#128A44`), `surfaceGradient` for panels, `backdropGradient` for the scaffold
- **Typography:** platform `defaultFontFamily` with an explicit fallback chain (`Roboto`, `Arial`, `Helvetica`, `sans-serif`) set in `AppTheme`; ticking digits use `FontFeature.tabularFigures()` so they never jitter.
- **Iconography & Notifications:** rounded logo asset (`assets/habitme_logo_rounded.png`) drives the launcher icon (`@mipmap/ic_launcher`); notifications use `drawable/ic_notification.xml` (small) and `drawable-xxxhdpi/notification_logo.png` (large).

---

## 2. Technical Stack

- **Framework:** Flutter (Material 3, dark only), Dart SDK `^3.13.7`, app version `1.0.0+1`
- **State Management:** `flutter_riverpod` 3.x (`AsyncNotifier` / `Notifier`, `ref.listen` for schedule re-arming)
- **Database:** SQLite (`sqflite` ^2.4.5, database `habitme.db` v2) with foreign keys enabled (`PRAGMA foreign_keys = ON`)
- **Background & Notifications:** `flutter_local_notifications` ^22.3.3, `timezone` ^0.11.2 (initialised from the compact `data/latest.dart`, plus a legacy-id alias table), `flutter_timezone` ^5.1.1
- **Calendar:** `table_calendar` ^3.3.0
- **File & Share Handling:** `path_provider` ^2.1.6, `file_picker` ^13.3.2, `share_plus` ^13.3.1
- **Utilities:** `intl` ^0.20.3, `uuid` ^4.6.0, `url_launcher` ^6.3.1
- **Tooling:** `flutter_lints` ^6.0.0, `flutter_launcher_icons` ^0.14.4

---

## 3. Database Schema (Version 2)

### Table: `labels`
```sql
CREATE TABLE labels (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color INTEGER,
  created_at INTEGER NOT NULL
);
```

### Table: `habits`
```sql
CREATE TABLE habits (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  label_id TEXT,
  is_recurring INTEGER NOT NULL DEFAULT 0,
  recur_unit TEXT,
  recur_interval INTEGER,
  notify INTEGER NOT NULL DEFAULT 0,
  is_done INTEGER NOT NULL DEFAULT 0,
  one_time_at INTEGER,
  anchor_at INTEGER NOT NULL,
  next_due_at INTEGER,
  completed_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (label_id) REFERENCES labels(id) ON DELETE SET NULL
);
CREATE INDEX idx_habits_label ON habits(label_id);
```

### Table: `completions`
```sql
CREATE TABLE completions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id TEXT NOT NULL,
  completed_at INTEGER NOT NULL,
  FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
);
CREATE INDEX idx_completions_habit ON completions(habit_id);
CREATE INDEX idx_completions_at ON completions(completed_at);
```

### Schema notes that affect the code
- **v1 → v2 upgrade adds `label_id` without the foreign key** (`ALTER TABLE` cannot attach one), so databases created at v1 accept a `label_id` that points at nothing while fresh installs reject it. The backup import therefore nulls unknown `label_id` values instead of trusting the constraint.
- `completions.id` is autoincrement and is **not** written to a backup; only `habit_id` + `completed_at` are, so re-import never collides on a primary key.
- All timestamps are stored as millisecond epochs (`INTEGER`), and every scheduled time is truncated to the whole minute before it is stored or armed.

---

## 4. Key Functional Features

### 4.1. Labels & Grouping Architecture
- **Single-Label Binding:** A habit can belong to at most one label. Assigning a new label unbinds the previous one.
- **Dynamic Color Sync:** If a habit has an assigned label, the habit icon and background tint automatically inherit that label's color. Unlabelled habits use the muted grey `AppColors.muted` (`#8E9C90`).
- **Label Tint Sweep:** the coloured card background runs `centerLeft → centerRight`, holding the tint for the first ~60% and fading into `AppColors.card` by 84%. All four stops are opaque `Color.alphaBlend(tint.withValues(alpha), AppColors.card)` blends, so the fade lands on the card instead of dipping toward transparency.
- **A-Z Label Sub-Grouping:** On the home page, Active and Completed sections group habits into alphabetical label subsections (`LabelSubheader`), with an unassigned bucket for unlabelled items.
- **Drawer Label Management:** Users can manage labels directly from the drawer: create labels with an 8-color palette, rename, or delete without deleting the underlying habits.

### 4.2. Persistent Expansion State
- Managed by `ExpansionPreferences`:
  - Remembers whether Active or Completed sections are open.
  - Remembers which label subsections are open.
  - Remembers individual habit tile expanded states.
  - States persist across application closures and re-launches.

### 4.3. Habit Scheduling, Reset Lifecycle & Notifications
- **Minute precision everywhere:** `Habit.create` and `Recurrence` drop seconds, `HabitScheduler._toMinute` truncates one-time targets, so DB state, countdown display and the armed alarm always describe the same minute.
- **Reconciliation:** `HabitScheduler.reconcile(now)` runs on startup and on `AppLifecycleState.resumed`; when `next_due_at <= now` the recurring habit resets to active and rolls to `recurrence.nextAfter(anchorAt, now)`, which is strictly in the future (an occurrence exactly on `now` still advances). Re-arming reminders is fire-and-forget (`unawaited(sync(...))`) - the habit list is never made to wait on, or fail because of, a platform channel.
- **Foreground wake-up:** `app.dart` arms a one-shot `Timer` for the soonest `nextDueAt + 300 ms` (2 s floor, 5 min ceiling), re-armed by `ref.listen(habitControllerProvider)` after every list change, calling `HabitController.refreshDue()`. This is what keeps a countdown rolling while the app stays open.
- **Reminder identity:** `stableNotificationId` (FNV-1a, positive 31-bit) hashes `habit.id@epochMs`, so an unchanged occurrence keeps its alarm across re-syncs; `replaceAll` diffs the plan by signature and only adds/removes what actually changed.
- **Rolling window:** 60 reminders globally, `min(40, max(3, 60 / recurringCount))` per habit; one-time reminders are queued first because they can't be regenerated.
- **Timezone:** `tzdata.initializeTimeZones()` runs once, lazily, from the compact `data/latest.dart`. That table only carries canonical names, while Android reports ids from its own legacy table (`Asia/Calcutta`, `Asia/Saigon`, `Asia/Dacca`), so a small `_legacyZoneAliases` map bridges the handful of old spellings devices actually report. `NotificationService.resolveZone(deviceId)` then: looks the id up directly, then via the alias table, and otherwise builds a fixed-offset `tz.Location` from `DateTime.now().timeZoneOffset`. A resolved zone is re-labelled with the device's own id, because that is what Java's `ZoneId.of` accepts. `tz.local` must never stay at UTC: `zonedSchedule` sends wall-clock fields *plus the zone name* to the OS, so a UTC fallback fires every reminder off by the device's distance from Greenwich (e.g. +05:30). `data/latest_all.dart` was tried and rejected - parsing the full tzdb on the start-up path is too heavy. The full tzdb is never loaded before the first frame; `main()` kicks `NotificationService.instance.init()` off with `unawaited`, and `init()` is single-flight (concurrent callers share one attempt, a failed attempt is not cached, so the next caller retries).
- **Delivery mode:** `exactAllowWhileIdle` when permitted (inexact alarms are batched by Doze, which is what makes reminders arrive minutes late and all at once); a rejected exact schedule is logged and retried in `inexactAllowWhileIdle`. `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM` + `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` are declared, and the plugin's action, scheduling and boot receivers are registered. `exactAlarmsBlocked` and `openExactAlarmSettings()` are exposed for a future UI warning.
- **Notification actions:** a "Done" action marks the habit complete from the shade — `onDoneAction` when the app is alive, `habitNotificationBackgroundHandler` in a background isolate (direct `HabitRepository` + `HabitScheduler.sync`, no Riverpod).

### 4.4. Countdown Display
- `DurationFormat.formatCountdown` drops leading zero units but keeps interior ones: `2h 48m 21s`, `48m 21s`, `42s`, `2d 4h 0m 0s`, `Overdue by 15m 0s`; an exact zero gap shows `Due now` and an overdue-with-no-remainder shows `Overdue` so the label is never a frozen `0s`.
- `CountdownText` re-reads `DateTime.now()` on every 1-second tick (no cached clock value) and is used inside the expanded tile's `AnimatedCrossFade` section.

### 4.5. Calendar View & Filtering
- Dynamic markers: Date markers match the assigned label colors of habits occurring on that day (neutral grey for unassigned; dual-colored pill when multiple label colors meet).
- Independent One-Time and Recurring filter chips styled in grey stone black.
- Interactive day view with direct completion toggling and edit access.

### 4.6. SQL Backup & Import/Export
- Export reads the **raw rows** from all three tables (labels alphabetically, habits by `created_at`, completions by `completed_at`) and writes them through `SqlCodec.encode`, so no field is normalised away on the way out; the method returns the file name for the UI to confirm.
- File format: marker `-- habit-tracker-backup v1`, export timestamp, row-count comment, `BEGIN TRANSACTION;` then one `INSERT INTO <table> (<all columns>) VALUES (…);` per row in dependency order, `COMMIT;`.
- `SqlCodec.decode` never executes SQL, and never builds a model object either. It parses statements positionally against `_schemas`, whitelists tables and columns, coerces each value to the declared column type and rejects a NULL in a `required: true` column, throwing `FormatException` quoting the line number and snippet. Comments, `BEGIN`/`COMMIT`, `PRAGMA`, CRLF/BOM, `INSERT OR …` and multi-row `VALUES` are all handled. The result is `ParsedBackup`, plain column-keyed maps ready to write.
- Import reads the picked file with `PlatformFile.readAsBytes()` (Android content URIs expose a null `path`) and merges inside one transaction: labels upserted, habits upserted after nulling any `label_id` the file doesn't define, completions inserted only for habits that exist and only when the `habit_id@completed_at` pair isn't already present.
- Writes use `ConflictAlgorithm.ignore`, never `replace`: under `PRAGMA foreign_keys = ON` a replace is a delete + insert, which would cascade away a habit's completion history.
- `ImportSummary` (`habits`, `completions`, `labels`, `orphanCompletions`, `unlabelledHabits`) drives the drawer's honest snackbars, which also print the exact failure reason instead of a generic "failed to import".

### 4.7. Start-Up And Load Resilience
The habit list is the app's critical path, so nothing that can hang or throw is allowed to sit on it:
- `HabitController.build()` → `HabitScheduler.reconcile()` only reads and rolls the database. Notification init and re-arming are `unawaited`, and `sync()` catches/logs every failure itself.
- `Habit.fromMap` is deliberately tolerant: `_flag()` accepts `1`/`true`/anything else, timestamps fall back (`anchorAt` → `createdAt` → now, `createdAt` ↔ `updatedAt`), epochs may arrive as `int`, `num` or text, and a `recur_interval` of `0` or less is read as a one-time habit rather than tripping `Recurrence`'s `assert(interval > 0)` - which is live in debug builds and would otherwise kill the whole load.
- `HabitRepository.getAll()` parses row by row and skips (with `debugPrint`) an unreadable row instead of losing the rest of the list.
- `Recurrence._step` floors the interval at 1 for the `_estimate` divisions and `occursOnDate` modulos, so a bad stored interval can neither divide by zero nor make `_nextIndex`'s walk loop forever - the release-build version of the same bug, which showed up as a permanent spinner rather than an error.
- The list's error state shows the real error text plus a **Retry** button (`ref.invalidate(habitControllerProvider)`), and `build()` logs `Habit load failed: …` with a stack, so a device-only failure is diagnosable from the screen instead of being swallowed by a generic message.

---

## 5. File Map

```text
lib/
├── main.dart                          # Entry point: system UI style, expansion-state + notification init
├── app.dart                           # Root MaterialApp, dark theme, lifecycle reconcile, foreground due-timer
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # DB name/version, table + column names, backup marker, branding
│   ├── logic/
│   │   ├── habit_controller.dart      # Habit AsyncNotifier (CRUD + reconcile/refreshDue/markDoneFromNotification)
│   │   ├── label_controller.dart      # Label AsyncNotifier
│   │   ├── habit_scheduler.dart       # Reconcile, reminder planning, minute truncation, caps
│   │   └── providers.dart             # Repositories, services, derived active/completed, HomeViewMode
│   ├── utils/
│   │   ├── date_utils.dart            # Human relative dates & formatters
│   │   ├── duration_format.dart       # Left-trimmed countdown + approximate/overdue strings
│   │   └── expansion_preferences.dart # Persistent UI expansion state storage
│   ├── theme/
│   │   ├── app_colors.dart            # Deep green-black palette, accent/surface/backdrop gradients
│   │   └── app_theme.dart             # Unified theme, font fallback, component styling
│   └── ui/
│       ├── drawer/
│       │   ├── app_drawer.dart        # Manage Labels, Import, Export, credit card, error/repair snackbars
│       │   └── manage_labels_sheet.dart # Color palette & label CRUD dialog
│       ├── home/
│       │   ├── home_page.dart         # Scaffold with toggle between List and Calendar
│       │   ├── habit_list_view.dart   # Grouped A-Z habit list with entrance stagger + expansion state
│       │   ├── habit_tile.dart        # Expandable card, label tint sweep, countdown, AppSwitch detail
│       │   └── calendar_view.dart     # Monthly calendar with label-colored markers & filters
│       ├── habit_form/
│       │   ├── habit_form_sheet.dart  # Center popup dialog for habit creation/editing
│       │   └── recurrence_picker.dart # Quick recurrence presets & conversational repeat builder
│       └── widgets/
│           ├── section_header.dart    # Collapsible Active / Completed headers
│           ├── label_subheader.dart   # Collapsible label category headers
│           ├── countdown_text.dart    # Ticking tabular-figure countdown timer widget
│           ├── animated_entrance.dart # One-shot fade + slide stagger for list rows
│           ├── app_switch.dart        # Spring-animated stone-themed toggle
│           └── gradient_border.dart   # Sheen frame for elevated panels
│
└── data/
    ├── db/
    │   └── app_database.dart          # SQLite v2 open, onCreate schema/indexes, v1 → v2 migration
    ├── models/
    │   ├── label.dart                 # HabitLabel data model + column names
    │   ├── habit.dart                 # Habit model with labelId binding, column names & tolerant fromMap
    │   ├── recurrence.dart            # Unit/interval occurrence maths (strictly-after, second-free, step floored at 1)
    │   └── completion.dart            # Historical completion record model
    ├── repositories/
    │   ├── label_repository.dart      # SQLite Label CRUD (delete unlinks habits)
    │   └── habit_repository.dart      # SQLite Habit CRUD, per-row-tolerant getAll, toggleDone & completion ranges
    └── services/
        ├── notification_service.dart  # Single-flight init, zone aliasing/resolution, stable ids, diff sync, permissions
        ├── notification_action_handler.dart # Background-isolate handler for the Done action
        ├── backup_service.dart        # Raw-row export, content-URI-safe read, FK-sanitizing upsert merge
        └── sql_codec.dart             # Whitelist codec: encode dump / decode + coerce + line-numbered errors

test/
├── scheduling_test.dart               # Minute precision, nextAfter strictness, stable ids, countdown strings, tolerant row parsing
├── backup_codec_test.dart             # Round-trip, escaping, format tolerance, validation rejections
└── timezone_test.dart                 # Legacy Android zone ids resolve; wall clock maps to the right instant
```

---

## 6. Verification

```powershell
dart format lib test
flutter analyze          # expected: No issues found
flutter test             # expected: 24/24 passing
flutter build apk --debug
```

Manual device checks that matter:
1. Cold-start on a real device with legacy habits and notifications blocked → the list renders; it must never sit on a spinner or show "Could not load habits".
2. Create a habit recurring every few minutes → while the app stays open, the countdown must roll to the next occurrence instead of sitting at `Due now`.
3. Let a reminder fire with the app backgrounded → it arrives on the minute, not minutes late or batched.
4. Tap **Done** on the notification → habit completes and `next_due_at` advances; same from the terminated-app state.
5. **Export** → note the file name in the snackbar → **Import** that same file → counts reported, completion history intact, no `FOREIGN KEY constraint failed`.

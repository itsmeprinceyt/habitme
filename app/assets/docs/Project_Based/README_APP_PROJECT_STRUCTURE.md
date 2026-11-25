# HabitMe Flutter App — Project Structure

> Project-specific documentation for the Android app in `app/`. Source of truth
> is the code; `app/assets/PROJECT_DETAILS.md` and `CURRENT_FILES.md` are older
> notes and have drifted in places (differences are called out at the end).
>
> Last updated: 25 November 2026

---

## 1. Stack

| Area | Choice |
| --- | --- |
| Framework | Flutter, Dart SDK `^3.13.7`, Material 3, **dark theme only** |
| App id / version | `com.itsmeprince.habitme`, `1.0.0+1` |
| State | `flutter_riverpod` ^3.4.3 (`AsyncNotifier`, `Notifier`, `Provider`) |
| Persistence | `sqflite` ^2.4.5 — `habitme.db`, schema v4 (`description`, `recur_count`) |
| Notifications | `flutter_local_notifications` ^22.3.3 + `timezone` ^0.11.2 |
| Calendar | `table_calendar` ^3.3.0 |
| Files | `path_provider` ^2.1.6, `file_picker` ^13.3.2, `share_plus` ^13.3.1 |
| Misc | `csv`, `intl` ^0.20.3, `uuid` ^4.6.0, `url_launcher` ^6.3.1 |
| Ads | `unity_ads_plugin` ^0.6.0 (banner, interstitial, rewarded) |
| Tooling | `flutter_lints` ^6.0.0, `flutter_launcher_icons` ^0.14.4 |

No backend, no auth, no cloud sync. Network access exists only for Unity Ads.

---

## 2. Layering

```
main.dart            bootstrap: bindings, log tee, prefs, notification/ads warm-up
app.dart             MaterialApp + lifecycle + foreground due-timer
core/
  constants/         app constants (tagline, DB name, table names, Unity ids)
  logic/             Riverpod providers, controllers, scheduler
  theme/             AppColors (palette) + AppTheme (component themes)
  ui/                screens, sheets, pages, reusable widgets
  utils/             logging, date/duration formatting, expansion prefs
data/
  db/                AppDatabase (open, schema, migration)
  models/            Habit, HabitLabel, Completion, Recurrence
  repositories/      HabitRepository, LabelRepository (all SQL)
  services/          notifications, ads, backup, SQL codec, notification actions
test/                scheduler, scheduling/format, backup codec
```

Rules implied by the code:
- **UI never writes SQL.** Screens call controller methods; controllers call
  repositories; only repositories touch `sqflite`.
- **Scheduling is separate from state.** `HabitScheduler` owns the reminder plan
  and notification sync; `HabitController` owns the in-memory habit list.
- **Platform failures never block the UI.** Notification sync is fire-and-forget
  and catches/logs its own errors.

---

## 3. File Tree (42 lib Dart files + 5 test suites)

```
app/
├─ pubspec.yaml
├─ README.md                          (placeholder, 2 bytes)
├─ assets/
│  ├─ habitme_logo.png
│  ├─ habitme_logo_rounded.png        launcher icon source
│  ├─ habitme_logo_svg.svg
│  ├─ PROJECT_DETAILS.md              earlier architecture notes (partly stale)
│  ├─ CURRENT_FILES.md                earlier file-by-file checklist
│  └─ docs/                           README.md (rules) + Project_Based/ (app docs)
├─ android/
│  └─ app/src/main/AndroidManifest.xml   permissions + notification receivers
├─ lib/
│  ├─ main.dart
│  ├─ app.dart
│  ├─ core/
│  │  ├─ constants/app_constants.dart
│  │  ├─ logic/
│  │  │  ├─ providers.dart            all Riverpod providers + view mode
│  │  │  ├─ habit_controller.dart     habit list mutations + notification sync
│  │  │  ├─ label_controller.dart     label CRUD
│  │  │  └─ habit_scheduler.dart      reconcile, plan, sync, fired handling
│  │  ├─ theme/
│  │  │  ├─ app_colors.dart
│  │  │  └─ app_theme.dart
│  │  ├─ ui/
│  │  │  ├─ home/
│  │  │  │  ├─ home_page.dart         Scaffold, view toggle, drawer, FAB
│  │  │  │  ├─ habit_list_view.dart   Active/Completed + label groups
│  │  │  │  ├─ habit_tile.dart        tile, expand, countdown, swipe delete
│  │  │  │  ├─ calendar_view.dart     heatmap month + day detail
│  │  │  │  └─ log_viewer_page.dart   live logs + scheduled plan + ads
│  │  │  ├─ habit_form/
│  │  │  │  ├─ habit_form_sheet.dart  create/edit dialog
│  │  │  │  └─ recurrence_picker.dart presets + custom interval/unit
│  │  │  ├─ drawer/
│  │  │  │  ├─ app_drawer.dart        menu, import/export, support, made-by
│  │  │  │  ├─ manage_labels_sheet.dart
│  │  │  │  └─ guide_page.dart        "Why HabitMe exists" + how-to
│  │  │  └─ widgets/
│  │  │     ├─ app_switch.dart
│  │  │     ├─ countdown_text.dart
│  │  │     ├─ section_header.dart
│  │  │     ├─ label_subheader.dart
│  │  │     ├─ animated_entrance.dart (AnimatedEntrance + ShimmerSweep)
│  │  │     └─ ad_banner.dart
│  │     └─ utils/
│  │        ├─ app_log.dart              in-memory ring buffer (600 lines)
│  │        ├─ calendar_heat.dart        completed ÷ scheduled day progress
│  │        ├─ date_utils.dart
│  │        ├─ duration_format.dart
│  │        └─ expansion_preferences.dart
│  └─ data/
│     ├─ db/app_database.dart
│     ├─ models/{habit,label,completion,recurrence}.dart
│     ├─ repositories/{habit,label}_repository.dart
│     └─ services/
│        ├─ notification_service.dart
│        ├─ notification_action_handler.dart
│        ├─ ads_service.dart
│        ├─ backup_service.dart
│        └─ sql_codec.dart
└─ test/
   ├─ habit_scheduler_test.dart        plan caps, fairness, stable keys, oversubscription
   ├─ recurrence_test.dart             limited series, remaining, clamping, isFinished
   ├─ calendar_heat_test.dart          day ratios, duplicate completion capping
   ├─ scheduling_test.dart             minute precision, ids, countdown, tolerant parsing
   └─ backup_codec_test.dart           round trip, ordering, validation, edge parsing
```

---

## 4. Entry Points & Boot Order

`main()`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Replace `debugPrint` with a tee that also appends to `AppLog` (ring buffer
   used by the Logs page).
3. Force a dark system UI overlay style (transparent status bar, black nav bar).
4. `ExpansionPreferences.load()` inside try/catch (UI prefs, non-fatal).
5. `unawaited(NotificationService.init())` — never delays the first frame.
6. `AdsService.instance.init()` — Unity init, then preloads interstitial and
   rewarded.
7. `runApp(ProviderScope(child: HabitApp()))`.

`HabitApp` (`app.dart`, `ConsumerStatefulWidget`):
- Registers `WidgetsBindingObserver` and notification callbacks
  (`onDoneAction` → `markDoneFromNotification`, `onFired` → scheduler).
- Post-frame: `checkPermissionsOnLaunch()`.
- Arms a one-shot **due ticker** and re-arms it on every habit-list change.
- On resume: `reconcileAndSync()`.
- Builds `MaterialApp(title: HabitMe, theme: AppTheme.dark, themeMode: dark,
  home: HomePage())`.

`HomePage` → `HabitListView` / `CalendarView`, and `HabitController.build()`
runs `HabitScheduler.reconcile(now)` which loads habits, rolls due ones, and
kicks off a background notification sync.

---

## 5. Providers (`core/logic/providers.dart`)

| Provider | Type | Purpose |
| --- | --- | --- |
| `homeViewModeProvider` | `NotifierProvider<HomeViewModeNotifier, HomeViewMode>` | list ↔ calendar toggle |
| `habitRepositoryProvider` | `Provider` | repository over the singleton DB |
| `labelRepositoryProvider` | `Provider` | repository over the singleton DB |
| `habitControllerProvider` | `AsyncNotifierProvider<HabitController, List<Habit>>` | source of truth for habits |
| `labelControllerProvider` | `AsyncNotifierProvider<LabelController, List<HabitLabel>>` | labels |
| `activeHabitsProvider` | `Provider<List<Habit>>` | `!isDone`, DB order |
| `completedHabitsProvider` | `Provider<List<Habit>>` | `isDone`, sorted by completion desc |
| `habitSchedulerProvider` | `Provider<HabitScheduler>` | plan/sync service |
| `notificationServiceProvider` | `Provider<NotificationService>` | singleton wrapper |
| `backupServiceProvider` | `Provider<BackupService>` | export/import |

`HabitController` methods: `toggle(id)`, `markDoneFromNotification(id)`,
`add(habit)`, `updateHabit(habit)`, `delete(id)`, `reconcile()`,
`reconcileAndSync()`, `refreshDue()`.

`LabelController` methods: `reload()`, `addLabel(name, color)`,
`updateLabel(label)`, `deleteLabel(id)`. Label changes re-run
`reconcile()` so habit tiles pick up new colours.

---

## 6. Platform Configuration

`android/app/src/main/AndroidManifest.xml` declares:
- `POST_NOTIFICATIONS` (Android 13+ runtime permission)
- `SCHEDULE_EXACT_ALARM` (Android 12+) and `USE_EXACT_ALARM` (Android 13+ alarm app)
- `WAKE_LOCK`, `VIBRATE`
- `RECEIVE_BOOT_COMPLETED` (restore alarms after reboot/update)
- `INTERNET` — required by Unity Ads; the tracker itself works offline
- Receivers: plugin action receiver, scheduled-notification receiver, boot
  receiver (exported, listens for `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`,
  quick-boot actions)
- `<queries>` for `PROCESS_TEXT` and https intents (url_launcher)

Gradle: namespace/applicationId `com.itsmeprince.habitme`, Java 17, core library
desugaring on, multiDex on, release currently signed with the debug key
(`TODO` in `build.gradle.kts`).

---

## 7. Tests

```bash
cd app
flutter test                     # all five suites, 48 tests
flutter test test/habit_scheduler_test.dart
```

- `habit_scheduler_test.dart` — fake repo + fake notification service; verifies
  no starvation for a 2-minute habit next to a daily one, global cap, per-habit
  quota, stable keys across sub-minute clock shifts, one-time reminder rules,
  oversubscription priority (not-done first), `onReminderFired` behaviour, and
  that a limited series stops producing occurrences after its last repeat.
- `recurrence_test.dart` — `count` limits `nextAfter` (returns `null` when
  finished), `remaining`, `isFinished`, no `upcoming` beyond the count.
- `calendar_heat_test.dart` — completed ÷ scheduled ratio, duplicate toggles
  counted once, completed never exceeds scheduled.
- `scheduling_test.dart` — minute truncation, `nextAfter` strictly future,
  FNV-1a id stability, countdown strings, tolerant `Habit.fromMap` (zero
  interval, NULL flags, text epochs).
- `backup_codec_test.dart` — full round trip, dump ordering, idempotent
  re-import, CRLF/`INSERT OR REPLACE`/multi-row VALUES, and rejected files
  (wrong marker, unknown table/column, NULL required, empty backup).

---

## 8. Drift vs. Older Notes

`app/assets/PROJECT_DETAILS.md` and `CURRENT_FILES.md` are useful but not exact:
- They mention `flutter_timezone` — it is **not** in `pubspec.yaml`.
- They describe the per-habit reminder cap as
  `min(40, max(3, 60 / count))`; the current `_plan` instead reserves one
  occurrence per notifying habit and shares the leftover budget evenly
  (`max(1, remaining ~/ notifyingCount)`), with `perHabitCap = 40` used only to
  bound `Recurrence.upcoming`.
- They say `exactAllowWhileIdle`; the code now schedules with
  `AndroidScheduleMode.alarmClock` when exact alarms are allowed and falls back
  to `inexactAllowWhileIdle`.
- They describe calendar markers per label colour; the code renders a numeric
  **heatmap** cell instead (`markersMaxCount: 0`).
- `AdBanner` is only mounted on the Logs page, not on Home.
- `HabitScheduler.isRecurrenceTooFrequent` and `canAddNotifyingHabit` are
  defined but not surfaced in the form UI.

---

## 9. Current Data & UI Snapshot (25 November 2026)

- **Schema v4.** `habits` now also has `description TEXT` (v3) and
  `recur_count INTEGER` (v4). Both are nullable; existing rows keep working
  (no note, repeats forever). Backup/import includes both columns.
- **Repeat count.** `Recurrence` carries an optional `count`. Null = forever;
  otherwise the series produces exactly that many occurrences. `nextAfter`
  returns `null` once the series is finished, `remaining()` and `isFinished()`
  expose the limit, and `upcoming()` never returns more than the count allows.
  `HabitScheduler.reconcile` stops rolling a finished series.
- **Habit form.** Title, optional 300-character description, label chips,
  Recurring/One-Time cards, then a `REPEAT` section: two presets per row,
  `Every [n] [unit]`, optional `Repeat [n] times, then it stops`, then
  `STARTS` / `SCHEDULED TIME` and the Remind Me switch. Small controls are flat
  and bordered; dropshadows are reserved for tiles/cards/primary CTAs.
- **Habit tile.** Recurring habits show an `∞` or `N×` pill beside the name and
  expanded `Repeats:` / `Remaining:` rows; limited series show `Complete` once
  exhausted. Description notes appear inside the expanded panel.
- **Calendar.** The heatmap is completion-based (`completed ÷ scheduled`), not
  planned-count-based; a habit counts once per day.
- **Notifications.** Seen reminders are cleared with `clearDelivered()` on
  launch and on resume, so the shade only keeps fresh reminders.
- **Website demo.** `website/src/app/components/DemoSection.tsx` mirrors this
  snapshot: repeat-count pill + rows, description, limited-series completion,
  flat controls — plus a 30-second interaction timer that shows an in-phone
  "download the app" card. Keep it in sync when these screens change.

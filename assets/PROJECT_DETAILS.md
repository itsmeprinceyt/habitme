# Habit Tracker (Flutter) - Handoff Spec

Paste this whole file to any AI before asking it to continue. Update the Progress section after every working session.

## Rules for the AI

- Developer is experienced in Flutter/Dart. No language explanations.
- No code comments in output.
- Prefer surgical, minimal-diff changes. Give full paste-ready files only when a full rewrite is requested.
- App is 100% offline. No network packages, no INTERNET permission in the release manifest.
- Theme: black, white, green, orange only.

## Product

- Local-only habit tracker. List page + calendar toggle (top-right icon). Drawer with Import, Export, Made by tile.
- Habit fields: name, done toggle, type (one-time | recurring), recurrence rule, notify flag (one-time only, optional).
- One-time: toggle on -> moves to Completed permanently.
- Recurring: toggle on -> moves to Completed with a live countdown to next cycle. When the cycle time hits, toggle resets to off, habit returns to Active, notification fires.
- Recurrence units: minutes, hours, daily, nth day, monthly, yearly (custom interval N per unit).
- Backup: export/import CSV and SQL dump. Import replaces or merges by habit id.

## Stack

- State: flutter_riverpod
- DB: sqflite + path
- Notifications: flutter_local_notifications, timezone, flutter_timezone
- Calendar: table_calendar
- Files: path_provider, file_picker, share_plus, csv
- Misc: intl, uuid

## Folder structure

```
lib/
  main.dart
  app.dart
  core/
    theme/app_colors.dart
    theme/app_theme.dart
    constants/app_constants.dart
    utils/date_utils.dart
    utils/duration_format.dart
  data/
    models/habit.dart
    models/recurrence.dart
    db/app_database.dart
    repositories/habit_repository.dart
    services/notification_service.dart
    services/backup_service.dart
    services/csv_codec.dart
    services/sql_codec.dart
  logic/
    habit_scheduler.dart
    providers.dart
    habit_controller.dart
  ui/
    home/home_page.dart
    home/habit_list_view.dart
    home/habit_tile.dart
    home/calendar_view.dart
    habit_form/habit_form_sheet.dart
    habit_form/recurrence_picker.dart
    drawer/app_drawer.dart
    widgets/countdown_text.dart
    widgets/section_header.dart
```

## Data model

habits table:

- id TEXT PRIMARY KEY (uuid)
- name TEXT NOT NULL
- is_recurring INTEGER (0/1)
- recur_unit TEXT (minutes|hours|days|months|years) nullable
- recur_interval INTEGER nullable
- notify INTEGER (0/1)
- is_done INTEGER (0/1)
- one_time_at INTEGER nullable (epoch ms, for one-time notify time)
- anchor_at INTEGER (epoch ms, start of recurrence)
- next_due_at INTEGER nullable (epoch ms)
- completed_at INTEGER nullable
- created_at INTEGER
- updated_at INTEGER

completions table (feeds calendar):

- id INTEGER PRIMARY KEY AUTOINCREMENT
- habit_id TEXT
- completed_at INTEGER

## Scheduling design (important)

- OS notifications cannot run Dart code at fire time. So state is resolved lazily.
- `HabitScheduler.reconcile(now)` runs on app start and on every resume: for each recurring habit with next_due_at <= now, set is_done=0, advance next_due_at by the interval until it is > now, then reschedule notifications.
- Notifications are pre-scheduled with `zonedSchedule` for a rolling window of upcoming occurrences (cap 40 per habit, global cap ~60 to stay under iOS's 64 pending limit; Android has more headroom).
- Toggling done on a recurring habit: record completion, set next_due_at = now-based next occurrence as per anchor, reschedule.
- Skip rule: if is_done is still true when a cycle hits, that cycle's notification is cancelled on toggle (cancel the pending one for the current cycle) and the next cycle is scheduled normally.
- Android: request POST_NOTIFICATIONS (13+), SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, and register the boot receiver so schedules survive reboot.

## CSV format

Header: `id,name,is_recurring,recur_unit,recur_interval,notify,is_done,one_time_at,anchor_at,next_due_at,completed_at,created_at,updated_at`
Completions export as a second section/file: `habit_id,completed_at`.

## SQL format

Plain text file of `INSERT OR REPLACE INTO habits (...) VALUES (...);` statements, one per row, wrapped in BEGIN/COMMIT, plus same for completions. Import executes statements in a transaction after validating the header marker `-- habit-tracker-backup v1`.

## Roadmap

1. Scaffold project, add deps, theme, app shell (drawer, home page, calendar toggle)
2. Models, database, repository
3. List UI: Active / Completed sections, toggle behavior, swipe to delete, empty states
4. Habit form bottom sheet: name, type, recurrence picker, notify toggle + time for one-time
5. Scheduler + notification service + permission flow + reconcile on resume
6. Countdown widget for completed recurring habits
7. Calendar view using completions
8. Backup service: CSV + SQL export/import, share sheet, file picker, merge-vs-replace dialog
9. Android/iOS platform config, app icon, splash, release build
10. Edge cases: timezone change, device reboot, DST, deleting habit cancels notifications

## Progress (update this)

- [ ] 1 Scaffold
- [ ] 2 DB + models
- [ ] 3 List UI
- [ ] 4 Habit form
- [ ] 5 Scheduler + notifications
- [ ] 6 Countdown
- [ ] 7 Calendar
- [ ] 8 Backup
- [ ] 9 Platform config
- [ ] 10 Edge cases

## Decisions log

- sqflite chosen over drift so SQL dump export stays simple.
- Riverpod chosen for state.

## Last session notes

(empty)

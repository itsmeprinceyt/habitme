# HabitMe – Project File Map

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
│   │   └── habit_scheduler.dart
│   │
│   ├── utils/
│   │   ├── date_utils.dart
│   │   └── duration_format.dart
│   │
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   │
│   └── ui/
│       ├── drawer/
│       │   └── app_drawer.dart
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
│           └── countdown_text.dart
│
└── data/
    ├── db/
    │   └── app_database.dart
    │
    ├── models/
    │   ├── recurrence.dart
    │   ├── habit.dart
    │   └── completion.dart
    │
    ├── repositories/
    │   └── habit_repository.dart
    │
    └── services/
        ├── notification_service.dart
        ├── backup_service.dart
        ├── csv_codec.dart
        └── sql_codec.dart
```

## Completed Work

### Step 1 – Project Setup & UI Foundation

- [x] Flutter project scaffold
- [x] Application theme and colors
- [x] App drawer
- [x] Home screen
- [x] List / Calendar view toggle

### Step 2 – Data Layer

- [x] Habit model
- [x] Recurrence model
- [x] Completion model
- [x] SQLite database setup
- [x] Habit repository
- [x] Database CRUD operations

### Step 3 – Habit Management & List UI

- [x] Habit controller using Riverpod AsyncNotifier
- [x] Habit providers
- [x] Active habits section
- [x] Completed habits section
- [x] Habit tile
- [x] Mark habit as completed
- [x] Swipe to delete with confirmation
- [x] Empty states
- [x] Derived providers for active and completed habits

### Step 4 – Scheduling & Notifications

- [x] Notification service using flutter_local_notifications
- [x] Device timezone synchronization
- [x] Notification permission handling
- [x] Exact alarm permission handling (Android)
- [x] Habit scheduler
- [x] Recurring habit reconciliation
- [x] Upcoming reminder generation
- [x] Per-habit notification cap
- [x] Global notification cap
- [x] Notification synchronization on habit CRUD
- [x] App startup reconciliation
- [x] App resume reconciliation

### Step 5 – Habit Creation & Editing

- [x] Habit form bottom sheet
- [x] Recurrence picker
- [x] Create habit functionality
- [x] Edit existing habits
- [x] One-time habit scheduling
- [x] Recurring habit configuration
- [x] Notification preference toggle
- [x] Form validation
- [x] Integration with existing HabitController
- [x] Notification synchronization after habit changes
- [x] Delete button in edit mode (with confirmation dialog)

### Step 6 – Date & Countdown Utilities

- [ ] `lib/core/utils/date_utils.dart`
- [ ] `lib/core/utils/duration_format.dart`
- [ ] `lib/core/ui/widgets/countdown_text.dart`
- [ ] Relative date formatting
- [ ] Countdown display
- [ ] Next due date display
- [ ] Human-readable duration formatting
- [ ] Handle past and future dates

### Step 7 – Calendar Integration

- [ ] Display habits on calendar
- [ ] Show scheduled and completed dates
- [ ] Navigate between months
- [ ] Select a date to view habits
- [ ] Calendar indicators for habit status
- [ ] Show recurring habit occurrences
- [ ] Handle calendar date selection

### Step 8 – Backup & Import/Export

- [x] `lib/data/services/backup_service.dart`
- [x] `lib/data/services/sql_codec.dart`
- [ ] `lib/data/services/csv_codec.dart`
- [ ] CSV export
- [ ] CSV import
- [x] SQL database export (share sheet, `habitme_backup_<timestamp>.sql`)
- [x] SQL database import (file picker, merge by habit id)
- [x] Backup validation and error handling (marker check, column whitelist, no raw SQL execution)
- [x] Restore existing backups (habits + completions, list refresh, notifications rescheduled)
- [x] `backupServiceProvider` in `providers.dart`
- [x] `url_launcher` dependency and Android `<queries>` entry for https

### Step 8b – UI Polish (done alongside)

- [x] Drawer redesign: rounded logo (`assets/habitme_logo_rounded.png`), tagline
- [x] "Made by ItsMe Prince" card opening https://www.itsmeprince.com
- [x] Drawer Import / Export wired to SQL backup
- [x] Safe-area handling on home body (`SafeArea(top: false)`)
- [x] Floating action button restyled (card background, green foreground, border)
- [x] Drawer background configurable via `drawerTheme` in `app_theme.dart`

### Step 9 – Testing & Final Polish

- [ ] Test notification scheduling on Android
- [ ] Test exact and inexact alarms
- [ ] Test recurring habit reset
- [ ] Test timezone changes
- [ ] Test app restart and resume
- [ ] Test notification permissions denied
- [ ] Test habit creation and editing
- [ ] Test one-time and recurring habits
- [ ] Test backup and restore
- [ ] UI responsiveness and edge cases
- [ ] Run `flutter analyze`
- [ ] Resolve remaining warnings and errors

---

## Current Progress

| Step | Description                   | Status                  |
| ---- | ----------------------------- | ----------------------- |
| 1    | Project Setup & UI Foundation | Complete                |
| 2    | Data Layer                    | Complete                |
| 3    | Habit Management & List UI    | Complete                |
| 4    | Scheduling & Notifications    | Implemented             |
| 5    | Habit Creation & Editing      | Complete (delete added) |
| 6    | Date & Countdown Utilities    | Pending                 |
| 7    | Calendar Integration          | Pending                 |
| 8    | Backup & Import/Export        | SQL done, CSV pending   |
| 9    | Testing & Final Polish        | Pending                 |

## Current Milestone

**Implemented:** Habit management, notification scheduling, habit creation/editing/deleting, SQL backup export/import, redesigned drawer, and safe-area/FAB polish.

**Next milestone:** Step 6 – Date & Countdown Utilities.

**Next files to create:**

1. `lib/core/utils/date_utils.dart`
2. `lib/core/utils/duration_format.dart`
3. `lib/core/ui/widgets/countdown_text.dart`

**Optional later:** `lib/data/services/csv_codec.dart` for CSV export/import.

## Decisions Log

- sqflite chosen over drift so SQL dump export stays simple.
- Riverpod chosen for state.
- SQL import never executes file contents; it parses only the exporter's INSERT format with whitelisted columns.
- Import merges by habit id using update-then-insert, because `INSERT OR REPLACE` would cascade-delete completions through the foreign key.
- Completions are deduplicated on (habit_id, completed_at) during import.
- file_picker 13: `FilePicker.pickFiles(...)` returns a nullable `List<PlatformFile>`; read the file via its path.

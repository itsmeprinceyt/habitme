# HabitMe – Project File Map

**Package name:** `habit_tracker`

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

- [ ] `lib/data/services/backup_service.dart`
- [ ] `lib/data/services/csv_codec.dart`
- [ ] `lib/data/services/sql_codec.dart`
- [ ] CSV export
- [ ] CSV import
- [ ] SQL database export
- [ ] SQL database import
- [ ] Backup validation and error handling
- [ ] Restore existing backups

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

| Step | Description                   | Status        |
| ---- | ----------------------------- | ------------- |
| 1    | Project Setup & UI Foundation | Complete      |
| 2    | Data Layer                    | Complete      |
| 3    | Habit Management & List UI    | Complete      |
| 4    | Scheduling & Notifications    | Implemented   |
| 5    | Habit Creation & Editing      | Code provided |
| 6    | Date & Countdown Utilities    | Pending       |
| 7    | Calendar Integration          | Pending       |
| 8    | Backup & Import/Export        | Pending       |
| 9    | Testing & Final Polish        | Pending       |

## Current Milestone

**Implemented:** Habit management foundation, notification scheduling, and habit creation/editing implementation.

**Next milestone:** Step 6 – Date & Countdown Utilities.

**Next files to create:**

1. `lib/core/utils/date_utils.dart`
2. `lib/core/utils/duration_format.dart`
3. `lib/core/ui/widgets/countdown_text.dart`

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

_Note: Implementation completed; runtime testing on physical Android devices is still pending._

## Remaining Work

### Step 5 – Habit Creation & Editing

- [ ] `lib/core/ui/habit_form/habit_form_sheet.dart`
- [ ] `lib/core/ui/habit_form/recurrence_picker.dart`
- [ ] Create habit functionality
- [ ] Edit habit functionality
- [ ] One-time habit scheduling
- [ ] Recurring habit configuration
- [ ] Notification preference toggle
- [ ] Form validation

### Step 6 – Date & Countdown Utilities

- [ ] `lib/core/utils/date_utils.dart`
- [ ] `lib/core/utils/duration_format.dart`
- [ ] `lib/core/ui/widgets/countdown_text.dart`
- [ ] Relative date formatting
- [ ] Countdown display
- [ ] Next due date display

### Step 7 – Calendar Integration

- [ ] Display habits on calendar
- [ ] Show scheduled and completed dates
- [ ] Navigate between months
- [ ] Select a date to view habits
- [ ] Calendar indicators for habit status

### Step 8 – Backup & Import/Export

- [ ] `lib/data/services/backup_service.dart`
- [ ] `lib/data/services/csv_codec.dart`
- [ ] `lib/data/services/sql_codec.dart`
- [ ] CSV export
- [ ] CSV import
- [ ] SQL database export
- [ ] SQL database import
- [ ] Backup validation and error handling

### Step 9 – Testing & Final Polish

- [ ] Test notification scheduling on Android
- [ ] Test exact and inexact alarms
- [ ] Test recurring habit reset
- [ ] Test timezone changes
- [ ] Test app restart and resume
- [ ] Test notification permissions denied
- [ ] Test backup and restore
- [ ] UI responsiveness and edge cases

---

## Current Progress

| Step | Description                   | Status      |
| ---- | ----------------------------- | ----------- |
| 1    | Project Setup & UI Foundation | Complete    |
| 2    | Data Layer                    | Complete    |
| 3    | Habit Management & List UI    | Complete    |
| 4    | Scheduling & Notifications    | Implemented |
| 5    | Habit Creation & Editing      | Pending     |
| 6    | Date & Countdown Utilities    | Pending     |
| 7    | Calendar Integration          | Pending     |
| 8    | Backup & Import/Export        | Pending     |
| 9    | Testing & Final Polish        | Pending     |

**Current milestone:** Habit management foundation and notification scheduling implemented.

**Next milestone:** Habit creation and editing, including recurrence configuration.s

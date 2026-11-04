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
- [x] Mark habit as completed and untoggle back to active
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

- [x] Modern center popup modal dialog for Habit Creation & Editing
- [x] User-friendly wording ('Frequency', 'Repeat every...', 'Daily', 'Weekly', 'Monthly' quick presets)
- [x] Recurrence picker with conversational phrasing and natural chip presets
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

- [x] `lib/core/utils/date_utils.dart`
- [x] `lib/core/utils/duration_format.dart`
- [x] `lib/core/ui/widgets/countdown_text.dart`
- [x] Relative date formatting (Today, Tomorrow, Yesterday, date + time)
- [x] Live ticking countdown display with tabular figures
- [x] Next due date / completion date display
- [x] Human-readable duration formatting & overdue handling
- [x] Section expandable/collapsible toggle with smooth rotation animation
- [x] Habit tile full text display without text truncation or ellipsis
- [x] Responsive layout with slick border glow and styling

### Step 7 – Calendar Integration

- [x] Display habits on calendar with dynamic event loading
- [x] Filter chips toggle for One-Time and Recurring habits (both can be toggled independently)
- [x] Creative markers: Green dot for One-Time, Orange dot for Recurring, and a dual-colored gradient pill when both exist on the same day
- [x] Weekend colors fixed to match theme (muted clean look instead of forced orange)
- [x] Navigate between months and select dates
- [x] Interactive selected day breakdown showing recurring & one-time habits with direct completion toggle and edit sheet tap
- [x] Full text visibility without ellipsis truncation

### Step 8 – Backup & Import/Export

- [x] `lib/data/services/backup_service.dart`
- [x] `lib/data/services/sql_codec.dart`
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

- [x] Zero-truncation responsiveness testing across compact & tablet viewports
- [ ] Test notification scheduling on Android
- [ ] Test exact and inexact alarms
- [ ] Test recurring habit reset
- [ ] Test timezone changes
- [ ] Test app restart and resume
- [ ] Test notification permissions denied
- [ ] Test habit creation and editing
- [ ] Test one-time and recurring habits
- [ ] Test backup and restore
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
| 5    | Habit Creation & Editing      | Complete (Popup Redone) |
| 6    | Date & Countdown Utilities    | Complete                |
| 7    | Calendar Integration          | Complete                |
| 8    | Backup & Import/Export        | Complete                |
| 9    | Testing & Final Polish        | In Progress             |

## Current Milestone

**Implemented:** Center popup habit dialog with natural wording & quick presets, responsive zero-truncation layout, calendar filtering with gradient badges, expandable habit tiles with live ticking countdowns, and SQL backup import/export.

**Next milestone:** Step 9 – Testing & Final Polish.

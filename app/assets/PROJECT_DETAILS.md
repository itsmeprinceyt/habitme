# HabitMe – Comprehensive Project Handout & Architecture Spec

## 1. Executive Summary & Rules

- **Application Name:** HabitMe
- **Package Name:** `habit_me`
- **Architecture Philosophy:** 100% Offline, Local-First, Zero Arbitrary Cloud Sync, Pitch Black Minimalist UI.
- **Theme Palette:**
  - Pitch Black: `#000000` (Scaffold background, canvas)
  - Surface: `#0D0D0D`
  - Cards: `#141414`
  - Borders: `#262626`
  - Text & Accents: Crisp White (`#FFFFFF`), Muted Slate Grey (`#8A8A8A`), Primary Green (`#22C55E`), and Isolated Completed Orange (`#FF8A00`).
- **Typography:** Standardized `Roboto` font with sans-serif fallback embedded in `AppTheme` for unified device rendering.
- **Iconography & Notifications:** Custom rounded HabitMe logo asset (`assets/habitme_logo_rounded.png`) used for app launcher and native notifications (`@mipmap/ic_launcher`).

---

## 2. Technical Stack

- **Framework:** Flutter (Material 3)
- **State Management:** `flutter_riverpod` (AsyncNotifier / Notifier architecture)
- **Database:** SQLite (`sqflite` v2) with foreign keys enabled (`PRAGMA foreign_keys = ON`)
- **Background & Notifications:** `flutter_local_notifications`, `timezone`, `flutter_timezone`
- **Calendar:** `table_calendar`
- **File & Share Handling:** `path_provider`, `file_picker`, `share_plus`
- **Utilities:** `intl`, `uuid`, `url_launcher`

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

---

## 4. Key Functional Features

### 4.1. Labels & Grouping Architecture
- **Single-Label Binding:** A habit can belong to at most one label. Assigning a new label unbinds the previous one.
- **Dynamic Color Sync:** If a habit has an assigned label, the habit icon and background tint automatically inherit that label's color. Unlabelled habits use neutral grey (`#8A8A8A`).
- **A-Z Label Sub-Grouping:** On the home page, Active and Completed sections group habits into alphabetical label subsections (`LabelSubheader`), with an unassigned bucket for unlabelled items.
- **Drawer Label Management:** Users can manage labels directly from the drawer: create labels with an 8-color palette, rename, or delete without deleting the underlying habits.

### 4.2. Persistent Expansion State
- Managed by `ExpansionPreferences`:
  - Remembers whether Active or Completed sections are open.
  - Remembers which label subsections are open.
  - Remembers individual habit tile expanded states.
  - States persist across application closures and re-launches.

### 4.3. Habit Scheduling & Reset Lifecycle
- **Offline Lazy Reconciliation:** Handled by `HabitScheduler.reconcile(now)` on app startup and lifecycle resume.
- **One-time Habits:** Toggle marks done or active; notification schedules once for `one_time_at`.
- **Recurring Habits:** When completed, `next_due_at` is calculated according to recurrence interval. Once `next_due_at <= now`, the habit resets to active.
- **Notifications:** Rolling window of scheduled reminders capped at 40 per habit and 60 globally.

### 4.4. Calendar View & Filtering
- Dynamic markers: Date markers match the assigned label colors of habits occurring on that day (neutral grey for unassigned; dual-colored pill when multiple label colors meet).
- Independent One-Time and Recurring filter chips styled in grey stone black.
- Interactive day view with direct completion toggling and edit access.

### 4.5. SQL Backup & Import/Export
- Export formats a transaction containing `labels`, `habits`, and `completions` starting with marker `-- habit-tracker-backup v1`.
- Safe SQL parser strictly validates table names and column names against a whitelist (no raw execution of arbitrary SQL).
- Merges updates by ID and inserts new entries while retaining completion histories.

---

## 5. File Map

```text
lib/
├── main.dart                          # App entry point, timezone & state initialization
├── app.dart                           # Root MaterialApp, dark theme configuration, lifecycle observer
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # DB version, table names, app metadata, branding URLs
│   ├── logic/
│   │   ├── habit_controller.dart      # Habit Riverpod AsyncNotifier
│   │   ├── label_controller.dart      # Label Riverpod AsyncNotifier
│   │   ├── habit_scheduler.dart       # Recurring calculations, notification rolling sync
│   │   └── providers.dart             # Derived Riverpod providers
│   ├── utils/
│   │   ├── date_utils.dart            # Human relative dates & formatters
│   │   ├── duration_format.dart       # Live countdown & overdue string formatters
│   │   └── expansion_preferences.dart # Persistent UI expansion state storage
│   ├── theme/
│   │   ├── app_colors.dart            # Pure dark color palette constants
│   │   └── app_theme.dart             # Unified theme & Roboto typography
│   └── ui/
│       ├── drawer/
│       │   ├── app_drawer.dart        # Drawer with Import, Export, Manage Labels, Creator credit
│       │   └── manage_labels_sheet.dart # Color palette & label CRUD dialog
│       ├── home/
│       │   ├── home_page.dart         # Scaffold with toggle between List and Calendar
│       │   ├── habit_list_view.dart   # Grouped A-Z habit list with expansion state
│       │   ├── habit_tile.dart        # Expandable habit card, dynamic label color, no ellipses
│       │   └── calendar_view.dart     # Monthly calendar with label-colored markers & filters
│       ├── habit_form/
│       │   ├── habit_form_sheet.dart  # Center popup dialog for habit creation/editing
│       │   └── recurrence_picker.dart # Quick recurrence presets & conversational repeat builder
│       └── widgets/
│           ├── section_header.dart    # Collapsible Active / Completed headers
│           ├── label_subheader.dart   # Collapsible label category headers
│           └── countdown_text.dart    # Ticking tabular-figure countdown timer widget
│
└── data/
    ├── db/
    │   └── app_database.dart          # SQLite v2 database instance, migrations & indexes
    ├── models/
    │   ├── label.dart                 # HabitLabel data model
    │   ├── habit.dart                 # Habit data model with labelId binding
    │   ├── recurrence.dart            # Recurrence calculation logic
    │   └── completion.dart            # Historical completion record model
    ├── repositories/
    │   ├── label_repository.dart      # SQLite Label CRUD operations
    │   └── habit_repository.dart      # SQLite Habit CRUD & completion range operations
    └── services/
        ├── notification_service.dart  # Native notification scheduling with app logo
        ├── backup_service.dart        # Safe export & import file operations
        └── sql_codec.dart             # Safe whitelist-based SQL backup serializer/deserializer
```

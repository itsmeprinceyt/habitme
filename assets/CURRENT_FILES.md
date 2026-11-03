# HabitMe - File Map

Package name: `habit_tracker`

## lib/

- main.dart
- app.dart

## lib/core/constants/

- app_constants.dart

## lib/core/theme/

- app_colors.dart
- app_theme.dart

## lib/core/logic/

- providers.dart
- habit_controller.dart

## lib/core/ui/widgets/

- section_header.dart

## lib/core/ui/drawer/

- app_drawer.dart

## lib/core/ui/home/

- habit_list_view.dart
- habit_tile.dart
- calendar_view.dart
- home_page.dart

## lib/data/models/

- recurrence.dart
- habit.dart
- completion.dart

## lib/data/db/

- app_database.dart

## lib/data/repositories/

- habit_repository.dart

## Full tree

```
lib/
  main.dart
  app.dart
  core/
    constants/
      app_constants.dart
    logic/
      habit_controller.dart
      providers.dart
    theme/
      app_colors.dart
      app_theme.dart
    ui/
      drawer/
        app_drawer.dart
      home/
        calendar_view.dart
        habit_list_view.dart
        habit_tile.dart
        home_page.dart
      widgets/
        section_header.dart
  data/
    db/
      app_database.dart
    models/
      completion.dart
      habit.dart
      recurrence.dart
    repositories/
      habit_repository.dart
```

## Done

- Step 1: scaffold, theme, drawer, list/calendar toggle
- Step 2: models, database, repository
- Step 3: list UI (Active/Completed sections, tile, toggle, swipe to delete with confirm, empty states, habit controller and derived providers)

## Remaining files (not created yet)

- lib/core/utils/date_utils.dart
- lib/core/utils/duration_format.dart
- lib/core/logic/habit_scheduler.dart
- lib/core/ui/habit_form/habit_form_sheet.dart
- lib/core/ui/habit_form/recurrence_picker.dart
- lib/core/ui/widgets/countdown_text.dart
- lib/data/services/notification_service.dart
- lib/data/services/backup_service.dart
- lib/data/services/csv_codec.dart
- lib/data/services/sql_codec.dart

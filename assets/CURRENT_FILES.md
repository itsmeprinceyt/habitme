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

## lib/logic/

- providers.dart

## lib/data/models/

- recurrence.dart
- habit.dart
- completion.dart

## lib/data/db/

- app_database.dart

## lib/data/repositories/

- habit_repository.dart

## lib/ui/widgets/

- section_header.dart

## lib/ui/drawer/

- app_drawer.dart

## lib/ui/home/

- habit_list_view.dart
- calendar_view.dart
- home_page.dart

## Full tree

```
lib/
  main.dart
  app.dart
  core/
    constants/
      app_constants.dart
    theme/
      app_colors.dart
      app_theme.dart
  data/
    db/
      app_database.dart
    models/
      completion.dart
      habit.dart
      recurrence.dart
    repositories/
      habit_repository.dart
  logic/
    providers.dart
  ui/
    drawer/
      app_drawer.dart
    home/
      calendar_view.dart
      habit_list_view.dart
      home_page.dart
    widgets/
      section_header.dart
```

## Done

- Step 1: scaffold, theme, drawer, list/calendar toggle
- Step 2: models, database, repository

## Remaining files (not created yet)

- lib/core/utils/date_utils.dart
- lib/core/utils/duration_format.dart
- lib/data/services/notification_service.dart
- lib/data/services/backup_service.dart
- lib/data/services/csv_codec.dart
- lib/data/services/sql_codec.dart
- lib/logic/habit_scheduler.dart
- lib/logic/habit_controller.dart
- lib/ui/home/habit_tile.dart
- lib/ui/habit_form/habit_form_sheet.dart
- lib/ui/habit_form/recurrence_picker.dart
- lib/ui/widgets/countdown_text.dart

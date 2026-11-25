# HabitMe Flutter App — Workflow

> Project-specific documentation: user flows, developer workflows, and the
> invariants to keep when changing the app.
>
> Last updated: 25 November 2026

---

## 1. User Flows

### First launch
1. `main()` loads expansion prefs, warms notifications and ads, starts the app.
2. `HabitController.build()` → `HabitScheduler.reconcile(now)` loads habits
   (empty), then a background notification sync (no-op).
3. Home shows the empty state: "No habits yet / Tap New habit to add your first."
4. Post-frame: `checkPermissionsOnLaunch()` asks for notification and exact-alarm
   permission if not already granted.

### Create a habit
1. FAB **New habit** → `HabitFormSheet.show()`.
2. Enter title (required), optionally pick or create a label, choose
   Recurring / One-Time.
3. Recurring: choose a preset or "Every N units" and the first occurrence.
   One-Time: pick date + time.
4. Toggle **Remind Me** (defaults on). Saving requests notification permission.
5. Save → `Habit.create` → `HabitController.add` → insert → prepend to state →
   async `scheduler.sync(..., askPermissions: true)`.
6. Dialog closes, snackbar "Habit created".

### Complete a habit
- Recurring: the switch marks it done and `nextDueAt` rolls to the next future
  occurrence; a completion row is logged. The tile stays in Active with a fresh
  countdown.
- One-Time: the switch toggles done/completedAt, logs or removes the latest
  completion, and the tile moves between Active and Completed (strikethrough when
  done).
- From the notification shade, **Done** marks it done without opening the app.

### Edit / delete
- Pencil on the tile or tapping a calendar day item opens the same form in edit
  mode. Changing type/interval/start time resets the schedule; name/label edits
  keep the countdown.
- Delete via swipe-left + confirm, or the footer trash icon in edit mode.
  Completions cascade; the reminder plan is re-synced.

### Let time pass
- App closed: OS fires the scheduled alarms. A fired reminder re-arms that
  habit's next occurrence; the next app start reconciles everything else and tops
  the 60-reminder window back up.
- App open: the due ticker wakes at the soonest due time (+300ms), rolls the
  habit, and the countdown restarts. Resume from background also reconciles.
- Reboot/update: the boot receiver restores alarms; the next reconcile re-plans.

### Calendar check
1. App bar toggle → calendar (fade/slide switch).
2. Month grid shows a heat square per day (deeper green = more habits).
3. Tap a day → date card lists its recurring then one-time habits; toggle or tap
   to edit. Filter pills can hide One-Time or Recurring.

### Labels
1. Drawer → Manage Labels.
2. Create with a name + one of 8 colours; edit name/colour; delete (habits stay,
   just unlabelled).
3. List view groups by label A→Z; tiles take the label colour.

### Backup
- Drawer → Export → SQL dump shared through the system sheet; snackbar shows the
  file name.
- Drawer → Import → pick a `.sql` backup → merged in a transaction; snackbar
  reports habits/labels/completions plus any skipped items.
- Bad file → the parser's message is shown (line number where possible).

### Support / debugging
- Drawer → Support developer → rewarded ad; thank-you or "skipped" message.
- Drawer → Logs → interstitial, then live logs + scheduled reminder list; copy
  both to the clipboard for a bug report.

---

## 2. State Flow (simplified)

```
UI action (switch / form save / swipe)
        │
        ▼
HabitController ── repo.insert/update/delete/toggleDone ──► sqflite
        │  state = AsyncData(new list)
        │
        ├─ unawaited HabitScheduler.sync(habits, now)
        │        └─ NotificationService.replaceAll(plan)  → OS alarms
        │
        └─ ref.listen in app.dart re-arms the foreground due ticker

Timer / app resume
        │
        ▼
HabitController.refreshDue / reconcileAndSync
        │
        ▼
HabitScheduler.reconcile → rolls due habits → DB updates → new list
```

Notification "Done" while app is dead goes straight to
`notification_action_handler.dart` → repository + scheduler (no Riverpod).

---

## 3. Developer Workflow

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run                     # debug device/emulator
flutter build apk --release     # current signing uses the debug key
```

Logs are mirrored into the in-app Logs page, so `flutter run` output and the
device output show the same lines.

### Adding a habit field (checklist)
1. `data/models/habit.dart`: add `HabitColumns` constant, constructor field,
   `fromMap`, `toMap`, and `copyWith` (value-getter for nullable fields).
2. `data/db/app_database.dart`: add the column in `_onCreate` **and** a migration
   step in `_onUpgrade` with a version bump (`AppConstants.databaseVersion`).
3. `data/services/sql_codec.dart`: add the column to `_schemas` (required flag
   and type) so backups round-trip; update `backup_codec_test.dart`.
4. `core/ui/habit_form/habit_form_sheet.dart`: input + save wiring.
5. Surface it in `habit_tile.dart` / `calendar_view.dart` if relevant; update
   `test/scheduling_test.dart` for tolerant parsing.
6. Run `flutter analyze` and `flutter test`.

### Changing recurrence or scheduling
- All recurrence maths lives in `data/models/recurrence.dart`; time is always
  truncated to the minute.
- The reminder plan lives in `core/logic/habit_scheduler.dart` `_plan`; caps are
  `globalCap = 60` and per-habit quota. Add tests to
  `test/habit_scheduler_test.dart` (fakes exist there).
- Notification plumbing (channels, ids, modes, permissions) is
  `data/services/notification_service.dart`; never bypass `replaceAll` for bulk
  changes, and keep calls serialised through its queue.

### Adding a screen or sheet
- Create the file under `core/ui/...`, use `AppColors`/`AppTheme` tokens, and
  follow the dialog shape (header with accent tile → scrollable body → footer).
- Read state with `ref.watch`, mutate through controllers only.
- If it navigates from the drawer, close the drawer first (`navigator.pop()`),
  then push/show.

### Debugging scheduling problems
1. Open Drawer → Logs: compare "Scheduled Notifications" with what the OS shows.
2. Copy all logs for the reconcile/sync lines
   (`Notifications: N scheduled, M cancelled, K kept`).
3. Check permission state: notifications enabled, exact alarms allowed
   (`canScheduleExactNotifications`), battery optimisation / manufacturer
   restrictions.
4. Remember the 60-reminder window only refills when the app opens.

---

## 4. Invariants (do not break)

1. **Minute precision** — `Habit.create`, `Recurrence.minuteOf`,
   `HabitScheduler._toMinute` all truncate seconds. Storage, countdown and
   alarms must describe the same minute.
2. **`nextAfter` is strictly in the future** — toggling done re-anchors on it;
   a past value breaks the countdown and reminder loop.
3. **Reconcile never blocks the UI** — notification sync stays `unawaited` and
   catches its own errors; the habit list must load even if the platform refuses.
4. **Reminder keys are stable** — `habitId@epochMinute`; never derive ids from
   list position or a timestamp that changes on every sync.
5. **Reservation before fairness** — each notifying habit always gets its next
   occurrence before any habit gets a second.
6. **Backup files are data, never SQL** — `SqlCodec.decode` must keep parsing
   positionally against the whitelist; never execute file contents.
7. **Import order is labels → habits → completions**, and completion autoincrement
   ids are never imported.
8. **Label delete unlinks, never deletes habits.**
9. **UI writes through controllers** — no `sqflite` calls from widgets.
10. **Home has no ads** — Unity surfaces only on the Logs page and via drawer
    actions.

---

## 5. Release Checklist

- `flutter analyze` clean, `flutter test` green.
- Bump `version` in `pubspec.yaml` (`build` number too).
- Confirm `AppConstants.unityTestMode = false` only for store builds.
- Verify notification permission + exact alarm flow on a clean install
  (Android 13+).
- Verify import/export round trip on device (content URI path).
- Replace the debug signing config before publishing (`android/app/build.gradle.kts`).
- Update website legal pages if permissions, ads or data handling change.

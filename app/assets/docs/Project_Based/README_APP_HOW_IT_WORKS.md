# HabitMe Flutter App — How It Works

> Project-specific documentation for the app's behaviour and algorithms. Every
> claim here is taken from the current Dart source, not from older notes.
>
> Last updated: 25 November 2026

---

## 1. Data Model

SQLite database `habitme.db`, schema version 4, foreign keys on.

### `labels`
`id TEXT PK`, `name TEXT NOT NULL`, `color INTEGER` (ARGB), `created_at INTEGER`.

### `habits`
`id TEXT PK`, `name TEXT NOT NULL`, `label_id TEXT` (FK → labels, `ON DELETE SET NULL`),
`is_recurring INTEGER`, `recur_unit TEXT`, `recur_interval INTEGER`,
`description TEXT` (optional note, max 300 in the form), `recur_count INTEGER`
(nullable total occurrences), `notify INTEGER`, `is_done INTEGER`,
`one_time_at INTEGER`, `anchor_at INTEGER NOT NULL`, `next_due_at INTEGER`,
`completed_at INTEGER`, `created_at INTEGER`, `updated_at INTEGER`.
Index on `label_id`.

### `completions`
`id INTEGER PK AUTOINCREMENT`, `habit_id TEXT` (FK → habits, `ON DELETE CASCADE`),
`completed_at INTEGER`. Indexes on `habit_id` and `completed_at`.

Notes:
- All times are millisecond epochs, and **every scheduled time is truncated to a
  whole minute** (seconds/millis always zero) before storage or arming.
- `anchor_at` is the recurrence origin. `next_due_at` is the cached next
  occurrence for recurring habits.
- Migrations: v1→v2 adds `labels` and `habits.label_id`; v2→v3 adds
  `habits.description`; v3→v4 adds `habits.recur_count`. All new columns are
  nullable, so upgraded habits keep their schedule (no note, repeat forever).
  `ALTER TABLE` cannot add the foreign key, so upgraded databases may hold a
  dangling `label_id`; the backup importer nulls unknown labels instead of
  relying on the constraint.
- Models tolerate rough data on read: `Habit.fromMap` treats booleans as
  `1`/`true`, parses text epochs, and downgrades a zero/negative interval to a
  one-time habit instead of throwing. `HabitRepository.getAll` skips a single
  unreadable row and keeps the rest of the list.

---

## 2. Recurrence

`Recurrence(unit, interval, count?)` with
`RecurUnit = minutes | hours | days | months | years`, `interval > 0`
(asserted; internally floored at 1 by `_step`) and optional `count > 0`
(asserted; `withCount(<= 0)` normalises to null = forever).

- `occurrence(anchor, index)` = anchor + `interval × index` steps.
  Days use calendar arithmetic (`DateTime(y, m, d + n)`), months/years go through
  `_addMonths`, which clamps to the last day of the target month
  (Jan 31 + 1 month → Feb 28/29).
- `nextAfter(anchor, now)` returns the first occurrence **strictly after** now,
  or **`null` once a limited series has produced all `count` occurrences**. A
  boundary time advances to the following occurrence. It estimates the index
  from the elapsed duration/month count, then walks forward until the occurrence
  is in the future.
- `upcoming(anchor, now, take)` returns the next `take` occurrences, capped by
  what is left of the repeat count.
- `remaining(anchor, now)` = `count - elapsed` (null when unlimited, floored at
  0); an occurrence starting exactly at `now` still counts as remaining.
  `isFinished(anchor, now)` is true once `nextAfter` would exceed the count.
  `isLimited` reports whether a count is set.
- `occursOnDate(anchor, target)` decides calendar membership:
  - minutes/hours: every day from the anchor day onward,
  - days: day difference divisible by the interval,
  - months/years: month/year difference divisible by the interval and the day
    matches the anchor day (clamped to month end).
- `label`: "Every day" / "Every 3 days" / "Every hour" (singular vs plural).
- `occursOnDate` also respects the count for days/months/years so calendar
  days after the last occurrence are not painted as scheduled.

---

## 3. Habit Lifecycle

**Create** (`Habit.create`): UUID v4 id, trimmed name and description,
`isDone = false`, anchor and timestamps truncated to the minute,
`nextDueAt = recurrence.nextAfter(anchor, now)`; `oneTimeAt` is only kept for
non-recurring habits. The form's optional repeat count is stored in
`recur_count`, which becomes `Recurrence.count`.

**Toggle done** (`HabitRepository.toggleDone`, used by `HabitController.toggle`):
- writes `is_done`, `completed_at`, `next_due_at`
  (`recurrence?.nextAfter(anchorAt, now)`), `updated_at`;
- in the same transaction, inserts a `completions` row when marking done, or
  deletes the **latest** completion row for that habit when un-marking;
- returns the updated habit; the controller replaces it in state and kicks an
  async notification sync.

**Roll forward** (`HabitScheduler.reconcile`): on startup and every resume, any
recurring habit whose `next_due_at` (`nextDueAt`) is `<= now` is reset to active
(`isDone = false`, `completedAt = null`) and given the next future occurrence.
A limited series whose `nextAfter` returns `null` is **not** restarted: its
`next_due_at` becomes null and it leaves the active rotation. This is what
makes a missed day reset an ongoing habit without resurrecting a finished
series.

**Foreground ticker** (`app.dart`): a one-shot `Timer` waits until the soonest
`nextDueAt + 300ms` (floor 2s, ceiling 5min) and calls `refreshDue()`, which
reconciles only if something is actually due. The timer is re-armed on every
habit-list change via `ref.listen`, and on timer/if backgrounded simply re-arms
(Flutter freezes timers while backgrounded; resume reconciles).

**Delete**: removes the habit row; completions cascade. Reminder plan is
re-synced, so its alarms disappear from the OS.

**Update** (`HabitFormSheet`): if type, recurrence unit/interval/count, or the
recurring start time changed, the schedule resets (`nextDueAt` computed from the
anchor, done/completed cleared). Otherwise `nextDueAt` is preserved so editing a
name, label or description does not move the countdown.

---

## 4. Notification Planning (`HabitScheduler`)

Constants: `perHabitCap = 40` (bounds `Recurrence.upcoming`),
`globalCap = 60` (OS pending-alarm budget), `minRecurrenceInterval = 15 min`
(helper only).

`_plan(habits, now)`:
1. Consider only habits with `notify = true`.
2. **Reservation pass** — take exactly the first upcoming occurrence of each
   notifying habit. One-time habits contribute their `one_time_at` only when not
   done and strictly in the future; a recurring habit with no future occurrence
   (including a finished limited series) contributes nothing.
3. If reservations exceed `globalCap`, keep the first 60 by priority:
   not-done before done, then earliest time, then `habitId`.
4. Otherwise share the remaining budget fairly: sort the overflow occurrences
   by time and give each habit at most `max(1, remaining ~/ notifyingCount)`
   extra slots. This is what stops a 1-minute habit from eating the whole queue.
5. Return everything sorted by time.

Reminder identity: `key = "<habitId>@<epochMs of the minute>"`, and
`stableNotificationId(key)` is an FNV-1a hash kept in the positive 31-bit range.
The id therefore survives re-syncs and app restarts for an unchanged occurrence.

`NotificationService.replaceAll(reminders)`:
- recomputes the plan signature (`id=epoch` pairs, sorted);
- on the first sync of a session it re-arms everything (repairs alarms dropped by
  force-stop/battery optimisation), afterwards it only adds missing ids and
  cancels stale ones;
- if reading pending notifications fails, it cancels all and re-arms the plan;
- serialises every platform call through a future queue with a 15s timeout.

Scheduling mode: `AndroidScheduleMode.alarmClock` when exact alarms are
available (survives Doze), otherwise `inexactAllowWhileIdle`. A rejected exact
schedule is logged and retried inexactly.

`onReminderFired(habitId, firedAt)`: for a recurring habit, schedules just the
next occurrence (`scheduleOne`) without replacing the queue; a limited series
that has reached its count schedules nothing further. One-time habits schedule
nothing further.

---

## 5. Notification Delivery & Actions

- Channel `habit_reminders_v2` ("Habit reminders"), importance/priority max,
  public visibility, category `reminder`, small icon `ic_notification`, large
  icon `notification_logo`, and a **Done** action that does not open the UI and
  cancels the notification.
- Body text: recurring → "Time to do it · Every 3 days"; one-time → "Reminder".
  Payload is the habit id.
- App alive: `onDoneAction` → `HabitController.markDoneFromNotification`
  (idempotent — an already-done habit is untouched), `onFired` → scheduler rolls
  the next occurrence.
- App dead/background: `habitNotificationBackgroundHandler` opens the database
  directly (no Riverpod), marks the habit done through `HabitRepository`, and
  re-syncs via its own `HabitScheduler`.
- Permissions: notifications and exact alarms are requested on first launch and
  when saving a habit with reminders; `ensurePermissions` runs once per process.
  If notifications were denied and later granted, the next launch resets the sync
  signature so alarms scheduled while denied are re-armed.
- Boot/update: the plugin's boot receiver restores pending alarms, and the app's
  next reconcile re-plans from the database.
- Seen reminders: `clearDelivered()` runs on launch and again on resume, so the
  notification shade only keeps reminders the user has not looked at yet. The
  in-app Guide page explains this instead of warning about the OS limit.
- Reminder limit: at most 60 are held by the OS at a time; opening the app
  refreshes the window.

---

## 6. Labels

- A habit has at most one label; assigning another replaces it.
- Label delete unlinks habits (sets `label_id = null`) and deletes the label in
  one transaction — habits are never deleted.
- `LabelController` reloads labels and calls `habitController.reconcile()` after
  update/delete so tiles re-render with the new name/colour.
- List view groups by label (A→Z, unlabelled last); calendar ignores labels for
  filtering but uses them for the day-item accent colours and chips.

---

## 7. Backups (`BackupService` + `SqlCodec`)

**Export**
1. Query all three tables (`labels` A→Z, `habits` by `created_at`, `completions`
   by `completed_at`).
2. `SqlCodec.encode` writes:
   `-- habit-tracker-backup v1`, export timestamp, row counts,
   `BEGIN TRANSACTION;`, one `INSERT INTO <table> (<all columns>) VALUES (…);`
   per row (labels → habits → completions), `COMMIT;`.
   Values are quoted with `''` escaping; `NULL` for absent values.
3. Write `habitme_backup_yyyyMMdd_HHmmss.sql` to the temporary directory and open
   the system share sheet (`share_plus`). The temp file name is returned for the
   snackbar; nothing is uploaded.

**Import**
1. Pick any file (`file_picker`, `FileType.any`), read bytes via
   `PlatformFile.readAsBytes()` (works with Android content URIs), falling back
   to `File(path)`.
2. `SqlCodec.decode` is a strict, non-executing parser:
   - normalises BOM/CRLF, requires the backup marker;
   - whitelists exactly the three tables and their columns;
   - parses `INSERT [OR …] INTO table (cols) VALUES (…), (…);` positionally,
     with quoted strings, `NULL` and integers;
   - rejects unknown tables/columns, wrong value counts, missing required
     values, non-numeric values, unterminated statements, and empty backups with
     a `FormatException` that names the line;
   - coerces types and re-validates each row through the models.
3. Merge inside one transaction: labels upserted (update, else insert-ignore),
   then habits with unknown `label_id` cleared, then completions inserted only
   for existing habits and only when `habitId@completedAt` is new. Autoincrement
   ids are never taken from the file.
4. Returns `ImportSummary` (habits, labels, completions, orphan completions,
   unlabelled habits). The drawer shows these counts, then reloads labels and
   reconciles habits. Cancel returns `null` and changes nothing.

---

## 8. Ads

`AdsService` (Unity Ads, game id in `AppConstants`, `testMode: false`):
- `init()` once at startup; on success loads one interstitial and one rewarded ad.
- `showInterstitial()` — called before opening the Logs page.
- `showRewarded()` — "Support developer" in the drawer; returns whether the ad
  was watched, drives the thank-you/skipped snackbar.
- `ready` (ValueNotifier) gates `AdBanner`, used three times on the Logs page
  (top, middle, bottom). Home, calendar and the form show no ads.
- Failures are logged via `debugPrint` and never surface as errors to the user.

---

## 9. Logging & Preferences

- `main()` tees `debugPrint` into `AppLog`, a 600-line in-memory ring buffer
  stamped `[HH:mm:ss]`. The Logs page listens to `AppLog.version`, can copy logs
  + the computed schedule to the clipboard, and clear the buffer.
- `ExpansionPreferences` persists booleans in
  `<app documents>/expansion_state.json` (debounce-free write on each toggle):
  section open/closed, label group open/closed, individual tile expanded.
  Loaded before `runApp`; read failures fall back to defaults.

---

## 10. Failure Handling

- DB load failure surfaces as an error state with the real message and a Retry.
- Notification init/sync/permission failures are caught and logged; the habit
  list never waits on a platform channel.
- Import validation errors show the parser's message (up to 8s), not a generic
  failure.
- Ad failures are silent except in the debug log.
- The scheduler's reconcile catches per-habit nothing — a DB write failure
  propagates to the controller, which rethrows so the UI can report it.

---

## 11. Known Gaps

- No background refresh: there is a `TODO` to use workmanager/background fetch
  so the 60-reminder window can be topped up while the app is closed.
- `exactAlarmsBlocked` and `openExactAlarmSettings()` exist but no UI warning is
  shown when exact alarms are denied.
- Release builds are still signed with the debug key.
- `HabitScheduler.isRecurrenceTooFrequent` and `canAddNotifyingHabit` are unused
  by the form.
- Expansion preferences are not cleaned up when a habit is deleted (keys remain
  in the JSON file).
- Ad banner placement is limited to the Logs page.

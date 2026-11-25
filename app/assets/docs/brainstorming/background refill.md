# Background Reminder Refill — Problem Report & Implementation Plan

> **Status:** Proposal — not implemented yet
> **App:** HabitMe (`com.itsmeprince.habitme`, Flutter)
> **Date:** 25 November 2026
> **Scope:** Android first; iOS noted as future work
> **Related TODO:** `lib/app.dart:72`, `lib/core/logic/habit_scheduler.dart:79`
> **Related known gap:** `app/assets/docs/Project_Based/README_APP_HOW_IT_WORKS.md` → "Known Gaps"

---

## 1. TL;DR

HabitMe keeps at most **60 reminders** armed in the OS at a time. This window is
filled when the app opens, resumes, or a habit changes. If the app stays fully
closed long enough for that 60-reminder window to be used up, **no new reminders
are scheduled until the user opens the app again**.

That is why the two `TODO(background)` comments still exist. They are not stale
in the sense of "the feature was moved somewhere else" — the feature is simply
**not implemented**. The current design made the problem much less visible
(exact alarms, boot restore, a large look-ahead window, and re-sync on resume),
but it did not remove the gap.

**Recommended fix:** a periodic Android WorkManager task (through the Flutter
`workmanager` plugin) every **30 minutes** that reads habits, recomputes the
notification plan, and schedules only the missing reminders. It must **not**
cancel or re-arm the whole queue, and it should **not** write to the database or
clear delivered notifications.

Estimated effort: **1–2 developer days**, including tests and device
verification.

---

## 2. Why this document exists

The two TODO comments say:

```dart
// TODO(background): refill via workmanager/flutter_background_fetch every N minutes
```

Locations:

| File | Line | Context |
| --- | --- | --- |
| `lib/app.dart` | 72 | `didChangeAppLifecycleState` → resume branch |
| `lib/core/logic/habit_scheduler.dart` | 79 | above `onReminderFired` |

They look old because a lot of reliability work has been added around them. The
goal of this document is to answer four questions before changing code:

1. Is the TODO still describing a real problem?
2. What exactly happens today, and where does it stop working?
3. What should a proper fix look like?
4. How do we implement, test and roll it out without destabilising reminders?

---

## 3. Current behaviour (verified from source)

### 3.1 Reminder planning

`HabitScheduler._plan()` in `lib/core/logic/habit_scheduler.dart`:

- considers only habits with `notify == true`;
- reserves exactly one future occurrence per notifying habit;
- if reservations exceed `globalCap = 60`, keeps the 60 highest priority
  (not-done first, then earliest, then habit id);
- otherwise shares the remaining budget fairly, with at least one extra slot per
  habit (`max(1, remaining ~/ notifyingCount)`);
- caps each habit at `perHabitCap = 40` upcoming occurrences while generating
  candidates.

The result is a list of **at most 60** `ScheduledReminder`s.

### 3.2 When the plan is pushed to the OS

`NotificationService.replaceAll()` is called from `HabitScheduler.sync()`
whenever:

- `HabitController.build()` runs at app start (`reconcile()` at the end of
  `HabitScheduler.reconcile()`);
- the app resumes (`app.dart`, `didChangeAppLifecycleState`);
- a habit is added, edited, toggled, completed, deleted or marked done from a
  notification;
- the background "Done" handler runs (`notification_action_handler.dart`);
- import finishes.

The first sync of a session re-arms every reminder. Later syncs only add missing
ids and cancel stale ones.

### 3.3 What is already reliable

- **Exact delivery:** `AndroidScheduleMode.alarmClock` when exact alarms are
  allowed, otherwise `inexactAllowWhileIdle`.
- **Boot/update restore:** `ScheduledNotificationBootReceiver` in
  `android/app/src/main/AndroidManifest.xml`.
- **Stable ids:** `FNV-1a(habitId@epochMinute)`, so re-syncing does not create
  duplicates.
- **Seen reminders:** `clearDelivered()` on launch and resume.
- **Foreground rollover:** a due ticker in `app.dart` wakes at the next due time
  and reconciles while the app is open.
- **Background "Done":** tapping the action on a notification marks the habit
  done and runs a full sync from a background isolate.

### 3.4 The missing piece

None of the above runs when the app is **closed and untouched**.

Android fires the alarms that were already scheduled, but Flutter is not
running, so nothing computes the next plan. Once the last of the 60 alarms has
fired, the queue is empty. Reminders resume only when:

- the user opens the app;
- the user taps **Done** on a notification (which starts the background
  handler);
- the device reboots (the boot receiver restores the *existing* alarms, but
  does not create new ones beyond the stored set);
- the app is updated.

There is no periodic job, no `WorkManager`, no `flutter_background_fetch`, no
server push. `pubspec.yaml` contains none of those dependencies.

---

## 4. Why this is worth fixing

### 4.1 User-facing impact

A habit tracker's core promise is "remind me even when I am not looking at the
app". Today, the reminder system silently degrades after the look-ahead window
is consumed.

Typical effects:

- a frequent habit stops reminding while the user is on vacation or busy;
- the user assumes notifications are broken and disables them;
- the app's 60-reminder window looks like a product limit instead of an
  implementation detail;
- the user has to remember to open the app to "reload" reminders — exactly the
  behaviour a habit app should not require.

### 4.2 Engineering benefits

- Removes the last major reliability gap in the notification pipeline.
- Makes the 60-reminder cap a scheduling detail rather than a user-visible
  ceiling.
- Lets the app keep working across long absences without opening.
- Removes two misleading TODOs and the "Known Gaps" entry, so future work is
  not confused by stale notes.
- Creates a reusable background entry point for future maintenance tasks
  (cleanup, backup reminders, etc.).

### 4.3 What we should *not* promise

WorkManager is **not exact**. Android may batch or delay periodic work,
especially in Doze or under aggressive OEM battery management. The fix is
best-effort queue refilling; exact reminder delivery remains the job of the
already-scheduled `alarmClock` alarms. The 60-reminder buffer is what absorbs
worker delay.

---

## 5. Exact scenarios where the gap is hit

The numbers below use the real planner rules. "Window" means how long the
scheduled reminders last without opening the app.

### Scenario A — one daily habit

- 60 occurrences × 1 day = **~60 days**.
- Low severity; most users open the app far sooner.

### Scenario B — one hourly habit

- 60 occurrences × 1 hour = **~2.5 days**.
- A long weekend without opening the app exhausts the queue.

### Scenario C — four hourly habits

- 4 reservations + `56 ~/ 4 = 14` extras each = 15 occurrences per habit.
- 15 hours of coverage, then silence until the app opens.

### Scenario D — frequent habit mixed with daily habits

Example: 10 daily notifying habits + 1 habit every 15 minutes.

- 10 reservations are taken by the daily habits.
- Remaining budget = 50, notifying count = 11 → `extraPerHabit = max(1, 50 ~/ 11) = 4`.
- The 15-minute habit gets **1 reservation + 4 extras = 5 reminders**.
- Its reminders stop after roughly **75 minutes** while the app is closed, even
  though the queue still holds daily reminders far in the future.

This is the sharpest failure: a short, high-frequency habit loses its reminders
first because the fair-share rule protects other habits.

### Scenario E — vacation / travel

- 3 habits every 2 hours = 36 reminders/day for those habits.
- The 60-slot window covers **less than two days**.

### Scenario F — force-stop and OEM battery managers

- Some devices drop alarms on force-stop; WorkManager itself is also suspended
  after a force-stop until the user opens the app.
- Xiaomi/Oppo/Vivo/Samsung battery optimisation may delay or suppress periodic
  work even when the app is not force-stopped.
- This fix reduces, but cannot completely eliminate, OEM behaviour. The exact
  alarms and boot receiver remain the second line of defence.

### Scenario G — reboot / app update

- The boot receiver re-arms stored alarms.
- It does not extend the window. If the stored set was nearly exhausted before
  the reboot, it stays nearly exhausted.

### Scenario H — notifications denied, then granted

- Reminders scheduled while permission was denied never displayed.
- Existing launch/resume logic detects the change and re-arms. WorkManager must
  not fight that logic; it should skip cleanly when permission is off.

---

## 6. Goals and non-goals

### Goals

1. Keep the 60-reminder queue topped up while the app is closed.
2. Never cancel, duplicate, or reorder reminders that are already armed.
3. Do no database writes from the background job (avoid races with the UI).
4. Never clear notifications the user has not seen.
5. Survive failures quietly; a background failure must not crash the app.
6. Keep the fix testable and observable through the existing Logs page.
7. Remove the TODOs and update the known-gap documentation only after the
   feature is verified.

### Non-goals

- Guaranteed exact timing for the refill job itself.
- Background execution on iOS (future; BGTaskScheduler has its own rules).
- Server push notifications.
- Changing the 60-reminder cap or the fairness algorithm.
- Rolling over due habits in the database from the background job.

---

## 7. Options considered

| Option | How it works | Pros | Cons | Verdict |
| --- | --- | --- | --- | --- |
| **A. `workmanager` Flutter plugin (periodic)** | Registers Android WorkManager periodic work; runs a Dart callback isolate | Simple, idiomatic Flutter, reuses DB/scheduler Dart code, survives reboot, no new permissions | Minimum ~15 min, inexact, OEM throttling, extra plugin | **Recommended** |
| B. Native Kotlin WorkManager + MethodChannel | Kotlin worker calls into Dart or reimplements plan in Kotlin | Maximum control, no plugin dependency | Duplicates scheduling/plan logic or needs a channel bridge; more code and tests | Fallback if plugin breaks |
| C. `AlarmManager` repeating refill alarm | Exact-ish repeating alarm triggers a background isolate | Fits existing exact-alarm setup | Exact-alarm permission, battery cost, still needs isolate/DB work; Android discourages repeating exact alarms | Not recommended |
| D. Foreground service | Always-running service refills the queue | Reliable while running | Permanent notification, battery drain, Play Store policy concerns, overkill | No |
| E. Push notification from a server | Server schedules/sends reminders | Works even if app is killed | Backend, accounts, privacy, cost; contradicts offline-first design | Out of scope |
| F. Status quo + document limitation | Keep 60-ahead and current docs | Zero work | Reminders still stop after the window; frequent habits fail first | Accept only as temporary |

### Why WorkManager

- It is the Android-recommended API for deferrable periodic background work.
- The plugin lets the job run Dart code, so the existing `HabitScheduler` and
  `NotificationService` remain the single source of truth.
- It needs no dangerous permission and no persistent notification.
- 30 minutes is far more frequent than needed for a 60-reminder buffer, so
  Doze delay is harmless in practice.

---

## 8. Recommended design

### 8.1 High-level flow

```
Android WorkManager (every 30 min)
        │
        ▼
Dart callback isolate
  DartPluginRegistrant.ensureInitialized()
        │
        ▼
ReminderRefillService.refill()
        │
        ├─ read habits from sqflite (read-only)
        ├─ HabitScheduler.computePlan(habits, now)
        ├─ NotificationService.ensureScheduled(plan)
        │     └─ read pending ids; schedule only missing ones
        └─ debugPrint summary; return success
```

### 8.2 Key design decisions

1. **No `reconcile()` in the background job.**
   `reconcile()` writes rolled-over habits to the database. If WorkManager runs
   while the app is foreground, those writes can race with the UI isolate and
   leave the visible list stale. The planner does not need `next_due_at`; it
   computes occurrences from `anchor_at` and `now`, so a read-only refill is
   enough.

2. **No `clearDelivered()` in the background job.**
   Clearing delivered notifications while the app is closed would remove
   reminders the user has not seen yet. Clearing belongs to app open/resume.

3. **Do not call `replaceAll()` with its "first sync re-arms everything" path.**
   `NotificationService`'s `_initialSyncDone` flag lives inside a single isolate.
   Every WorkManager run starts a fresh isolate, so the current method would
   treat each run as the first sync and reschedule all 60 reminders. That is
   wasteful and can fight the UI isolate. Add a dedicated `ensureScheduled()`
   that always diffs against the OS pending list and never re-arms everything.

4. **Stable ids remain the safety net.**
   Scheduling an already-pending `habitId@minute` id replaces the same alarm; it
   does not create a duplicate notification.

5. **The refill job is best-effort.**
   If it runs late, the 60-slot buffer absorbs the delay. If it fails, the next
   run (or the next app open) repairs the queue.

6. **Registration is idempotent.**
   Use one unique work name and `ExistingPeriodicWorkPolicy.keep`. Registering on
   every launch must not reset the schedule or create duplicates.

### 8.3 Why 30 minutes?

- Android's minimum periodic interval is ~15 minutes.
- 15 minutes spends more battery and scheduler quota for little benefit.
- With a 60-reminder buffer, 30 minutes is enough even for a habit repeating
  every 15 minutes: each run adds roughly two occurrences, so the window stays
  near full.
- Optional future refinement: adaptive frequency (15 minutes if any habit has an
  interval below 2 hours, otherwise 60 minutes). Keep v1 simple.

---

## 9. Implementation plan

### Phase 0 — Refactor prerequisites (no behaviour change)

**Goal:** one clear entry point for "compute plan and sync", without duplicate
syncs.

1. In `HabitScheduler`, split responsibilities:
   - `reconcile(now)` should optionally skip its fire-and-forget sync, or expose
     a `rollForwardDue(now)` method.
   - `sync(habits, now)` stays the single notification sync entry point.
   - `reconcileAndSync()` currently triggers **two** syncs: `reconcile()` starts
     an unawaited sync, then `reconcileAndSync()` awaits another one. Fix this
     while touching the class.
2. Add a narrow method for background use:

   ```dart
   Future<void> refillPlan({DateTime? now}) async {
     final habits = await _repo.getAll();
     await _notifications.ensureScheduled(_plan(habits, now ?? DateTime.now()));
   }
   ```

   This method must not update rows and must not call `reconcile()`.

3. In `NotificationService`, add:

   ```dart
   Future<void> ensureScheduled(List<ScheduledReminder> reminders) {
     final next = _tail.then((_) => _ensureScheduled(reminders));
     _tail = next.catchError((_) {});
     return next;
   }
   ```

   `_ensureScheduled` should:
   - read `pendingNotificationRequests()`;
   - build the wanted id set (skip past times);
   - schedule only ids not already pending;
   - **not** cancel stale ids (the UI sync owns cancellation);
   - **not** use the `_signature` early-return, because pending alarms can be
     dropped externally;
   - log `Background refill: X added, Y already pending`.

4. Tests for the new methods (fakes already exist in
   `test/habit_scheduler_test.dart`).

**Files:** `lib/core/logic/habit_scheduler.dart`,
`lib/data/services/notification_service.dart`, tests.

### Phase 1 — Add the background worker

1. Add `workmanager` to `pubspec.yaml` (latest version compatible with the
   project's Flutter/Dart SDK; verify its current API after install).
2. Create `lib/core/logic/reminder_refill.dart`:

   ```dart
   const reminderRefillTask = 'habitme.reminder-refill';
   const reminderRefillFrequency = Duration(minutes: 30);

   @pragma('vm:entry-point')
   void reminderRefillDispatcher() {
     Workmanager().executeTask((task, inputData) async {
       DartPluginRegistrant.ensureInitialized();
       WidgetsFlutterBinding.ensureInitialized();
       try {
         final repo = HabitRepository(AppDatabase.instance);
         final scheduler = HabitScheduler(repo, NotificationService.instance);
         await scheduler.refillPlan();
         return true;
       } catch (error, stackTrace) {
         debugPrint('Background reminder refill failed: $error');
         debugPrintStack(stackTrace: stackTrace);
         return true; // next periodic run is the retry
       }
     });
   }

   Future<void> registerReminderRefill() async {
     if (!Platform.isAndroid) return;
     await Workmanager().initialize(reminderRefillDispatcher);
     await Workmanager().registerPeriodicTask(
       reminderRefillTask,
       reminderRefillTask,
       frequency: reminderRefillFrequency,
       existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
       constraints: Constraints(networkType: NetworkType.not_required),
     );
   }
   ```

   Notes:
   - Exact API names/classes may differ slightly by plugin version; adapt to the
     installed version rather than copying blindly.
   - Wrap plugin initialisation in try/catch. A worker registration failure must
     never block app startup.
   - Do **not** call `NotificationService.clearDelivered()` here.

3. Register once during startup. Best place: `main()` after bindings and after
   the notification warm-up, or `HabitApp.initState` post-frame. Keep it
   unawaited so the first frame is not delayed.

4. Add a constant for the work name/frequency in `AppConstants` if preferred,
   so tests and logs share it.

**Files:** `pubspec.yaml`, `lib/main.dart` or `lib/app.dart`, new
`lib/core/logic/reminder_refill.dart`, possibly
`lib/core/constants/app_constants.dart`.

### Phase 2 — Remove the stale TODO and update docs

Only after device verification:

1. Delete the two `TODO(background)` lines.
2. Replace them with a short accurate comment, for example:

   ```dart
   // The 60-reminder window is topped up by a periodic WorkManager task
   // (see core/logic/reminder_refill.dart) while the app is closed.
   ```

3. Update:
   - `app/assets/docs/Project_Based/README_APP_HOW_IT_WORKS.md` (remove the
     "No background refresh" known gap; describe the worker and its limits);
   - `README_APP_PROJECT_STRUCTURE.md` (boot order, providers/services, file
     tree);
   - `README_APP_WORKFLOW.md` (time-passing flow, debugging section, release
     checklist);
   - this document's status to "Implemented" with the verified date.

### Phase 3 — Device verification and rollout

See sections 11 and 12.

---

## 10. Edge cases and decisions

| Case | Decision |
| --- | --- |
| App open while the worker runs | Read-only refill; no DB writes; stable ids make duplicate scheduling harmless. UI sync remains authoritative. |
| Notifications denied | `ensureScheduled` may still arm alarms; if permission is denied, `clearDelivered`/UI handles re-arm after grant. Worker must not crash. |
| Exact alarms blocked | Existing fallback to `inexactAllowWhileIdle` continues; refill is independent. |
| Limited series finished | Planner returns no future occurrences; nothing added. |
| One-time habit completed | Not included by the planner (`isDone` / past time). |
| Past reminders | Skipped by `ensureScheduled` (`at <= now`). |
| Database locked by UI | `sqflite` serialises access; worker catches errors and returns success; next run retries. |
| Timezone change | Existing `zonedSchedule` path is used; a refill after travel recomputes occurrences from local `DateTime`. Test manually. |
| Reboot | WorkManager persists its job; boot receiver restores alarms; worker tops up later. |
| Force-stop | Android suspends the app and its jobs until launch. Document as an OS limitation. |
| OEM battery saver | May delay work. Document; exact alarms still deliver what is armed. |
| iOS | Not part of v1. A future BGTaskScheduler task can reuse `refillPlan()`. |
| Multiple app versions / changed worker name | Changing the unique work name creates a new job; use `keep` and avoid renaming. If frequency changes, cancel + register once under a versioned name. |

### Concurrency note

`NotificationService`'s queue and flags are per isolate. The worker and the UI
are separate isolates, so they cannot share `_tail` or `_initialSyncDone`.
`ensureScheduled()` therefore treats the **OS pending list** as the source of
truth. Platform calls are serialised inside each isolate; the plugin's channel
handles the rest. Stable ids make overlapping schedules idempotent.

---

## 11. Testing plan

### 11.1 Unit tests (fast, no device)

- `refillPlan()`:
  - loads habits once;
  - computes the same plan as `computePlan()`;
  - calls `ensureScheduled()` exactly once;
  - performs no repository writes.
- `ensureScheduled()` (with a fake/injected notification layer if needed):
  - schedules only missing ids;
  - does not cancel stale ids;
  - skips past occurrences;
  - no-ops when the pending set already contains everything.
- Planner regression:
  - limited series produces no extras after its count;
  - fairness/reservation unchanged.
- Run `flutter analyze` and the full `flutter test` suite (currently 48 tests).

### 11.2 Device tests (debug build)

1. **Worker registration**
   - `adb shell dumpsys jobscheduler | grep -i habitme` — confirm a periodic job
     exists.
2. **Force a run**
   - Find the job id in `dumpsys`, then:
     `adb shell cmd jobscheduler run -f com.itsmeprince.habitme <jobId>`.
   - Confirm the Logs page shows a refill summary.
3. **Empty-queue recovery**
   - With the app terminated, cancel pending notifications (debug helper or
     `adb`), force the worker, and confirm the pending count rises toward 60.
4. **No duplicates**
   - Let the worker run twice, then open the app; confirm there are no duplicate
     alarms/notifications.
5. **Delivered reminders**
   - Leave a notification in the shade, run the worker; confirm it is **not**
     cleared.
6. **Exact-alarm denied**
   - Revoke exact alarm access; confirm reminders still schedule inexactly and
     refill logs success.
7. **Reboot**
   - Device reboot with a partially filled queue; confirm alarms restore and the
     worker remains registered.
8. **Battery saver / OEM**
   - Test with battery saver on; record delay. Do not promise exact timing.
9. **Frequency smoke test**
   - Temporarily set the debug frequency to 15 minutes; verify repeated runs
     without duplicated notifications, then restore 30 minutes.

### 11.3 Regression checklist

- app launch/resume sync unchanged;
- add/edit/delete/toggle/import still re-sync;
- notification **Done** still works with the app dead;
- 60-reminder cap still respected;
- no database `locked` errors in Logs;
- analyze + tests clean.

---

## 12. Observability and rollout

- Every worker run logs one line:
  `Background refill: X added, Y already pending, Z habits, N plan entries`.
- Failures log the exception and stack trace to `debugPrint` → `AppLog`.
- Optional: persist `last_refill_at` in `SharedPreferences` and show it on the
  Logs page, so support can confirm the worker is alive without `adb`.
- No feature flag is required for v1. If OEM issues appear, a compile-time
  constant can disable registration without touching the UI.
- Release notes: "Reminders keep refilling while the app is closed."
- Do not claim guaranteed exact refill timing.

---

## 13. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Worker delayed by Doze/OEM | Medium | Low (60-slot buffer) | 30-min cadence, exact alarms, document behaviour |
| Duplicate notifications | Low | Medium | Stable ids; `ensureScheduled` only adds missing; device tests |
| UI/worker database race | Low | Medium | Read-only worker; no reconcile writes |
| Worker registration failure | Low | Medium | try/catch; app still works with existing sync; log it |
| Plugin incompatibility with AGP/Flutter version | Low | Medium | Pin a compatible version; native WorkManager fallback |
| Battery complaints | Low | Medium | 30-min minimum, no network/battery constraints triggered, tiny workload |
| Existing double-sync wastes battery | Already present | Low | Fix `reconcileAndSync()` in Phase 0 |
| Users expect instant delivery after a long absence | Medium | Low | Buffer + docs; exact alarms still deliver armed reminders |

---

## 14. Acceptance criteria

- [ ] A periodic WorkManager job is registered exactly once on Android.
- [ ] With the app terminated, forcing the worker adds missing reminders toward
      the 60-reminder cap.
- [ ] Running the worker repeatedly creates no duplicate alarms or notifications.
- [ ] The worker never cancels pending reminders and never clears delivered
      notifications.
- [ ] The worker performs no habit database writes.
- [ ] Failures are logged and do not crash the app or the worker.
- [ ] `flutter analyze` and all tests pass.
- [ ] Both `TODO(background)` comments are replaced with an accurate note.
- [ ] App docs no longer list "No background refresh" as an open gap.
- [ ] Device verification covers force-run, empty queue, reboot, exact-alarm
      denied and duplicate checks.

---

## 15. Effort breakdown

| Phase | Work | Estimate |
| --- | --- | --- |
| 0 | Scheduler/notification refactor + unit tests | 0.5 day |
| 1 | Plugin setup, worker, registration, logging | 0.5 day |
| 2 | Docs + TODO cleanup | 0.25 day |
| 3 | Device verification and fixes | 0.5 day |
| **Total** | | **~1.5–2 days** |

---

## 16. Open questions

1. Is 30 minutes the right cadence, or should it be adaptive (15 minutes when a
   habit repeats faster than every 2 hours)?
2. Is iOS in scope now? If not, the worker should register on Android only.
3. Should the existing double sync in `reconcileAndSync()` be fixed in the same
   change, or as a separate cleanup?
4. Do we want a debug-only "run refill now" action in the Logs page to make
   support/debugging easier?

---

## 17. References

- `lib/core/logic/habit_scheduler.dart` — planning, reconcile, `onReminderFired`
- `lib/app.dart` — lifecycle, due ticker, TODO
- `lib/data/services/notification_service.dart` — scheduling, stable ids, sync
- `lib/data/services/notification_action_handler.dart` — background isolate pattern
- `lib/core/logic/habit_controller.dart` — state + sync entry points
- `lib/data/db/app_database.dart` — schema v4
- `android/app/src/main/AndroidManifest.xml` — permissions and receivers
- `app/assets/docs/Project_Based/README_APP_HOW_IT_WORKS.md` — known gap
- Android WorkManager periodic work (15-minute minimum, deferrable)
- Flutter `workmanager` plugin (Dart callback isolate)

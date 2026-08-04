# TitanFit Functional Specifications

Functional requirements per feature. Each section gives the **purpose**, the **primary user flows**, the
**acceptance criteria** at a glance, and the **current status** — all grounded in the actual code.

Legend: **Implemented** · **Partial** (works but with caveats) · **UI only** · **Backlog** (not started).

References are `file:line`-style so each claim is verifiable.

---

## 1. Authentication

**Purpose.** Trusted identity: users create an account, log in, keep a session alive, and log out,
with server-side revocation.

**Primary user flows**
1. **Register** — email + password (≥6 chars) + name → account created, token pair issued, user lands on
   the dashboard.
2. **Login** — email + password verified → token pair issued, token persisted, redirect to dashboard
   (`apps/mobile/lib/features/auth/presentation/screens/login_screen.dart:41-45`).
3. **Session restore** — app start checks for a stored token, calls `GET /users/profile`, and routes to
   `/dashboard` or `/login` (`auth_provider.dart:45-58`, `core/router/app_router.dart:27-37`).
4. **Silent refresh** — on any `401`, the Dio interceptor trades the stored refresh token for a new pair
   and retries the original request (`core/network/api_client.dart:26-59`).
5. **Logout** — `POST /auth/logout` invalidates the server refresh token; local storage is cleared;
   redirect to `/login` (`profile_screen.dart:28-33`).

**Acceptance criteria**
- Password hashing with bcrypt cost 12 (`apps/api/src/services/auth.service.ts:12`).
- Access token TTL 15m; refresh token TTL 7d, rotated on every refresh and login
  (`apps/api/src/config/index.ts:10-11`).
- Server-side revocation on logout: `User.refreshToken = null`
  (`apps/api/src/services/auth.service.ts:64-69`).
- Ownership-scoped, validated: duplicate email → `400`; bad credentials → `401`
  (`auth.service.ts:9-10`, `auth.controller.ts:52`).
- Tokens travel in the body (mobile stores them in `flutter_secure_storage`).

**Current status: Implemented (API); partial on device.**
- The API implements register/login/refresh/logout with rotating tokens (see
  [`docs/api/README.md`](../api/README.md#2-authentication)).
- ⚠️ The mobile register flow is **local-only**: it stores a plaintext password under `local_users` and
  mints a fake `local_token_*`; it never calls `/auth/register`
  (`apps/mobile/lib/features/auth/data/repositories/auth_repository.dart:47-75`). Login checks local
  users first, then the API (`auth_repository.dart:19-45`). This is a documented security/architecture
  gap (audit A5, SE&#8209;related).

---

## 2. Dashboard

**Purpose.** Home screen that orients the user: greeting, level, streak/discipline cards, today's stats,
and proactive health recommendations.

**Primary user flows**
1. On load, fetch aggregated stats (`GET /progress/stats`) via `dashboardProvider.loadStats()`
   (`dashboard_screen.dart:31-33`, `dashboard_provider.dart:33-41`).
2. Compute health insights from live workout + sleep provider state: a **sleep recommendation** and a
   **rest-day suggestion** (`core/services/health_insights.dart`).
3. Navigate to the 5 main tabs (dashboard/workouts/habits/sleep/progress) via the bottom shell
   (`core/router/app_router.dart:52-95,108-121`).

**Acceptance criteria**
- Greeting card shows name and level (`dashboard_screen.dart:52,84`).
- Stat cards surface `currentStreak`, `disciplineScore`, `totalWorkouts`, `totalSleepRecords`,
  `totalHabitsCompleted` (`dashboard_screen.dart:91-126`).
- Rest-day suggestion flags `consecutiveDays >= 4` or `weekCount >= 6` with `shouldRest: true`
  (`health_insights.dart:107-172`).
- Empty data does not crash — stat cards fall back to `?? 0`.

**Current status: Implemented.**
- UI and insight engine are wired to real providers. ⚠️ The notifications bell has an empty
  `onPressed: () {}` (`dashboard_screen.dart:71`) and there is no pull-to-refresh (audit A8/AC8).

---

## 3. Workouts + Session

**Purpose.** Log, browse, and execute workouts: full CRUD with an exercise library, plus a live workout
session with a timer, set/rep tracking, rest countdown, and XP rewards.

**Primary user flows**
1. **Browse** — paginated list (`GET /workouts`) rendered on the Workouts tab (`workout_screen.dart:25`,
   `workout_provider.dart:38-46`); tabs split "My Workouts" and the curated `exerciseLibrary`
   (`workout_screen.dart:57-67`, `exercise_library.dart`).
2. **Create** — modal enters title + optional goal/date/duration/calories/notes + exercises; `POST
   /workouts` with nested `exercises`; +50 XP server-side (`workout.service.ts:45-71`).
3. **Detail & edit** — single workout view with exercises (`workout_detail_screen.dart`); delete and
   add-exercise actions.
4. **Session** — start a session from a workout; per-second timer, pause/resume, log sets
   (`logSet`), 90s rest countdown with skip, exercise navigation, completion summary
   (`workout_session_provider.dart:98-205`).
5. **End session** — summary is built locally (`endSession`) and, when online, persisted back as a
   workout; estimated calories = `(elapsed ~/ 60) * 7` (`workout_session_provider.dart:181-205`).

**Acceptance criteria**
- CRUD ownership-scoped: `where: { id, userId }` → other users see `404`
  (`workout.service.ts:20-24`).
- Nested exercises persist in `order` (defaults to 1-based) and come back ordered
  (`workout.service.ts:54-66`, `:9`).
- `endSession` returns `{ title, duration, calories, exercises, totalSets, totalReps }`
  (`workout_session_provider.dart:192-204`).
- Consecutive-day tracking drives the rest-day insight (`health_insights.dart:120-145`).

**Current status: Implemented.**
- Session timer/rest/set tracking is the most complete feature in the app. ⚠️ `PUT /workouts/:id` is
  unvalidated (backlog), and `startSession` does not cancel a previously running timer
  (`workout_session_provider.dart:98-114`, audit S6).

---

## 4. Habits + Streaks

**Purpose.** Daily discipline: check off seven habit types each day, accumulate streak and discipline
scores, and view monthly history.

**Primary user flows**
1. **Today's habits** — `GET /habits` returns the day's completions; the Habits tab renders the 7 fixed
   habit types with done states (`habits_screen.dart:33-40`, `habit_provider.dart:34-42`).
2. **Check-in** — tap a habit → `POST /habits/checkin` creates a completion (or toggles one off);
   +25 XP and streaks recomputed server-side (`habit.service.ts:54-65`).
3. **Streaks & discipline** — `GET /habits/streaks` → `{ currentStreak, longestStreak, disciplineScore }`
   (`habit.service.ts:68-74`); discipline = weighted blend of streaks, capped at 100
   (`utils/helpers.ts:15-23`).
4. **Monthly view** — `GET /habits/monthly?year&month` returns the month ascending
   (`habit.service.ts:21-30`).

**Acceptance criteria**
- One row per `(user, type, date)` — unique index enforces idempotency (`schema.prisma:120`).
- A new completion recomputes `currentStreak` (consecutive days ending today) and
  `longestStreak` (`habit.service.ts:76-115`).
- Streak type values: `WAKE_UP_EARLY | WORKOUT_COMPLETED | DRINK_WATER | EAT_HEALTHY | SLEEP_ON_TIME |
  STRETCH | MEDITATE` (`schema.prisma:25-33`, `habit_model.dart:30-41`).

**Current status: Partial.**
- Server-side streaks and discipline are implemented and correct.
- ⚠️ The mobile `habit_repository.getStreaks()` returns hard-coded zeros
  (`habit_repository.dart:37-43`), so streak cards never show real data; monthly history is fetched by the
  API but not surfaced in the app UI (audit A6).

---

## 5. Sleep

**Purpose.** Track sleep sessions, visualize the week, and get a personalized sleep score and
recommendation.

**Primary user flows**
1. **Record** — bottom sheet takes bedtime/wake-up; `POST /sleep` computes duration + score, returns a
   record, awards +30 XP (`sleep.service.ts:5-21`).
2. **History** — `GET /sleep/history?days` (default 7) → records + `avgScore`, `avgDuration`,
   `totalRecords`; loaded by `SleepProvider.loadHistory()` (`sleep_provider.dart:46-61`).
3. **Week chart + recommendations** — `fl_chart` weekly bars and the insights banner
   (`sleep_screen.dart:47-56`, `health_insights.dart:44-105`).
4. **Stats** — `GET /sleep/stats` → all-time `totalRecords`, `avgScore`, `avgDuration`, recent 7.

**Acceptance criteria**
- Reject `wakeTime ≤ sleepTime` (`sleep.service.ts:11`).
- Score ladder 100/75/50/25 by duration bands (`utils/helpers.ts:25-31`).
- Sleep insight surfaces: on-track (good), sleep debt / oversleeping (poor ≥3 short nights in 7d or avg
  out of 6–10h), recover-tonight (fair) (`health_insights.dart:59-104`).
- Duration computed to 1 decimal in hours (`sleep.service.ts:8-9`).

**Current status: Implemented.**
- Full server flow + mobile chart/records. ⚠️ `SleepRecord.duration` is stored as `Int` in Postgres, so
  fractional hours (e.g. 7.5) truncate on round-trip (audit P7).

---

## 6. Progress

**Purpose.** Long-term view: overall stats, workout volume, sleep quality, achievements, and body stats.

**Primary user flows**
1. **Load aggregate** — `GET /progress/stats` fans out user/workout/sleep/habit/achievement queries
   (`progress.service.ts:4-25`, `progress_provider.dart:33-41`).
2. **Charts** — Workout Volume and Sleep Quality sections (`progress_screen.dart:65-91`).
3. **Achievements** — grid of unlocked `UserAchievement` rows (`progress_screen.dart:73-75`).
4. **Body stats** — height/weight from the current user profile.

**Acceptance criteria**
- Aggregate response contains `user`, `totalWorkouts`, `totalWorkoutDuration`, `totalCaloriesBurned`,
  `weeklyWorkouts`, `avgSleepScore`, `avgSleepDuration`, `totalSleepRecords`, `totalHabitsCompleted`,
  `weeklyHabitsCompleted`, `achievements` (`progress.service.ts:35-85`).
- Achievement titles are enum-constrained (`schema.prisma:35-45`).

**Current status: Partial.**
- ⚠️ `ProgressScreen` renders charts from **fabricated `Random(42)` / `Random(7)` data**, not the real
  stats (`progress_screen.dart:125,180`); offline fallback injects hard-coded averages
  (`progress_repository.dart:36-47`). Stat header reads `totalHabits` but the API returns
  `totalHabitsCompleted` (`progress_screen.dart:56`). This is a data-honesty backlog item (audit A4/P0).

---

## 7. Profile

**Purpose.** View identity, gamification state (level/XP/streak), and edit body measurements; entry point
to reminders and logout.

**Primary user flows**
1. **View** — avatar initial, name/email, level, XP, streak, age, height/weight, fitness level
   (`profile_screen.dart:40-106`).
2. **Edit body data** — tap edit on Height/Weight tiles → dialog parses a positive number →
   `authProvider.updateProfile({field: value})` → `PUT /users/profile`
   (`profile_screen.dart:129-163`, `auth_provider.dart:93-98`).
3. **Reminders** — bell button navigates to `/reminders` (`profile_screen.dart:24-26`).
4. **Logout** — two logout affordances (app-bar and outlined button) both call `logout()`.

**Acceptance criteria**
- Profile reflects server truth via `GET /users/profile`.
- Editing height/weight persists through `PUT /users/profile` and refreshes the user in state.
- Update is Zod-validated server-side (optional fields, enums, positive numbers).

**Current status: Implemented (basic).**
- ⚠️ `updateProfile` swallows errors (`catch (_) {}` in `auth_provider.dart:97`); age/fitness-level/goals
  are displayed but not editable from this screen (audit S9).

---

## 8. Reminders / Notifications

**Purpose.** Scheduled on-device nudges (morning, workout, stretch, wind-down) that pair with a user
configurable reminder list.

**Primary user flows**
1. **Initialize** — `NotificationService().init()` at app start registers Android/iOS notification
   settings (`main.dart:8-9`, `notification_service.dart:11-23`).
2. **Configure** — the Reminders screen lists 4 default reminders (Wake Up 6:00, Workout 7:30, Stretch
   12:00, Wind Down 21:30) with enable toggles, time pickers, and weekday selection, all persisted to
   secure storage under `titan_reminders`
   (`reminders_screen.dart:41-63`, `data/models/reminder.dart:44-77`).

**Acceptance criteria**
- Reminder config survives app restarts (persisted JSON in `flutter_secure_storage`).
- Each reminder has a title, subtitle, icon, `TimeOfDay`, and day mask.

**Current status: UI only.**
- ⚠️ The four `schedule*` methods in `NotificationService` are **defined but never invoked** — no
  scheduled/zoned notifications, no Android 13 POST_NOTIFICATIONS permission request, and the persisted
  reminder config is never read back to schedule anything (audit A7).

---

## 9. Offline / Transitions

**Purpose.** Keep the app usable on flaky or absent networks by being local-first: every repository tries
the API and falls back to a `flutter_secure_storage` JSON cache (ADR-0001).

**Primary user flows / fallback matrix**

| Repository | Online | Offline fallback |
|---|---|---|
| Workout | `GET/POST/PUT/DELETE /workouts…` | cached list; creates get local timestamp ids; delete removes locally even on API failure (`workout_repository.dart:13-143`) |
| Habits | `GET /habits`, `POST /habits/checkin` | today's toggles stored under `local_habits` (`habit_repository.dart:13-98`) |
| Sleep | `POST /sleep`, `/history`, `/stats` | locally-scored records under `local_sleep` (`sleep_repository.dart:13-101`) |
| Auth | login → API | login first tries `local_users`; register is local-only (`auth_repository.dart:19-75`) |
| Dashboard/Progress | `GET /progress/stats` | aggregates the three local caches into a stat map (`dashboard_repository.dart:21-48`, `progress_repository.dart:21-48`) |

**Acceptance criteria**
- API failure never surfaces a raw crash — repositories catch and switch to cache.
- Offline state is immediately visible after a kill/relaunch (storage is persistent).
- Re-launch with network restores server truth on next `load*()` since the API is tried first.

**Current status: Partial.**
- ✅ Browsing and new local data survive offline for workouts/habits/sleep; auth session restore works
  offline for local users.
- ⚠️ **No sync/outbox**: data created offline is never pushed to the server; fake local tokens and
  fabricated offline stats mask real state; register never reaches the server (audit A5, A4). These are
  the top follow-ups after ADR-0001.
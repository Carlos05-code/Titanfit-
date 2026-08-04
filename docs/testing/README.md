# TitanFit Testing Strategy

This document describes how TitanFit is tested, what is covered where, how to run the suites, and how
tests integrate with CI. It reflects the current state of the repository as of **2026-08-05** and flags
the backlog items surfaced by [`docs/audit/repository_audit.md`](../audit/repository_audit.md).

---

## 1. The pyramid

TitanFit follows the classic **test pyramid**, weighted toward fast, deterministic unit tests:

```
        / Integration \       E2E device test (Android emulator → live Render API) — manual / dev-time
       /  (Flutter widget, \
      /    API contract)      Widget tests — targeted smoke coverage (planned backlog)
     /____________________\
   /  Unit tests            \   Mobile: validators + helpers today; state/rule engines next.
  /   (pure, fast, no IO)     \  API: jest for zod schemas, auth service (mocked Prisma), error handler.
 /____________________________\
```

1. **Unit tests** — the bulk of coverage. Pure functions and isolated state machines with no network/IO:
   Flutter validators, formatting helpers, the health-insights rule engine, the workout-session state
   machine; API-side zod schema parsing, `auth.service` against a mocked Prisma client, and the error handler.
2. **Widget tests** — Flutter component tests with `flutter_test` that pump widgets and assert rendering
   and interaction (login form validation, habit tile toggle, reminder switch). Currently planned, not yet in the repo.
3. **Integration / E2E** — the Flutter app booted on an **Android emulator talking to the live Render API**
   (`https://titanfit-api.onrender.com/api`). Performed manually during development to validate the real
   auth + data round-trip. See §5.

---

## 2. What is covered where

### 2.1 Mobile — currently implemented

| File | Unit under test | What it asserts |
|---|---|---|
| `apps/mobile/test/core/validators_test.dart` | `core/utils/validators.dart` | `Validators.email` (valid/missing/malformed), `Validators.password` (min 6, required), `Validators.name` (min 2, required), `Validators.required` (custom field label) |
| `apps/mobile/test/core/helpers_test.dart` | `core/utils/helpers.dart` | `formatDuration` (0/45/60/95/130 min), `formatDate` (month names), `formatTimeOfDay` (12h + AM/PM, midnight/noon edges), `greeting` (morning/afternoon/evening boundaries) |

### 2.2 Mobile — targeted next (unit) backlog

The following are the highest-value unit targets and are described in terms of their **lifecycle** so a
test author knows exactly the state transitions to exercise:

- **`core/services/health_insights.dart`** — `HealthInsights.analyzeSleep(List<SleepRecord>)` and
  `HealthInsights.suggestRestDay(List<WorkoutModel>, {sleepRecords})` are pure static functions ideal for
  table-driven tests:
  - `analyzeSleep` lifecycle: empty records → `null`; ≤7-day window empty → `null`; on-track
    (avg 7–9h, <3 short nights, last night ≥7h) → level `good`; chronic debt (≥3 short nights in 7d or
    avg < 6h) → `poor`; oversleeping (avg > 10h) → `poor`; single short last night → `fair`; near-miss
    avg → `fair`.
  - `suggestRestDay` lifecycle: no workouts → rest `false`; `consecutiveDays >= maxConsecutiveWorkouts`
    (4) → rest `true`; ≥6 workouts in 7d → rest `true`; ≥5 → `false` (positive message); else `false`.
- **`features/workout/presentation/providers/workout_session_provider.dart`** — the `WorkoutSessionNotifier`
  state machine:
  - `startSession` → `SessionStatus.active`, timer ticks increment `elapsedSeconds`, exercises mapped with
    target sets/reps/weight from the model.
  - `pauseSession` / `resumeSession` → status transitions preserve elapsed time.
  - `logSet` → appends a `TrackedSet`, sets `isResting = true` with a 90s countdown that reaches 0 and
    clears `isResting`; completing `targetSets` sets `isComplete`.
  - `skipRest`, `nextExercise` / `prevExercise` index boundaries.
  - `endSession` → `SessionStatus.completed`, returns `{ title, duration, calories, exercises, totalSets,
    totalReps }` with `calories = (elapsed ~/ 60) * 7`.
  - `reset` and `dispose` cancel timers (tests should use `fakeAsync`/`FakeAsync` to drive the
    `Timer.periodic` callbacks deterministically).
- **`features/.../data/repositories/*`** — offline-first fallback logic (see §2.4) against a mocked Dio
  client plus a stubbed `FlutterSecureStorage`.

### 2.3 API — planned jest unit tests

`npm test` currently runs `jest --passWithNoTests`, i.e. **no API tests exist yet**. The targets:

| Target | What to assert |
|---|---|
| Zod schemas (`controllers/*`) | register/login/refresh/update-profile/create-workout schemas accept valid input and reject invalid (bad email, short password, enums not in set, non-positive numbers) — assert the `details` error array shape |
| `services/auth.service.ts` | register duplicates email → throw; bcrypt hash applied; tokens generated and refresh token persisted; login bad password → `"Invalid credentials"`; refresh with mismatched/absent stored token → throw; refresh rotates the stored token; logout nullifies it — with a **mocked `prisma`** (`utils/prisma.ts`) |
| `services/workout.service.ts` | ownership-scoped lookups return `null`/404 for other users; create persists nested exercises in `order`; `getStats` aggregation; XP + level-up math (threshold every 1000 XP) |
| `middleware/errorHandler.ts` | dev vs production message masking |
| `middleware/auth.ts` | missing / malformed / expired bearer header → 401 envelope |

Jest runs from `apps/api` (TypeScript via `ts-jest`/`ts-node` — see `devDependencies`) and must not touch
a real database; inject a mock for `prisma` (e.g. `jest.mock('../utils/prisma')`).

### 2.4 Offline-first repositories (behavioral contract)

The mobile repositories are local-first: **try the API, fall back to `flutter_secure_storage` JSON**.
Tests should pin down this fallback contract per repository:

| Repository | On API failure it… |
|---|---|
| `workout_repository.dart` | returns cached `local_workouts`; `create` fabricates a local row with a timestamp id; `delete` removes locally even if the API call fails; `getStats` computes from cache |
| `habit_repository.dart` | `getToday`/`checkIn` toggle today's row in `local_habits`; `getStreaks` returns hard-coded zeroes (⚠️ not real — backlog) |
| `sleep_repository.dart` | `record` saves a locally-scored `SleepRecord`; `getHistory`/`getStats` recompute averages from `local_sleep` |
| `auth_repository.dart` | login first checks `local_users`, then the API; register is local-only and stores the password (⚠️ plaintext — see security backlog) |
| `dashboard_repository.dart` / `progress_repository.dart` | `getStats` aggregates `local_workouts`, `local_sleep`, `local_habits` into a stat map (fabricated averages ⚠️ — backlog) |

---

## 3. How to run

### Mobile (`apps/mobile`)

```bash
flutter pub get
flutter test                 # runs test/ (validators + helpers)
dart format --output=none --set-exit-if-changed .   # formatting gate (CI)
flutter analyze              # static analysis (CI)
```

### API (`apps/api`)

```bash
npm ci
npx prisma generate
npm run build                # tsc type-check + emit (strict)
npm test                     # jest — currently a no-op until unit backlog is written
```

---

## 4. CI integration

`.github/workflows/ci.yml` gates every push to `main` and every pull request (with a
`concurrency` group to cancel superseded runs). Three jobs:

| Job | Command chain | Applies to |
|---|---|---|
| **Backend · build + test** | `npm ci` → `prisma generate` → `prisma validate` → `npm run build` → `npm test` | `apps/api` (Node 22, npm cache) |
| **Mobile · format + analyze + test** | `flutter pub get` → `dart format --check` → `flutter analyze` → `flutter test` | `apps/mobile` (Flutter 3.35.6 stable) |
| **API · docker build** | `docker build -t titanfit-api:ci apps/api` | container image smoke |

Nothing is committed that bypasses CI: a red test, failed analyze, or unformatted file fails the pipeline.
The docker job double-checks the image that Render will actually build.

---

## 5. E2E device test (development-time)

During development the app was exercised **end-to-end on an Android emulator against the live API**:

1. `baseUrl` is `https://titanfit-api.onrender.com/api` (`apps/mobile/lib/core/constants/app_constants.dart`).
2. Run the app on the emulator (`flutter run`), register/login via the real auth endpoints, and walk the
   main flows: dashboard stats, create a workout (+ exercises), habit check-in, log sleep, progress view,
   logout.
3. Because access tokens expire every 15 minutes, the E2E pass also verifies the silent, automatic
   **refresh-on-401** in `core/network/api_client.dart` (`_tryRefreshToken` → retry with new token).
4. This run is a manual/device test today; formalizing it (e.g. `integration_test/`) is backlog.

---

## 6. Coverage expectations

- **Current:** coverage is limited to the two mobile unit files in §2.1. There is no coverage threshold
  enforced anywhere today, and CI does not emit coverage reports (`--collectCoverage` is not configured).
- **Target:**
  - Mobile: 100% of `core/utils/{validators,helpers}.dart` and `core/services/health_insights.dart`;
    high coverage of the `workout_session_provider` state machine and offline-repository fallbacks.
  - API: the units in §2.3, focusing on auth service behavior with a mocked Prisma (no integration DB).
  - Guard rails: add `flutter test --coverage` with a threshold (e.g. ≥80% on `lib/core` and
    `lib/features/*/presentation/providers`) and `jest --coverage --coverageThreshold` for the API;
    enforce both in CI before they can regress.
- **Non-goals for unit scope:** real Postgres integration tests do not run in CI; Prisma migrations are
  validated structurally (`prisma validate`) and applied at deploy time (see
  [`docs/deployment/README.md`](../deployment/README.md)).
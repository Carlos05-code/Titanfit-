# TitanFit REST API Reference

> Base URL (live): `https://titanfit-api.onrender.com`
> API root: all routes below are mounted under **`/api`** in `apps/api/src/routes/index.ts`.
> Health probe: `GET /health` (no `/api` prefix).

The API is an Express 4 + TypeScript (strict) + Prisma 6 + PostgreSQL application.
Validation is performed with **Zod** inside each controller (`apps/api/src/controllers/*.ts`).
Authentication uses **JWT access tokens** with **rotating refresh tokens** persisted in the database
(see [ADR-0002](../decisions/0002-token-rotation-auth.md)).

---

## 1. Conventions

### 1.1 Response envelope

Every endpoint (except `/health`) returns one of two envelope shapes (`apps/api/src/types/index.ts`):

```jsonc
// Success
{ "success": true, "data": <payload> }

// Success without a payload (logout, delete)
{ "success": true, "message": "Logged out successfully" }

// Failure
{ "success": false, "error": "<human readable message>" }

// Validation failure (Zod)
{
  "success": false,
  "error": "Validation failed",
  "details": [
    { "field": "body.email", "message": "Invalid email" }
  ]
}
```

- `success: true` → the request succeeded; read `data` (or `message`).
- `success: false` → the request failed; read `error`, and `details` when validation failed.
- Validation errors use the `details` array produced by `zod` (`apps/api/src/middleware/validate.ts` format:
  `{ field, message }`). Note: the `validate` middleware is defined but **not** wired to routes; controllers
  call `schema.parse(req)` directly and emit the same `details: error.errors` array.

### 1.2 Error codes

| Status | Meaning | When it happens |
|---|---|---|
| `200` | OK | Read/update/refresh/logout succeeded |
| `201` | Created | Register, workout create, sleep record |
| `400` | Bad Request | Zod validation failed, required field missing, wake ≤ sleep |
| `401` | Unauthorized | Missing/invalid/expired bearer token; bad credentials; invalid refresh token |
| `404` | Not Found | User or workout not found (ownership-scoped) |
| `500` | Internal Server Error | Unexpected error; raw `error.message` is returned in non-production |

Unhandled errors fall through to the global `errorHandler` (`apps/api/src/middleware/errorHandler.ts`),
which returns `error.message` in development and a generic `"Internal server error"` in production.

### 1.3 Pagination

Introduced by `GET /api/workouts`. Query parameters:

| Param | Type | Default | Notes |
|---|---|---|---|
| `page` | int | `1` | 1-based |
| `limit` | int | `20` | **Not capped** server-side (see hardening notes) |

Response shape:

```jsonc
{
  "workouts": [ /* Workout[] */ ],
  "total": 42,
  "page": 1,
  "totalPages": 3
}
```

### 1.4 Date & time

Timestamps are ISO-8601 strings via `DateTime.toISOString()` (Prisma `DateTime` → JSON string).
Sleep endpoints accept ISO-8601 date-time strings for `sleepTime` / `wakeTime`; date inputs that cannot
be parsed produce `Invalid Date` values (a known hardening gap — see audit).

---

## 2. Authentication

JWTs: access token TTL `JWT_EXPIRES_IN` (default **15m**), refresh token TTL `JWT_REFRESH_EXPIRES_IN`
(default **7d**), signed with separate secrets (`apps/api/src/config/index.ts`).

Token lifecycle (`apps/api/src/services/auth.service.ts`):

- `register` / `login` issue an access + refresh pair and store the refresh token on `User.refreshToken`.
- `refresh` verifies the presented refresh token **and** matches it against the stored value, then **rotates**
  it (a new pair is persisted). Replaying an old token after rotation is rejected.
- `logout` nullifies `User.refreshToken` → all server-side session state is revoked (single active session).
- The mobile client stores both tokens in `flutter_secure_storage` and transparently refreshes on `401`
  (`apps/mobile/lib/core/network/api_client.dart`).

**Authorization header for protected routes:**

```
Authorization: Bearer <accessToken>
```

---

### 2.1 Auth endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/register` | none | Create account, return user + token pair |
| POST | `/api/auth/login` | none | Verify credentials, return user + token pair |
| POST | `/api/auth/refresh` | none | Rotate refresh token, return new pair |
| POST | `/api/auth/logout` | ✅ bearer | Revoke refresh token on the server |

#### `POST /api/auth/register` — 201

```jsonc
// Request body
{
  "email": "titan@example.com",
  "password": "supersecret",
  "name": "Aegon"
}
```

| Field | Type | Rules |
|---|---|---|
| `email` | string | must be a valid email |
| `password` | string | `min(6)` |
| `name` | string | `min(2)` `max(50)` |

```jsonc
// 201 response
{
  "success": true,
  "data": {
    "user": {
      "id": "3f6b…", "email": "titan@example.com", "name": "Aegon",
      "createdAt": "2026-08-05T09:12:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs…",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs…"
  }
}
```

Errors: `400` duplicate email (`"Email already registered"`), `400` validation.

#### `POST /api/auth/login` — 200

```jsonc
{ "email": "titan@example.com", "password": "supersecret" }
```

```jsonc
{
  "success": true,
  "data": {
    "user": {
      "id": "3f6b…", "email": "titan@example.com", "name": "Aegon",
      "age": null, "gender": null, "height": null, "weight": null,
      "fitnessLevel": "BEGINNER", "goals": [],
      "xpPoints": 0, "level": 1, "disciplineScore": 0,
      "currentStreak": 0, "longestStreak": 0,
      "createdAt": "2026-08-05T09:12:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs…",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs…"
  }
}
```

`user` is the full safe profile (password and `refreshToken` are stripped). Errors: `400` validation,
`401` for bad credentials (`"Invalid credentials"`).

#### `POST /api/auth/refresh` — 200

```jsonc
{ "refreshToken": "eyJhbGciOiJIUzI1NiIs…" }
```

```jsonc
{
  "success": true,
  "data": { "accessToken": "eyJhbGciOiJIUzI1NiIs…", "refreshToken": "eyJhbGciOiJIUzI1NiIs…" }
}
```

Errors: `401` (`"Invalid or expired refresh token"`) — includes non-matching stored token, tampered JWT,
or expired TTL.

#### `POST /api/auth/logout` — 200 (bearer)

No body. The controller calls `authService.logout(userId)` which sets `User.refreshToken = null`.

```jsonc
{ "success": true, "message": "Logged out successfully" }
```

---

## 3. Users

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/users/profile` | ✅ bearer | Return authenticated user's profile |
| PUT | `/api/users/profile` | ✅ bearer | Update profile fields |

#### `GET /api/users/profile` — 200

Returns the authenticated user (same field set as `login.user`). Errors: `404` user not found, `500`.

#### `PUT /api/users/profile` — 200

All fields optional — this is a full-replace-style `PUT`; a **planned future improvement is `PATCH`** for
partial updates. Body and validation (`apps/api/src/controllers/user.controller.ts`):

| Field | Type | Rules |
|---|---|---|
| `name` | string | `min(2)` `max(50)` |
| `age` | number (int) | `min(13)` `max(120)` |
| `gender` | string | one of `male` \| `female` \| `other` |
| `height` | number | positive (cm) |
| `weight` | number | positive (kg) |
| `fitnessLevel` | string | `BEGINNER` \| `INTERMEDIATE` \| `ADVANCED` \| `ATHLETE` |
| `goals` | string[] | subset of `MUSCLE_GAIN` \| `FAT_LOSS` \| `ENDURANCE` \| `STRENGTH` \| `GENERAL_FITNESS` |

```jsonc
// Request
{ "age": 34, "weight": 88.5, "fitnessLevel": "INTERMEDIATE", "goals": ["MUSCLE_GAIN", "STRENGTH"] }

// 200 response
{
  "success": true,
  "data": {
    "id": "3f6b…", "email": "titan@example.com", "name": "Aegon",
    "age": 34, "gender": null, "height": null, "weight": 88.5,
    "fitnessLevel": "INTERMEDIATE", "goals": ["MUSCLE_GAIN", "STRENGTH"],
    "xpPoints": 50, "level": 1, "disciplineScore": 0,
    "currentStreak": 0, "longestStreak": 0, "createdAt": "2026-08-05T09:12:00.000Z"
  }
}
```

Errors: `400` validation (`details` array), `500`.

---

## 4. Workouts

The `Workout` resource has a one-to-many `Exercise` child. Creating a workout with nested `exercises`
persists them in a single call; they are always returned ordered by `order` ascending.

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/workouts/stats` | ✅ bearer | Aggregate totals + recent 7 workouts |
| GET | `/api/workouts?page&limit` | ✅ bearer | Paginated list, newest first |
| GET | `/api/workouts/:id` | ✅ bearer | Single workout + exercises |
| POST | `/api/workouts` | ✅ bearer | Create workout (optionally with exercises), +50 XP |
| PUT | `/api/workouts/:id` | ✅ bearer | Update top-level workout fields |
| DELETE | `/api/workouts/:id` | ✅ bearer | Delete workout (cascades exercises) |

All lookups are **ownership-scoped** (`where: { id, userId }`); a workout belonging to another user
surfaces as `404`.

#### `GET /api/workouts?page=1&limit=20` — 200

```jsonc
{
  "success": true,
  "data": {
    "workouts": [
      {
        "id": "w1", "userId": "3f6b…", "title": "Upper Body",
        "goal": "STRENGTH", "date": "2026-08-05T07:00:00.000Z",
        "duration": 60, "calories": 420, "notes": "RPE 8",
        "createdAt": "2026-08-05T07:00:00.000Z", "updatedAt": "2026-08-05T07:00:00.000Z",
        "exercises": [
          { "id": "e1", "workoutId": "w1", "name": "Bench Press", "sets": 4, "reps": 8,
            "weight": 80, "duration": null, "calories": null, "order": 1 }
        ]
      }
    ],
    "total": 1, "page": 1, "totalPages": 1
  }
}
```

#### `GET /api/workouts/stats` — 200

```jsonc
{
  "success": true,
  "data": {
    "totalWorkouts": 12,
    "totalDuration": 720,            // minutes, summed
    "totalCalories": 5000,           // kcal, summed
    "recent": [                      // newest 7
      { "date": "2026-08-05T07:00:00.000Z", "duration": 60, "calories": 420 }
    ]
  }
}
```

#### `POST /api/workouts` — 201

`title` required; everything else optional. `exercises[].name` required; `order` defaults to
position (1-based). Creating a workout awards **+50 XP** and may level the user up.

```jsonc
// Request
{
  "title": "Push Day",
  "goal": "STRENGTH",
  "date": "2026-08-05T07:00:00.000Z",
  "duration": 75,
  "calories": 500,
  "notes": "Good pump",
  "exercises": [
    { "name": "Bench Press", "sets": 4, "reps": 8, "weight": 80 },
    { "name": "Overhead Press", "sets": 3, "reps": 10, "weight": 50 }
  ]
}
```

```jsonc
// 201 response — created workout, exercises attached, ordered
{
  "success": true,
  "data": { "id": "w2", "userId": "3f6b…", "title": "Push Day", "goal": "STRENGTH",
    "date": "2026-08-05T07:00:00.000Z", "duration": 75, "calories": 500, "notes": "Good pump",
    "createdAt": "…", "updatedAt": "…",
    "exercises": [
      { "id": "e3", "workoutId": "w2", "name": "Bench Press", "sets": 4, "reps": 8, "weight": 80, "duration": null, "calories": null, "order": 1 },
      { "id": "e4", "workoutId": "w2", "name": "Overhead Press", "sets": 3, "reps": 10, "weight": 50, "duration": null, "calories": null, "order": 2 }
    ] }
}
```

#### `GET /api/workouts/:id` — 200

Single workout with ordered `exercises`. Errors: `404` (`"Workout not found"`).

#### `PUT /api/workouts/:id` — 200

Accepts a **partial** object of top-level fields (`title`, `goal`, `date`, `duration`, `calories`, `notes`)
spread directly into Prisma — **not Zod-validated** (known gap; see hardening notes). Exercises are
not updated via this route. Errors: `404`.

#### `DELETE /api/workouts/:id` — 200

```jsonc
{ "success": true, "message": "Workout deleted" }
```

Errors: `404`.

---

## 5. Habits

A `Habit` row is one completion of one habit type on one calendar day
(unique on `(userId, type, date)`). Habit types (`apps/api/prisma/schema.prisma`):

```
WAKE_UP_EARLY | WORKOUT_COMPLETED | DRINK_WATER | EAT_HEALTHY | SLEEP_ON_TIME | STRETCH | MEDITATE
```

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/habits?date` | ✅ bearer | Habits for today (or `date=YYYY-MM-DD`) |
| GET | `/api/habits/monthly?year&month` | ✅ bearer | All habit completions in a month, ascending |
| GET | `/api/habits/streaks` | ✅ bearer | Streak + discipline aggregate |
| POST | `/api/habits/checkin` | ✅ bearer | Create completion, or toggle an existing one |

#### `GET /api/habits?date=2026-08-05` — 200

```jsonc
{
  "success": true,
  "data": [
    { "id": "h1", "userId": "3f6b…", "type": "WAKE_UP_EARLY", "completed": true,
      "date": "2026-08-05T00:00:00.000Z", "createdAt": "2026-08-05T05:59:00.000Z" }
  ]
}
```

#### `GET /api/habits/monthly?year=2026&month=8` — 200

Same item shape; ordered by `date` ascending across the whole month.

#### `POST /api/habits/checkin` — 200

```jsonc
// Request — `type` required; `date` optional (defaults to today)
{ "type": "DRINK_WATER", "date": "2026-08-05" }
```

Semantics (idempotent toggle): if a row for `(user, type, date)` exists it is flipped
(`completed: !completed`); otherwise a `completed: true` row is created and the user is awarded **+25 XP**.
A new completion also recomputes streaks + discipline score.

```jsonc
{ "success": true, "data": { "id": "h2", "userId": "3f6b…", "type": "DRINK_WATER",
  "completed": true, "date": "2026-08-05T00:00:00.000Z", "createdAt": "…" } }
```

Errors: `400` (`"Habit type is required"`), `500`.

#### `GET /api/habits/streaks` — 200

```jsonc
{ "success": true, "data": { "currentStreak": 5, "longestStreak": 12, "disciplineScore": 78 } }
```

`disciplineScore` = min(100, round(workoutStreak×0.4 + habitStreak×0.35 + sleepConsistency×0.25))
(`apps/api/src/utils/helpers.ts`). Note: the mobile client currently returns hard-coded zeroes for this
endpoint (`apps/mobile/lib/features/habits/data/repositories/habit_repository.dart`).

---

## 6. Sleep

A `SleepRecord` captures one sleep session. `duration` is computed from `wakeTime - sleepTime` in hours
(rounded to 1 decimal) and a `score` is derived. **Known limitation:** the schema stores `duration` as
`Int`, so fractional hours are truncated in Postgres.

Score ladder (`calculateSleepScore`):

| Duration (h) | Score |
|---|---|
| 7 – 9 | 100 |
| 6 – <7 · 9 – 10 | 75 |
| 5 – <6 · >10 | 50 |
| everything else | 25 |

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/sleep` | ✅ bearer | Record a sleep session (+30 XP) |
| GET | `/api/sleep/history?days` | ✅ bearer | Last `days` records + averages (default 7) |
| GET | `/api/sleep/stats` | ✅ bearer | All-time aggregates + recent 7 |

#### `POST /api/sleep` — 201

```jsonc
// Request
{ "sleepTime": "2026-08-05T22:15:00.000Z", "wakeTime": "2026-08-06T06:15:00.000Z" }

// 201 response
{ "success": true, "data": { "id": "s1", "userId": "3f6b…",
  "sleepTime": "2026-08-05T22:15:00.000Z", "wakeTime": "2026-08-06T06:15:00.000Z",
  "duration": 8, "score": 100, "createdAt": "…" } }
```

Errors: `400` missing fields, `400` (`"Wake time must be after sleep time"`), `400` invalid dates.

#### `GET /api/sleep/history?days=7` — 200

```jsonc
{
  "success": true,
  "data": {
    "records": [ { "id": "s1", "userId": "3f6b…", "sleepTime": "…", "wakeTime": "…",
      "duration": 8, "score": 100, "createdAt": "…" } ],
    "avgScore": 88,
    "avgDuration": 7.6,
    "totalRecords": 5
  }
}
```

#### `GET /api/sleep/stats` — 200

```jsonc
{
  "success": true,
  "data": {
    "totalRecords": 34,
    "avgScore": 82,
    "avgDuration": 7.4,
    "recent": [ /* last 7 SleepRecord objects */ ]
  }
}
```

---

## 7. Progress

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/progress/stats` | ✅ bearer | Aggregated dashboard: user + workout/sleep/habit stats + achievements |
| GET | `/api/progress/weight` | ✅ bearer | Current weight + height snapshot |

#### `GET /api/progress/stats` — 200

Fans out 5 parallel queries (`apps/api/src/services/progress.service.ts`):

```jsonc
{
  "success": true,
  "data": {
    "user": { "id": "3f6b…", "name": "Aegon", "email": "…", "age": 34, "gender": null,
      "height": null, "weight": 88.5, "fitnessLevel": "INTERMEDIATE",
      "goals": ["MUSCLE_GAIN"], "xpPoints": 105, "level": 1, "disciplineScore": 78,
      "currentStreak": 5, "longestStreak": 12, "createdAt": "…" },
    "totalWorkouts": 12,
    "totalWorkoutDuration": 720,
    "totalCaloriesBurned": 5000,
    "weeklyWorkouts": [ { "date": "…", "duration": 60, "calories": 420 } ],
    "avgSleepScore": 82,
    "avgSleepDuration": 7.4,
    "totalSleepRecords": 34,
    "totalHabitsCompleted": 41,
    "weeklyHabitsCompleted": 9,
    "achievements": [ { "id": "a1", "userId": "3f6b…", "title": "FIRST_WORKOUT",
      "unlockedAt": "…", "createdAt": "…" } ]
  }
}
```

`UserAchievement.title` values: `SEVEN_DAY_WARRIOR`, `THIRTY_DAY_BEAST_MODE`, `EARLY_RISER`,
`STRENGTH_MASTER`, `ENDURANCE_KING`, `DISCIPLINE_TITAN`, `HYDRATION_HERO`, `SLEEP_CHAMPION`,
`FIRST_WORKOUT`, `HUNDRED_WORKOUTS`.

#### `GET /api/progress/weight` — 200

Returns the current body snapshot, not a time-series (no historical weight log yet).

```jsonc
{ "success": true, "data": { "weight": 88.5, "height": 183.0,
  "createdAt": "…", "updatedAt": "…" } }
```

---

## 8. Health

`GET /health` — no auth, no envelope (by design):

```jsonc
{ "status": "ok", "timestamp": "2026-08-05T09:12:00.000Z" }
```

Used by Render's health check and `docker compose` readiness.

---

## 9. Status code summary

| Code | Used by |
|---|---|
| `200` | all reads/updates, refresh, logout, checkin, streaks, stats |
| `201` | register, create workout, record sleep |
| `400` | zod validation, missing required fields, wake ≤ sleep, duplicate email on register |
| `401` | missing / invalid / expired token; invalid credentials; invalid refresh token |
| `404` | missing user or workout (ownership-scoped) |
| `500` | unexpected server errors (masked in production) |
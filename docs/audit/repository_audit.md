# TitanFit — Repository Audit

> **Audit date:** 2026-08-05
> **Auditor:** Lead Staff Software Engineer (automated + manual review)
> **Repo:** `Carlos05-code/Titanfit-` (default branch `main`, 9 commits, 228 tracked files)
> **Scope:** Entire monorepo — Flutter mobile app (`lib/`, 58 Dart files, ~6.7k LOC), Node/TS/Prisma backend (`backend/`, 26 TS files), documentation, configuration, CI/CD, git history, assets.

---

## Executive Summary

TitanFit is a fitness-tracking product with a **genuinely strong core**: a feature-first Flutter app using Riverpod + go_router + Dio, and a cleanly layered Express + Prisma + Zod + JWT backend, already containerized and deployed to a live PostgreSQL-backed Render service with working migrations and end-to-end auth.

However, the repository is **not yet portfolio-grade** in these dimensions:

| Area | Verdict | Headline finding |
|---|---|---|
| Code structure (Flutter) | ✅ Strong | Feature-first `features/<feature>/presentation,data` already in place |
| Code structure (Backend) | ✅ Strong | Controllers → services → Prisma, ownership-scoped queries |
| README / docs | ❌ Broken | README is `flutter create` boilerplate **corrupted with appended UTF-16 bytes**; no `docs/` |
| Tests | ❌ Absent | 1 empty widget test; backend `jest --passWithNoTests`; `prisma:seed` points at a missing file |
| CI/CD | ❌ Absent | No `.github/`, no Actions, no badges |
| LICENSE | ❌ Absent | No license file, no `license:` in pubspec |
| App identity | ⚠️ Default | `com.example.fitness`, "fitness", "A new Flutter project." everywhere |
| Dead code | ⚠️ Significant | 9/16 runtime deps unused; leftover e-commerce models; duplicate `AppColors`; unused error taxonomy |
| Data honesty | ⚠️ Misleading | Progress screen renders `Random()` charts as real user data |
| Security | ⚠️ Hardening | Hardcoded JWT fallback secrets; no helmet/rate-limit; raw errors leaked; unvalidated `PUT /workouts/:id` |
| Assets | ❌ Broken | `assets/images`, `assets/icons` declared in pubspec but empty/untracked |

---

## Scope & Methodology

- Manual line-by-line review of every file under `lib/` (58 files), `backend/src/` (26 files), `backend/prisma/`, root configs; reading of `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `render.yaml`, `backend/DEPLOYMENT.md`.
- Git forensics: `git log --all`, per-commit diff stats, per-commit secret scan (`git grep` for `password|secret|api_key|token|PRIVATE KEY|DATABASE_URL`).
- Dynamic checks: `flutter analyze` (0 errors), backend `tsc` (clean), Render service + Postgres deploy state (`/health` ok).

---

## Repository Snapshot

- **Stack:** Flutter 3.35 / Dart ^3.9.2 mobile app; Node 22 + Express ^4.21 + TypeScript + Prisma 6 + PostgreSQL 16 + Zod + JWT backend.
- **Deployment:** Docker `./backend/Dockerfile` on Render (free oregon), live at `https://titanfit-api.onrender.com`; blueprint `render.yaml`; local `docker-compose.yml`.
- **State management:** Riverpod 2.6 (`StateNotifierProvider` + hand-written immutable states ×7), go_router 14.
- **Offline strategy:** `flutter_secure_storage`, local-first repos with fallback JSON.
- **Auth:** JWT access (15m) + refresh (7d, rotated in DB), bcryptjs cost 12.
- **Git:** linear history, 9 commits, clean secret hygiene, no tags, no branches beyond `main`.

---

## 1. Current Strengths

1. **Feature-first Flutter layout** — `lib/features/auth|workout|habits|sleep|progress|dashboard|profile|reminders|notifications` with `presentation/` + `data/` sub-layers is the correct seed for Clean Architecture.
2. **Riverpod DI** — providers are the single composition root; screens consume state via `ref.watch`, keeping widget→logic decoupling.
3. **Workout session feature** — per-second timer, rest countdown, set logging, pause/resume, XP award; the most "real" code in the app.
4. **Layered backend** — controllers → services → Prisma; all queries ownership-scoped (`where: { id, userId }`); singletons written once, exported once.
5. **Token rotation** — refresh tokens persisted and rotated on login/refresh, revoked on logout (single-active-session model).
6. **Schema quality** — cascade rules correct on every FK; unique constraints & composite indexes on high-cardinality columns; enums for domain types.
7. **Deployment maturity** — multi-stage Dockerfile running `prisma migrate deploy` before boot, committed `package-lock.json`, clean `DEPLOYMENT.md`, validated `render.yaml` blueprint.
8. **Good hygiene** — `.env` never committed; IDE files ignored; no secrets in history; `flutter analyze` clean; TS `strict` on.
9. **Consistent response envelope** — `{ success, data }` shape used throughout the API.

---

## 2. Weaknesses

| # | Finding | Evidence |
|---|---|---|
| W1 | Root `README.md` is Flutter boilerplate **corrupted** with an appended UTF-16LE block (`# Titanfit-`) | `README.md:1-592-bytes` |
| W2 | Zero tests across the whole product | `test/widget_test.dart` empty; backend `jest --passWithNoTests` (`backend/package.json:13`) |
| W3 | No CI/CD | no `.github/` anywhere |
| W4 | No LICENSE / SECURITY / CONTRIBUTING / CODE_OF_CONDUCT / CHANGELOG | glob `**/LICENSE*` → ∅ |
| W5 | No `docs/` | only `backend/DEPLOYMENT.md` |
| W6 | App identity still `com.example.fitness` / "fitness" / "A new Flutter project." | `android/app/build.gradle.kts`, `ios/.../project.pbxproj`, `web/manifest.json`, `windows/runner/Runner.rc` |
| W7 | `prisma:seed` script references a nonexistent `prisma/seed.ts` | `backend/package.json:12` |
| W8 | 9/16 runtime + 3/4 dev dependencies unused | `pubspec.yaml`; grep |
| W9 | `assets/images` + `assets/icons` declared but empty/untracked | `pubspec.yaml:36-38` |
| W10 | No custom lints | `analysis_options.yaml` is stock template |

---

## 3. Architecture Issues

| # | Issue | Detail |
|---|---|---|
| A1 | Core → feature dependency inversion | `core/services/health_insights.dart` imports feature providers (`sleep_provider`, `workout_provider`) — the core layer is concretely coupled to features |
| A2 | Router rebuilt on every auth change | `app_router.dart:21-22` watches `authProvider`; `main.dart:18` rebuilds the whole `GoRouter` (fresh `GlobalKey`s each time) → risks losing nav stack / duplicate key assertions |
| A3 | No domain layer anywhere | Features are `presentation/` + `data/` only; business rules (sleep scoring, streaks) live in repositories/UI |
| A4 | Fake data silently substitutes real data offline | `dashboard_repository.dart:36-47` and `progress_repository.dart:36-47` return fabricated metrics; `progress_screen.dart` uses `Random(42)`/`Random(7)` for charts (lines 125, 180) |
| A5 | Auth is bi-modal and insecure | `register` never calls the API — stores **plaintext password** in secure storage (`auth_repository.dart:67`) and mints fake `local_token_*` (line 72); offline data can never reach the server |
| A6 | Streaks computed nowhere | `habit_repository.getStreaks()` returns hardcoded zeros; `ApiConstants.habitStreaks/habitMonthly` unused |
| A7 | Notifications are decorative | `NotificationService.init()` only; 4 `schedule*` methods dead; reminders UI persists config nobody reads; Android 13 permission never requested |
| A8 | Backend error handling bypasses the global handler | every controller does its own `try/catch` and returns `error.message` verbatim (auth:38,52,62,71; workout:34,43,66,75…) — global `errorHandler.ts` is effectively dead |
| A9 | `workout.update` unvalidated | raw `req.body` spread into `prisma.workout.update` (`workout.controller.ts:63` → `workout.service.ts:84-92`) |
| A10 | Single-session refresh, no reuse detection, plaintext refresh token at rest | `auth.service.ts:34-38` overwrites the DB token; replaying a pre-rotation token is just rejected, never flagged |
| A11 | Non-atomic XP award | read-modify-write across 2 queries, no `$transaction` anywhere (`workout.service.ts:123-135`, `habit.service.ts:117-129`) |

---

## 4. Folder / Naming Issues

| # | Finding |
|---|---|
| F1 | Leftover scaffolding: `lib/pages/home.dart` (dead), `lib/data/` legacy layer containing **e-commerce models** (`OrderModel`, `ProductModel`, `ServiceModel`) with `throw UnimplementedError` stubs |
| F2 | `AppColors` defined **twice** with different palettes: `core/theme/app_colors.dart` (used) and `core/theme/app_color.dart` (dead) — same class name, silent wrong-palette landmine |
| F3 | `UserModel` defined twice: `lib/data/models/user_model.dart` vs `lib/features/auth/data/models/user_model.dart` |
| F4 | `presentation/providers/` empty directory in profile feature |
| F5 | Backend handler indirection `(req: any, res) => controller.x(req, res)` discards types on every route; `@types/express ^5` vs express 4 forces `as string` casts |
| F6 | REST naming drift: `POST /habits/checkin` (RPC verb), `PUT /users/profile` (should be PATCH), `sleep` singular vs `workouts`/`habits` plural |
| F7 | Subpar names: `_ExerciseCard(exercise: dynamic)` (`workout_detail_screen.dart:163`), unused `ApiException` taxonomy, `dashboard_repository` misnamed locals |

---

## 5. Code Smells (representative)

| # | Smell | Evidence |
|---|---|---|
| S1 | Large widgets | `dashboard_screen.dart` 604 lines (build ≈ 140); `workout_screen.dart` 549; `workout_session_screen.dart` 497; `progress_screen.dart` 398; `sleep_screen.dart` 410 |
| S2 | Duplicated logic | sleep thresholds ×3 (`health_insights.dart:38-41`, `sleep_repository.dart:26-28`, `sleep_screen.dart:89,306`); `_SectionTitle` ×3; delete-dialog ×3; habit labels ×2; new-workout dialog ×2; reco-card color mapping ×2 |
| S3 | Magic numbers / strings | rest timer `90` (`workout_session_provider.dart:148` + UI `/90`); `calsPerMin = 7` (`:187`); XP cap `1000`; hour thresholds `12/17` in `greeting()` (`helpers.dart:32-34`); month list hand-rolled despite `intl` installed |
| S4 | Dead code | unused deps; unused `Failure` hierarchy; unused `api_exceptions.dart`; `formatCalories()`; `api_constants.habitStreaks/habitMonthly/weightHistory`; empty `onPressed: () {}` (dashboard_screen:71) |
| S5 | Framework shadowing | `premium_button.dart:104-117` defines its own `AnimatedBuilder` class shadowing Flutter's |
| S6 | Timer lifecycle leaks | `startSession` doesn't cancel a previous `Timer.periodic` (`workout_session_provider.dart:98-114`); timers only stop on provider dispose |
| S7 | Mutable models | `Reminder` has public mutable fields mutated via `state.map` |
| S8 | Implicit mutation | `logSet` mutates `SessionExercise` in place inside the existing list (workout_session_provider:137-139) |
| S9 | Raw error strings to UI | `e.toString()` leaks into auth state (`auth_provider.dart:69,83`); `updateProfile` swallows errors (`catch (_) {}` at :97) |

---

## 6. Documentation Gaps

| Doc | Status |
|---|---|
| README (overview/install/features/screenshots) | ❌ broken boilerplate |
| Architecture docs | ❌ |
| API documentation | ❌ (17 endpoints, no reference) |
| Testing documentation | ❌ |
| Deployment doc | ✅ `backend/DEPLOYMENT.md` |
| Security policy / SECURITY.md | ❌ |
| Contribution guide / CONTRIBUTING.md | ❌ |
| Code of Conduct | ❌ |
| CHANGELOG / SemVer | ❌ |
| Licensing | ❌ |
| ADR / decision records | ❌ |
| Diagrams | ❌ |

---

## 7. Testing Gaps

- **Flutter:** 0 unit tests, 0 widget tests, 0 integration tests. No coverage of: health-insights rules engine, session timer math, offline-first repositories, validators, models (`fromJson`).
- **Backend:** 0 tests. `npm test` is `jest --passWithNoTests` — a guaranteed green no-op. No coverage of auth flow, zod validation paths, services, error handler.
- No CI gate would ever catch a regression.

---

## 8. Performance Concerns

| # | Issue |
|---|---|
| P1 | `bcryptjs` cost-12 hashing is **synchronous** — blocks the event loop per register/login |
| P2 | `habit.updateStreaks` loads **every completed habit ever** per check-in (unbounded, O(total)) |
| P3 | `progress.getStats` fans out ~7 parallel queries on every dashboard load, **uncached** — Redis is installed but never used |
| P4 | Pagination only on workouts, and `limit` is unbounded (`?limit=1000000` accepted, `workout.controller.ts:30`) |
| P5 | No `CHECK` constraints — invalid rows (negative duration, wake < sleep) possible |
| P6 | Duplicate sleep records allowed (no `(userId, sleepTime)` uniqueness) |
| P7 | `SleepRecord.duration` is `Int` but the API computes fractional hours (7.5) → silent truncation |

---

## 9. Security Concerns

| # | Finding | Severity |
|---|---|---|
| SE1 | Hardcoded JWT fallback secrets in code (`config/index.ts:8-9`: `fallback-secret`) — token forgery if env missing | **High** |
| SE2 | Raw `error.message` (Prisma/DB internals) leaked to clients in **all** controllers, all envs | **High** |
| SE3 | No rate limiting on `/auth/login` & `/auth/register` → brute force | **High** |
| SE4 | No `helmet` security headers | **High** |
| SE5 | `PUT /workouts/:id` accepts unvalidated body spread into Prisma | **High** |
| SE6 | CORS open to any origin (`cors()` default) | Medium |
| SE7 | User enumeration: register returns distinct `"Email already registered"` | Medium |
| SE8 | `Invalid Date` (NaN) slips past `durationHours <= 0` check on sleep; date inputs unvalidated | Medium |
| SE9 | Tokens in response body (XSS-exposed) rather than `httpOnly` cookies | Medium |
| SE10 | Android `android:allowBackup` not disabled → secure-storage auto-backup can restore stale ciphertext | Medium |
| SE11 | bcrypt password `min(6)`, no max length (truncates at 72 bytes), no complexity | Medium |
| SE12 | No 404 handler → Express default HTML path disclosure | Low |
| SE13 | **Good:** `.env` never committed; no secrets in git history; refresh tokens revoked on logout | ✅ |

---

## 10. Accessibility Issues

| # | Issue |
|---|---|
| AC1 | Zero `Semantics`/`semanticLabel`/`Tooltip` in the entire `lib/` |
| AC2 | No text-scaler accommodation; fixed 9–11px chart/label text (progress_screen:187,299; dashboard_screen:342) |
| AC3 | Sub-48dp touch targets (`_QuickAction`, `_QuickRepSelector` pills, profile edit icon 6px padding) |
| AC4 | Color-only status (exercise set dots) without icon/text |
| AC5 | `_calculateIndex` mis-highlights the bottom nav on Profile/Reminders/Session (`app_router.dart:123-130`) |
| AC6 | Shell body not wrapped in `SafeArea` (`app_router.dart:107`) — content under notches |
| AC7 | Contrast risk: `textMuted 0xFF6B6B6B` on `surface 0xFF1E1E1E` ≈ 4.0:1 |
| AC8 | No pull-to-refresh; empty/error/loading states inconsistent |

---

## 11. Developer Experience

| # | Issue |
|---|---|
| D1 | No `Makefile` / task runner / `README` quickstart → onboarding is guesswork |
| D2 | No lint/test/format scripts wired into a pre-commit or CI gate |
| D3 | `prisma:seed` crashes (missing file); `npm test` is a lie |
| D4 | Path alias `@/*` configured in tsconfig but never used (no `tsconfig-paths`) |
| D5 | No `.env.example` → wait, it exists ✅ for backend; Flutter base URL is a hardcoded constant (`app_constants.dart:4`) — no `--dart-define` injection for dev/prod |
| D6 | Backend dev tool `ts-node-dev --transpile-only` skips type errors at runtime |

---

## 12. Git History & Hygiene

- **Commit style:** 6/9 conventional (`feat/fix` + scope); first 3 unprefixed. Move forward with Conventional Commits everywhere.
- **Mega-commit:** `ce70f0d` = 218 files / +17,508 lines (initial import) — expected, but never again: keep PRs small.
- **Secrets:** none committed. Only the documented `fallback-secret` literals + local `docker-compose` `change-me` values.
- **Hygiene:** `.idea/`, `.vscode/`, `.iml` untracked ✅. Root `.gitignore` comprehensive ✅.
- **Gaps:** no LICENSE, no tags/releases, no CI.

---

## 13. Severity-Ranked Findings (consolidated)

| Priority | Finding | Area |
|---|---|---|
| P0 | README corrupt/boilerplate; no docs at all | Docs |
| P0 | Zero tests; CI absent | Quality |
| P0 | Hardcoded JWT fallback secrets; auth endpoints unthrottled; no helmet | Security |
| P0 | Progress charts / stats fabricated (`Random`) — misleading | Data |
| P1 | `PUT /workouts/:id` unvalidated body to Prisma | Security |
| P1 | Raw error leakage across all controllers | Security |
| P1 | Plaintext passwords written by app's local auth | Security |
| P1 | Dead code & unused deps (9 libs) | Maintainability |
| P1 | Migration of screenshots into `assets/screenshots`; app identity `com.example`→`com.titanfit` | Branding |
| P2 | Fake offline stats; broken streaks | Data |
| P2 | Timer lifecycle; router rebuild anti-pattern | Architecture |
| P2 | A11y (Semantics, hit targets, SafeArea, nav highlight) | UX |
| P3 | XP/level non-atomic; unbounded habit scan; no caching | Performance |

---

## 14. Recommended Roadmap

Mapped to the project directive (16 steps):

1. **STEP 1 — Audit** (this document) → commit.
2. **STEP 2 — Restructure** into monorepo: `apps/mobile` (Flutter) + `apps/api` (backend), root `docs/`, `assets/`, `diagrams/`, `scripts/`, `packages/`, `tests/`, plus `README`, `LICENSE`, `CHANGELOG`, `CONTRIBUTING`, `CODE_OF_CONDUCT`, `SECURITY`, `.github/`. Update `render.yaml`, compose, CI paths; keep live Render deploy building.
3. **STEP 3 — README** professional rewrite with badges, screenshots, quickstart.
4. **STEP 4 — Clean Architecture** metric: features get `presentation/domain/data`; extract domain rules (sleep scoring, streak engine, level math) out of repos/UI; DI the secure-storage singleton.
5. **STEP 5 — Architecture docs** (`docs/architecture/*`).
6. **STEP 6 — Mermaid diagrams** (`diagrams/*`, referenced by `docs/diagrams/README.md`).
7. **STEP 7 — UI/UX** targeted: SafeArea, semantics, hit targets, consistent empty/loading/error states, nav-highlight fix, remove dead affordances; **replace fabricated charts** with real provider-fed data.
8. **STEP 8 — Code quality** delete dead code, deduplicate widgets, extract constants, fix timer lifecycle, remove framework-shadowing class.
9. **STEP 9 — Testing** Flutter unit/widget tests (rules engine, validators, session provider, repos w/ mocked Dio) + backend jest (auth, validation, services); test docs.
10. **STEP 10 — CI** GitHub Actions: flutter analyze+test+format+build; backend lint+build+test; concurrency; badge.
11. **STEP 11 — Security** remove fallback secrets, helmet + rate-limit + CORS allowlist, central error handler (no leaks), validate `workouts.update`, cap pagination, `allowBackup=false`, API-first auth (no plaintext).
12. **STEP 12 — Screenshots** → `assets/screenshots/` + README gallery.
13. **STEP 13 — CHANGELOG** SemVer.
14. **STEP 14 — Conventional Commits** for every change.
15. **STEP 15 — Portfolio polish** (badges, identity `com.titanfit.app`, consistent naming).
16. **STEP 16 — Final self-review** against the "would this impress a senior engineer?" checklist.

---

## Appendix A — Dead Code Inventory (actionable)

| Path | Action |
|---|---|
| `lib/pages/home.dart` | delete |
| `lib/data/models/{user,service,product,order}_model.dart` + `lib/data/repositories/*_impl.dart` | delete (legacy e-commerce scaffold) |
| `lib/core/theme/app_color.dart` | delete (duplicate `AppColors`) |
| `lib/core/errors/failure.dart` | delete or integrate |
| `lib/core/network/api_exceptions.dart` | delete or integrate into Dio error mapping |
| `lib/core/utils/helpers.dart: formatCalories` | delete |
| `lib/features/reminders` dead scheduling | wire `NotificationService.schedule*` or note |
| deps: `intl`(if keeping manual fmt), `riverpod_annotation`, `json_annotation`, `build_runner`, `json_serializable`, `riverpod_generator`, `cached_network_image`, `shimmer`, `google_fonts`, `percent_indicator`, `table_calendar`, `image_picker`(if removing avatar), `cupertino_icons` | prune unused |
| backend deps: `redis`, `node-cron`, `express-validator` | prune unused (or wire redis caching) |

## Appendix B — Backend Endpoint Inventory (17)

| Method | Path | Auth | Validated? |
|---|---|---|---|
| POST | `/api/auth/register` | no | zod ✅ |
| POST | `/api/auth/login` | no | zod ✅ |
| POST | `/api/auth/refresh` | no | zod ✅ |
| POST | `/api/auth/logout` | yes | — |
| GET | `/api/users/profile` | yes | — |
| PUT | `/api/users/profile` | yes | zod ✅ (enum→string mismatch) |
| GET | `/api/workouts/stats` | yes | — |
| GET | `/api/workouts?page&limit` | yes | ⚠️ unbounded limit |
| GET | `/api/workouts/:id` | yes | ⚠️ no UUID check |
| POST | `/api/workouts` | yes | zod ✅ |
| PUT | `/api/workouts/:id` | yes | ❌ **none** |
| DELETE | `/api/workouts/:id` | yes | ⚠️ no UUID check |
| GET | `/api/habits?date` | yes | ⚠️ manual |
| GET | `/api/habits/monthly?year&month` | yes | ⚠️ manual |
| GET | `/api/habits/streaks` | yes | ⚠️ |
| POST | `/api/habits/checkin` | yes | ⚠️ enum→Prisma leak |
| POST | `/api/sleep` | yes | ⚠️ `Invalid Date` accepted |
| GET | `/api/sleep/history?days` | yes | ⚠️ |
| GET | `/api/sleep/stats` | yes | ⚠️ |
| GET | `/api/progress/stats` | yes | ❌ none |
| GET | `/api/progress/weight` | yes | ❌ none |
| GET | `/health` | no | ✅ |

---

*End of audit — findings are tracked in this document and will be resolved through the roadmap above.*
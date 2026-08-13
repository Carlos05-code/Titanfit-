# Changelog

All notable changes to TitanFit are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Repository restructuring into a monorepo layout (`apps/mobile` + `apps/api`).
- Layers: root README, LICENSE, SECURITY, CONTRIBUTING, CODE_OF_CONDUCT.
- Documentation index (`docs/`), architecture docs, API reference, testing guide, deployment guide.
- Mermaid diagrams under `diagrams/`.
- GitHub Actions CI pipeline (analyze, lint, test, build, format) + Dependabot.
- Jest test suite for the backend; Flutter unit tests for validators & helpers.
- Live smoke-test suite (`scripts/smoke-api.mjs`) and DB cleanup helper (`scripts/delete-user.mjs`).

### Changed
- Backend hardened: helmet, express-rate-limit, CORS allowlist, centralized error handling,
  Zod validation (strict whitelists) across all routes, transactional XP award, fallback-secret removal.
- API moved from PUT to PATCH semantics for partial updates; mobile client aligned.
- Mobile: dead code removed, synthesized/fake chart data replaced with provider-fed data,
  shared widgets extracted, accessibility (Semantics, SafeArea, hit targets) improved.
- Whole codebase normalized with `dart format`; analyzer runs clean.

### Fixed
- README encoding corruption (UTF-16 tail removed).
- `Validators.email` rejecting/accepting malformed addresses (spaces) — stricter regex.
- Bottom-navigation highlight while on Profile / Reminders / Session screens.
- Refresh failures no longer wipe local user data (`deleteAll` → scoped token removal).
- Concurrent 401s now share a single refresh call (single-flight).

### Security
- Removed hardcoded JWT fallback secrets from production behavior.
- No more raw `error.message` leakage to clients.
- Sleep XP can no longer be farmed: one record per UTC day.

## [1.0.0] - 2026-08-04

Initial release.

### Added
- Flutter mobile application (auth, workouts, habits, sleep, progress, profile, reminders).
- Node.js/TypeScript REST API (Express + Prisma + PostgreSQL) with JWT auth & refresh rotation.
- Offline-first repositories backed by secure storage.
- Initial Prisma migration for all tables/enums.
- Dockerfile, docker-compose, Render blueprint (`render.yaml`), deployment documentation.
- Live deployment on Render with managed PostgreSQL.
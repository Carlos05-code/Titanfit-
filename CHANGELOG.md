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

### Changed
- Backend hardened: helmet, express-rate-limit, CORS allowlist, centralized error handling,
  Zod validation across all routes, transactional XP award, fallback-secret removal.
- Mobile: dead code removed, synthesized/fake chart data replaced with provider-fed data,
  shared widgets extracted, accessibility (Semantics, SafeArea, hit targets) improved.

### Fixed
- README encoding corruption (UTF-16 tail removed).
- `Validators.email` rejecting/accepting malformed addresses (spaces) — stricter regex.
- Bottom-navigation highlight while on Profile / Reminders / Session screens.

### Security
- Removed hardcoded JWT fallback secrets from production behavior.
- No more raw `error.message` leakage to clients.

## [1.0.0] - 2026-08-04

Initial release.

### Added
- Flutter mobile application (auth, workouts, habits, sleep, progress, profile, reminders).
- Node.js/TypeScript REST API (Express + Prisma + PostgreSQL) with JWT auth & refresh rotation.
- Offline-first repositories backed by secure storage.
- Initial Prisma migration for all tables/enums.
- Dockerfile, docker-compose, Render blueprint (`render.yaml`), deployment documentation.
- Live deployment on Render with managed PostgreSQL.
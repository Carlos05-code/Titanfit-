# TitanFit — Architecture Diagrams

Mermaid source diagrams (.mmd) live in `diagrams/` at the repo root and are
rendered natively by GitHub. Each file is a single, self-contained Mermaid
diagram (flowchart / sequence / ER) referenced from the listed docs.

| Diagram file | Rendered purpose | Referenced in |
| --- | --- | --- |
| `system-architecture.mmd` | End-to-end topology: Flutter app (offline-first cache via `flutter_secure_storage`), Express REST API, Prisma ORM, PostgreSQL on Render; JWT auth path, Docker-on-Render deployment, and health check. | `docs/architecture/README.md`, `docs/deployment/README.md`, root `README.md` |
| `folder-structure.mmd` | Full repository tree: top-level layout with subgraphs for `apps/mobile`, `apps/api`, `docs`, `diagrams`, `assets`, `scripts`, `packages`, `tests`, and `.github`. | `docs/README.md`, new-contributor onboarding in `CONTRIBUTING.md` |
| `authentication-flow.mmd` | JWT auth sequence: register/login over `/api/auth/*`, bcrypt verify, access (15 min) + refresh (7 day) tokens, secure-storage persistence, interceptor auto-refresh on 401, refresh rotation, logout revocation. | `docs/api/auth`, `docs/architecture/README.md` |
| `navigation-flow.mmd` | Flutter `go_router` routing: splash -> login/register -> `MainShell` with 5 bottom-nav tabs, plus sub-pages (workout detail, workout session, profile, reminders) and redirect rules from `app_router.dart`. | `docs/architecture/README.md`, `apps/mobile/README.md` |
| `database-er.mmd` | Database ER diagram from `prisma/schema.prisma`: `User`, `Workout`, `Exercise`, `Habit`, `SleepRecord`, `UserAchievement`, `ProgressPhoto` with all 1:N relations and unique/composite indexes. | `docs/api/database`, `docs/specifications/README.md` |
| `sequence-session.mmd` | On-device workout session sequence: start, per-second timer, log set, live progress, end session, `POST /api/workouts` with offline fallback into secure-storage queue. | `docs/api/workouts`, `docs/specifications/README.md` |
| `user-flow.mmd` | Product user journey: onboarding/auth -> daily flows (workout, habit, sleep, progress) -> gamification (XP, level, streak, achievements) -> insights and retention. | `README.md`, `docs/specifications/README.md` |
| `ci-cd-pipeline.mmd` | GitHub Actions pipeline: push/PR/dispatch triggers, concurrency guard, backend/mobile/docker jobs, then Render deploy on `main`. | `docs/deployment/README.md`, `.github/workflows/ci.yml` |
| `repository-structure.mmd` | Git-managed structure: `.github` CI files, governance files (README, LICENSE, CONTRIBUTING, SECURITY, CHANGELOG), `docs/`, `diagrams/`, `packages/`, `scripts/`. | `CONTRIBUTING.md`, `docs/deployment/README.md` |

## Rendering

- **GitHub**: Mermaid is supported natively in Markdown via fenced ```` ```mermaid ```` blocks — copy the diagram body into a markdown file, or use the GitHub Markdown renderer on the `.mmd` files.
- **Local tooling**: `npx @mermaid-js/mermaid-cli -i diagrams/<name>.mmd -o out.svg` renders any single file to SVG/PNG.

All diagrams are source-of-truth artifacts; update the `.mmd` and re-render whenever the codebase changes (routes, schema, CI, or architecture).
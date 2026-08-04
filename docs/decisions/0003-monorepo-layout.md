# ADR-0003 — Monorepo Layout

**Status:** Accepted  
**Date:** 2026-08-05

## Status

Accepted and reflected in the repository: `apps/mobile` (Flutter) and `apps/api` (Node/Express/Prisma),
with root-level `docs/`, `.github/`, and deployment configuration.

## Context

TitanFit consists of two independently released artifacts — a Flutter mobile app and a Node.js REST API —
plus shared assets (documentation, CI, deployment blueprint, diagrams, licensing). The options were:

- **Polyrepo:** separate git repositories per app. Isolates codebases but splits CI config, docs, issue
  tracking, and deployment plumbing, and makes cross-cutting changes (e.g. API contract updates
  mirrored in the mobile client) awkward.
- **Monorepo with side-by-side apps:** one repository, `apps/<name>` per artifact, root-level docs and CI.
  Cross-cutting changes are reviewed in a single PR; the toolchain stays per-app (no forced
  shared-package coupling).

The team was already operating as a single small unit shipping both artifacts together, and the audit
flagged that documentation, CI, and deployment plumbing were the weakest seams to keep in sync.

## Decision

Adopt a **monorepo** layout:

1. Each deployable lives in its own directory under `apps/`:
   - `apps/mobile` — Flutter app (its own `pubspec.yaml`, `test/`, feature-first `lib/`).
   - `apps/api` — Express API (its own `package.json`, `tsconfig.json`, `prisma/`, `Dockerfile`,
     `docker-compose.yml`).
2. Everything that spans the product lives at the root: `docs/` (this documentation), `.github/workflows/`
   (CI), `render.yaml` (deployment blueprint), `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`.
3. Cross-cutting libraries that are not yet needed stay **reserved** under a future `packages/`
   directory; nothing is shared via npm/`pub` today.
4. The root README links into `apps/*` READMEs and `docs/` rather than duplicating per-app content.

## Consequences

### Positive

- One PR can ship a coordinated API + mobile change; contract changes (e.g. the API reference in
  `docs/api/README.md`) are reviewed alongside the code.
- Single CI pipeline (`.github/workflows/ci.yml`) with per-app jobs; single deployment blueprint
  (`render.yaml`) that provisions the whole stack.
- Docs, decisions, and specs have one canonical home with stable relative links
  (`docs/api`, `docs/testing`, `docs/deployment`, `docs/specifications`, `docs/decisions`).
- Each app keeps its own lockfiles, toolchains, and versioning — no shared-toolchain tax.

### Negative

- **Path awareness everywhere:** build context, deployment, and CI must be path-explicit —
  `render.yaml` points at `./apps/api/Dockerfile` with `dockerContext: ./apps/api`, CI sets
  `working-directory: apps/api` / `apps/mobile`, and Docker's build context is the API subdirectory.
  A restructure that moves these paths breaks deploy + CI in the same commit (a safety net, but also a
  footgun).
- Repository size and tooling grow monotonically; without discipline, app-specific tooling (version
  managers for Flutter/Node) must be kept in sync per app.
- No shared packages exist yet — the moment the two apps want to share code (e.g. a DTO/contracts
  library), the `packages/` convention must be designed deliberately (workspace tooling for both
  npm and pub) before being used.

*Follow-ups:* establish the `packages/` shared-code convention only when a real shared dependency
appears; keep `render.yaml`, CI working-directories, and Docker context in lockstep with any layout
change.
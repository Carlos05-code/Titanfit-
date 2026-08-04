# Architecture Decision Records (ADRs)

Architecture Decision Records capture the context, decision, and consequences behind TitanFit's
significant structural choices. They follow a consistent template:

> **Status** · **Context** · **Decision** · **Consequences** (Positive / Negative)

New ADRs are added to `docs/decisions/` with a zero-padded sequence number, and a row is added to the
index below.

| ADR # | Title | Status | Date |
|---|---|---|---|
| [0001](0001-offline-first-storage.md) | Offline-first repositories with `flutter_secure_storage` as cache | Accepted | 2026-08-05 |
| [0002](0002-token-rotation-auth.md) | JWT access tokens + rotating refresh tokens stored in the database | Accepted | 2026-08-05 |
| [0003](0003-monorepo-layout.md) | Monorepo layout with `apps/mobile` + `apps/api` | Accepted | 2026-08-05 |

## Status meanings

- **Proposed** — under discussion; not yet implemented.
- **Accepted** — agreed and reflected in the codebase.
- **Superseded** — replaced by a later ADR; kept for history.

## Templates

Each ADR uses the shared template:

```markdown
# ADR-00XX — <Title>

**Status:** Accepted · **Date:** YYYY-MM-DD

## Status
…

## Context
…

## Decision
…

## Consequences
### Positive
…
### Negative
…
```
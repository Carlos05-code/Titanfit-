# ADR-0001 — Offline-first Storage

**Status:** Accepted  
**Date:** 2026-08-05

## Status

Accepted and implemented across the mobile repositories (`apps/mobile/lib/features/*/data/repositories/*`).

## Context

TitanFit is a mobile fitness tracker whose users train in gyms, on commutes, and in other places with
flaky or absent connectivity. Waiting on the network to render the dashboard, habits, or a workout
history is a poor experience, and losing data after a failed check-in is unacceptable for a habit-tracking
product.

The product already has a real, authenticated API (see ADR-0002) that is the source of truth for
server-side state. The mobile app needed a way to (a) keep screens usable when the network drops and
(b) preserve user-entered data across network failures and app restarts.

Options considered:

- **Network-only (no cache):** simplest, but the app becomes useless offline and loses input.
- **A SQLite/local persistence layer with a formal sync engine:** robust but heavy to build and maintain
  in the current mobile-only effort.
- **Offline-first repositories with `flutter_secure_storage` as a JSON cache:** repositories try the API
  first and fall back to locally persisted JSON on failure — a pragmatic middle ground.

## Decision

Adopt **offline-first repositories**:

1. Every mobile data repository (`workout_repository.dart`, `habit_repository.dart`,
   `sleep_repository.dart`, `auth_repository.dart`, `dashboard_repository.dart`,
   `progress_repository.dart`) attempts the API **first**, then falls back to cached data.
2. Cached data is stored as JSON blobs in **`flutter_secure_storage`** under keys such as
   `local_workouts`, `local_habits`, `local_sleep`, `local_users`.
3. When online writes succeed, the local cache is updated (e.g. `saveLocal` after `getAll`, local append
   after `create`) so the cache stays fresh.
4. Reads are never hard-blocked by the network: repo methods `catch` and serve the cache instead of
   throwing (see `apps/mobile/lib/features/workout/data/repositories/workout_repository.dart:13-28`).

## Consequences

### Positive

- The dashboard, workouts, habits, and sleep screens remain usable with no connectivity.
- User-entered data (habit check-ins, sleep records, workouts) survives network failures and app
  restarts — persistence is durable across relaunches.
- Small amount of new code: the pattern is uniform across repositories and easy to test against a mocked
  Dio client + stubbed secure storage.
- `flutter_secure_storage` gives at-rest encryption on Android/iOS rather than a plain shared-preferences
  blob.

### Negative

- **Data on the device:** caching user-generated data in on-device storage means user data exists both
  server-side and local-side, widening the data-handling surface and raising privacy expectations.
- **Single-device bias:** local-first reads combined with per-device caches assume one device; multi-device
  sync is not modeled.
- **No sync/outbox:** there is no queue to push offline-created data (local rows get synthetic ids and
  could duplicate real ones when the server comes back).
- **Plaintext-password risk in local auth:** the local-auth path stores credentials and mints fake
  `local_token_*` values, and **stores plaintext passwords** in secure storage
  (`auth_repository.dart:67`) — a security debt to be addressed (either make registration API-first once
  offline registration is dropped, or hash/strip credentials). This is tracked as a known gap.
- **Fabricated offline aggregates:** dashboard/progress offline fallbacks return hard-coded placeholder
  metrics, which can silently mislead (see `docs/specifications/README.md#9-offline--transitions`).

*Follow-ups:* a real sync/outbox queue, resolution of the local plaintext-credential path, and honest
offline aggregation.
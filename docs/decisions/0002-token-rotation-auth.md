# ADR-0002 — Token Rotation Auth

**Status:** Accepted  
**Date:** 2026-08-05

## Status

Accepted and implemented in `apps/api/src/services/auth.service.ts`, `apps/api/src/middleware/auth.ts`,
and the mobile client `apps/mobile/lib/core/network/api_client.dart`.

## Context

TitanFit's API needs an authentication model for ~15-minute client sessions. The two classic approaches
were considered:

- **Stateless self-contained JWTs:** the server validates a signed token without any per-session state.
  Simple and horizontally scalable, but revocation is impossible until expiry — a leaked or stolen token
  stays valid, and "log out everywhere" cannot be honored server-side.
- **Session/revocable tokens:** the server holds session state and can revoke at will, but requires a
  lookup on every request and adds operational state to manage.

A pure stateless design was also impractical here because the client is a mobile app with a long-lived
"keep me signed in" expectation: an access token alone expires in 15 minutes, and re-authenticating with
a password that often is unacceptable.

## Decision

Use a **JWT access token (short-lived) + a rotating refresh token stored in the database**:

1. **Access token** — JWT signed with `JWT_SECRET`, TTL `JWT_EXPIRES_IN` (default `15m`), carries
   `{ userId, email }` (`apps/api/src/types/index.ts:3-6`), validated statelessly by
   `middleware/auth.ts`.
2. **Refresh token** — JWT signed with a **separate secret** `JWT_REFRESH_SECRET`, TTL
   `JWT_REFRESH_EXPIRES_IN` (default `7d`), and **persisted on `User.refreshToken`**
   (`apps/api/prisma/schema.prisma:64`).
3. **Rotation & single active session** — every `login`, `register`, and `refresh` overwrites the stored
   refresh token (`auth.service.ts:18-22, 34-38, 52-56`). A `refresh` that presents a token **not equal**
   to the stored value (e.g. a replayed, already-rotated token) is rejected with `401`
   (`auth.service.ts:46-50`).
4. **Logout revocation** — `logout` nullifies `User.refreshToken` so all issued refresh tokens for that
   user die server-side (`auth.service.ts:64-69`).
5. **Client behavior** — the mobile client stores both tokens in `flutter_secure_storage`, and on any
   `401` silently trades the refresh token for a new pair and retries the failed request once
   (`api_client.dart:26-59`).

## Consequences

### Positive

- Short-lived access tokens limit the blast radius of a stolen access token (~15 minutes).
- Logout is truly server-side: one `UPDATE` revokes the session everywhere.
- Rotation means an access token can never be exchanged twice with the same refresh token, and reuse of an
  old token is observable if the server starts flagging mismatches.
- Stateless access-token validation keeps per-request cost low (DB only touched on auth flows).

### Negative

- **Single active session:** because the refresh token is a single DB column, logging in on a second
  device silently invalidates the first device's session — acceptable for v1, but not multi-device.
- Refresh token is stored **in plaintext at rest** in Postgres and is `null`-able; a DB leak exposes
  long-lived credentials (mitigations: encrypt at rest, reduce TTL, token hashing).
- **No reuse detection yet:** a rotated token that is replayed is merely rejected, not flagged/alarmed —
  the plumbing detects it, but there is no security eventing or forced re-auth. This is the primary
  candidate for future ADR-0002 follow-up work.
- Rotation adds a write (`User.update`) to every refresh; the single-column layout limits refresh-token
  history (a rotation history table would enable reuse-detection).

*Follow-ups:* refresh-token families/reuse detection, session history, encrypted-at-rest refresh tokens,
and multi-device session support — each to be captured as its own ADR before implementation.
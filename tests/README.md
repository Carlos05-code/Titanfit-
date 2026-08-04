# tests/

Cross-cutting testing assets and strategy notes for the monorepo.

| Location | What lives there |
|---|---|
| `apps/mobile/test/` | Flutter unit + widget tests |
| `apps/api/tests/` | Jest unit + integration tests |
| `tests/` (this dir) | Shared fixtures, end-to-end walkthroughs, strategy docs |

## E2E walkthrough

The canonical end-to-end smoke path:

1. `POST /api/auth/register` (or `/login`) → tokens.
2. `POST /api/workouts` with exercises → 201 + awarded XP.
3. `GET /api/workouts` → created resource present, ownership-scoped.
4. `POST /api/sleep` → sleep record scored.
5. `GET /api/progress/stats` → aggregated dashboard payload.

The mobile device test (Android emulator → live Render API) is documented in
[docs/testing](../docs/testing/README.md).
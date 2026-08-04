# packages/

Reserved for **shared domain packages** extracted from the mobile app.

Once the domain layer (streak engine, sleep scoring, level math) is extracted in the
[Clean Architecture refactor](../docs/architecture/README.md), shared code that is used by
multiple apps will live here (e.g. `packages/titanfit_domain`).

Current status: **empty by design** — the mobile app is the only front-end, so there is
nothing to share yet. Introducing a premature shared package would hurt the codebase.
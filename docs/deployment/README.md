# TitanFit Deployment Guide

Operational documentation for shipping the TitanFit API to **Render** (web service + managed Postgres)
and running the full stack locally with Docker. The mobile app is a Flutter client that points at the
live API base URL (`https://titanfit-api.onrender.com/api` — `apps/mobile/lib/core/constants/app_constants.dart`).

Source of truth for the API's own, shorter runbook: `apps/api/DEPLOYMENT.md`.

---

## 1. Deployed stack (architecture)

```
                    ┌─────────────────────────────┐
  Flutter app ─────▶│  Render Web Service          │
  (Android/iOS)     │  "titanfit-api"              │
   bearer JWT       │  runtime: docker · plan: free│
                    │  /health health check        │
                    └──────────────┬──────────────┘
                                   │ DATABASE_URL (auto-injected)
                    ┌──────────────▼──────────────┐
                    │  Render Managed PostgreSQL   │
                    │  "titanfit-db"  (plan: free) │
                    └─────────────────────────────┘
```

- **One web service**, containerized via `apps/api/Dockerfile`. It handles all REST traffic, JWT issuance
  and verification, and is the only place application logic lives.
- **One managed Postgres instance** (`titanfit-db`), provisioned by the same blueprint. Render injects its
  connection string into `DATABASE_URL` automatically — no credential handling in the app.
- **Redis is declared** (`REDIS_URL`) and run locally in `docker-compose`, but the API does **not** use it
  in the currently deployed feature set (reserved for caching/rate limiting).
- The mobile app is **not deployed** by this pipeline; it is built/distributed separately and calls the
  public REST API.

---

## 2. `render.yaml` blueprint

One file (`render.yaml`, repo root) provisions both services declaratively:

| Key | Value | Notes |
|---|---|---|
| `services[].type` | `web` | Internet-facing long-running process |
| `name` | `titanfit-api` | Service name in the Render dashboard |
| `runtime` | `docker` | Build from a Dockerfile (not a language runtime) |
| `plan` | `free` | Free tier; spins down when idle (~50s cold start) |
| `dockerfilePath` | `./apps/api/Dockerfile` | **Monorepo:** the Dockerfile lives under `apps/api` |
| `dockerContext` | `./apps/api` | Build context is the API subdir, so `COPY package*.json` paths resolve |
| `autoDeployTrigger` | `commit` | **Every push to `main` triggers a deploy** |
| `healthCheckPath` | `/health` | Render marks the service live once `/health` returns 2xx |
| `envVars` | see table below | Static values + generated secrets + `fromDatabase` |

Databases section:

```yaml
databases:
  - name: titanfit-db
    plan: free
    databaseName: titanfit
    user: titanfit
```

Render wires the database's `connectionString` into the web service's `DATABASE_URL` env var via the
`fromDatabase` reference — the blueprint is the single source of truth for both.

> ⚠️ **Monorepo path note (ADR-0003):** the build context and `Dockerfile` paths point into
> `apps/api`. Any future restructure of the repo layout must update `render.yaml` (and CI and the compose
> file) or deployments will break.

### Env vars set by the blueprint

| Key | Source | Value |
|---|---|---|
| `DATABASE_URL` | `fromDatabase: titanfit-db` | managed Postgres connection string (auto) |
| `REDIS_URL` | static | `redis://localhost:6379` (placeholder; Redis not used in this feature set) |
| `JWT_SECRET` | `generateValue: true` | random, generated at blueprint deploy (strong, not the dev fallback) |
| `JWT_REFRESH_SECRET` | `generateValue: true` | random, generated at blueprint deploy |
| `JWT_EXPIRES_IN` | static | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | static | `7d` |
| `PORT` | static | `3000` |
| `NODE_ENV` | static | `production` |

---

## 3. Dockerfile build steps

`apps/api/Dockerfile` is a four-stage build:

```dockerfile
FROM node:22-alpine AS base        # 1. base: Node 22 + openssl (Prisma requires it)
RUN apk add --no-cache openssl
WORKDIR /app

FROM base AS deps                  # 2. deps: lockfile-pinned install
COPY package*.json ./
RUN npm ci

FROM deps AS build                 # 3. build: Prisma client + TypeScript emit
COPY prisma ./prisma
COPY tsconfig.json ./
COPY src ./src
RUN npx prisma generate
RUN npm run build                  # → dist/

FROM base AS runtime               # 4. runtime: minimal production image
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
```

Key points:

- `npm ci` (not `install`) guarantees reproducible dependency trees from `package-lock.json`.
- `npx prisma generate` happens in the **build** stage so the generated client ships in `node_modules`.
- **Migrations run on boot** — the container command is `prisma migrate deploy && node dist/server.js`,
  so the schema is applied to Postgres *before* the server accepts traffic. Render's health check then
  confirms readiness.
- The runtime image excludes `src/`, `tsconfig.json`, and build tooling — only `dist`, `prisma`, and deps.
- Local `apps/api/.dockerignore` keeps build artifacts and secrets out of the image context.

---

## 4. Environment variables

| Variable | Required | Description | Example / default |
|---|---|---|---|
| `DATABASE_URL` | ✅ | Postgres connection string (Prisma) | `postgresql://user:pass@host:5432/titanfit?schema=public` |
| `JWT_SECRET` | ✅ prod | Access-token signing secret. Render auto-generates; **never** the dev fallback | random ≥32 chars |
| `JWT_REFRESH_SECRET` | ✅ prod | Refresh-token signing secret | random ≥32 chars |
| `JWT_EXPIRES_IN` | ❌ | Access-token TTL (`jsonwebtoken` format) | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | ❌ | Refresh-token TTL | `7d` |
| `REDIS_URL` | ❌ | Reserved for caching/rate-limiting | `redis://localhost:6379` |
| `PORT` | ❌ | HTTP listen port | `3000` |
| `NODE_ENV` | ❌ | `production` masks raw error messages globally and sets log severity | `development` |

> ⚠️ `apps/api/src/config/index.ts` contains **fallback secrets** (`fallback-secret`) used when env vars
> are absent. Only the Render blueprint's generated values make those fallbacks inert in production. Do not
> ship without them (see hardening checklist).

---

## 5. Deploying

Render Blueprint auto-deploys on **every commit to `main`**:

```
git push origin main   →  Render detects commit  →  builds apps/api/Dockerfile
                       →  blue/green swap if /health passes
```

- If the build or health check fails, Render keeps the previous deployment serving.
- Deploys are triggered by `autoDeployTrigger: commit`; you can also trigger manually from the dashboard
  as a rollback (redeploy a previous, healthy deployment).
- Because migrations run on boot, a deploy is an opportunity to apply schema changes — make sure migration
  files are committed **before** the code that requires them (`prisma migrate deploy` applies pending
  migrations in order).

---

## 6. Local Docker Compose

`apps/api/docker-compose.yml` runs the same image against local dependencies:

| Service | Image | Ports | Purpose |
|---|---|---|---|
| `db` | `postgres:16-alpine` | `5432` | Postgres with `postgres_data` volume; healthcheck via `pg_isready` |
| `redis` | `redis:7-alpine` | `6379` | Reserved cache (not used by feature set) |
| `api` | build from `Dockerfile` (`context: .`) | `3000` | API; starts only after `db` is healthy |

```bash
# from the repo root
docker compose -f apps/api/docker-compose.yml up --build
curl http://localhost:3000/health   # {"status":"ok","timestamp":"…"}
```

The compose file passes the same env vars as production (with local/dev secrets and `DATABASE_URL`
pointing at the `db` service). Migrations run automatically at container start exactly as in Render.

**Without Docker**:

```bash
cd apps/api
npm ci
cp .env.example .env     # set DATABASE_URL for your local Postgres
npx prisma migrate deploy   # or: npx prisma migrate dev
npm run dev              # ts-node-dev watch mode
```

---

## 7. Health check & verification

| Check | Command | Expected |
|---|---|---|
| Readiness | `curl https://titanfit-api.onrender.com/health` | `{"status":"ok","timestamp":"…"}` |
| Auth smoke | `curl -s -X POST -H "Content-Type: application/json" -d '{"email":"…","password":"…","name":"…"}' https://titanfit-api.onrender.com/api/auth/register` | `{"success":true,"data":{…tokens…}}` |
| Dashboard data | `curl -H "Authorization: Bearer <accessToken>" https://titanfit-api.onrender.com/api/progress/stats` | `{"success":true,"data":{…}}` |

After any deploy, verify in order: build succeeds → `/health` returns 200 → token refresh works →
representative data endpoints return the envelope. This mirrors the E2E device test described in
[`docs/testing/README.md`](../testing/README.md).

---

## 8. Rollback

1. In the Render dashboard → **Deploys** tab for `titanfit-api`, select the last known-good deployment
   (or a specific commit) and choose **Redeploy** (the "Revert to previous deployment" action re-runs it).
2. Because migrations run before boot, reverting to a previous image does **not** auto-revert a schema
   migration that was already applied. If the bad deploy introduced a forward-only migration, coordinate a
   corrective migration rather than relying on image rollback alone.
3. Confirm `/health` and the smoke checks above before telling users recovery is complete.

---

## 9. Production hardening checklist

Current gaps and mitigations to apply before treating the deployment as battle-ready (mirrors
`docs/audit/repository_audit.md`):

| # | Action | Status |
|---|---|---|
| 1 | Remove/guard the `fallback-secret` JWT literals in `config/index.ts` | ⚠️ env-provided on Render, but fallback still reachable if a var is dropped |
| 2 | Add centralized error handling — controllers currently return raw `error.message` verbatim even in production | ⚠️ partial (`errorHandler` masks only unhandled errors) |
| 3 | Rate-limit `/auth/login` and `/auth/register` (Redis is already declared) | ❌ not implemented |
| 4 | Add `helmet` security headers and a CORS allowlist (currently `cors()` open) | ❌ not implemented |
| 5 | Validate `PUT /workouts/:id` (raw `req.body` spread into Prisma) and cap `limit` on pagination | ❌ not implemented |
| 6 | Dedicated readiness/liveness messaging and structured logs | ❌ basic |
| 7 | Automatic DB backups / point-in-time recovery on the managed Postgres plan | ⚠️ confirm plan entitlements |
| 8 | Rotate `JWT_SECRET`/`JWT_REFRESH_SECRET` via Render's generated values on incident | ✅ supported |
| 9 | Keep `NODE_ENV=production` in the container (already in `Dockerfile` + blueprint) | ✅ done |
| 10 | Disable Android `allowBackup` so secure-storage ciphertext is not auto-restored | ❌ mobile backlog |

Deployments should only proceed through CI (`.github/workflows/ci.yml`) green on `main`, which runs the
docker build job that mirrors the Render image build.
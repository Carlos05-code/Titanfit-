# TitanFit API — Deployment

Node.js + Express + TypeScript + Prisma + PostgreSQL backend for TitanFit.

## Prerequisites

- Node.js 20+ (local dev)
- Docker (for containerized/local stacks)
- Any of: Render / Railway / Fly.io / a VPS for cloud hosting

## Local development

```bash
cd backend
npm install
cp .env.example .env      # set DATABASE_URL to your local Postgres
npx prisma migrate deploy
npm run dev               # ts-node-dev, watches files
```

Health check: `GET http://localhost:3000/health`

## Environment variables

| Variable                  | Description                                   | Default            |
| ------------------------- | --------------------------------------------- | ------------------ |
| `DATABASE_URL`            | PostgreSQL connection string                  | *(required)*       |
| `JWT_SECRET`              | Access-token signing secret                   | `fallback-secret`  |
| `JWT_REFRESH_SECRET`      | Refresh-token signing secret                  | `fallback-refresh-secret` |
| `JWT_EXPIRES_IN`          | Access token TTL                              | `15m`              |
| `JWT_REFRESH_EXPIRES_IN`  | Refresh token TTL                             | `7d`               |
| `PORT`                    | HTTP port                                     | `3000`             |
| `NODE_ENV`                | environment                                   | `development`      |

> **Never** use the fallback secrets in production. Set strong random values.

## Option A — Docker Compose (local / VPS)

```bash
cd backend
docker compose up --build
```

- API on `http://localhost:3000`
- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`
- Migrations run automatically on container start.

## Option B — Render (free, recommended)

1. Push this repo to GitHub.
2. In Render, **New → Blueprint**, connect the repo, select `render.yaml`.
3. Render provisions the Docker web service + managed Postgres and wires `DATABASE_URL` automatically.
4. Deploys take effect on push to `main` (Blueprint autoDeploy).

The web service runs `npx prisma migrate deploy && node dist/server.js` on boot,
so the schema is migrated before traffic arrives.

## Option C — Railway

1. New Project → Deploy from GitHub repo.
2. Add a **PostgreSQL** service; copy its connection string.
3. Add a service from the repo root with these settings:
   - Root directory: `backend`
   - Build: `npm ci && npx prisma generate && npm run build`
   - Start: `npx prisma migrate deploy && node dist/server.js`
   - Add a `DATABASE_URL` variable bound to the Postgres service, plus `JWT_SECRET`/`JWT_REFRESH_SECRET`.

## Option D — Manual VPS (pm2/systemd)

```bash
cd backend
npm ci --omit=dev
npx prisma migrate deploy
npm run build
node dist/server.js            # or: pm2 start dist/server.js
```

Wedge behind nginx/Caddy for TLS.

## Checking a deployment

```bash
curl https://<your-host>/health
# {"status":"ok","timestamp":"..."}
```
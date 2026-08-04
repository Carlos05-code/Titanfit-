#!/usr/bin/env bash
# TitanFit quality gate — mirrors .github/workflows/ci.yml locally.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> API: install (noop if cached) / generate / build / test"
(cd apps/api && npm ci --silent)
(cd apps/api && npx prisma generate)
(cd apps/api && npm run build)
(cd apps/api && npm test)

echo "==> API: docker build"
docker build -q -t titanfit-api:check apps/api

echo "==> Mobile: pub get / format / analyze / test"
(cd apps/mobile && flutter pub get)
(cd apps/mobile && dart format --set-exit-if-changed .)
(cd apps/mobile && flutter analyze)
(cd apps/mobile && flutter test)

echo "==> check complete ✓"
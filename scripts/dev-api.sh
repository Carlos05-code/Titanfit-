#!/usr/bin/env bash
# Boot the TitanFit API locally.
set -euo pipefail
cd "$(dirname "$0")/../apps/api"
[ -f .env ] || { echo "Missing apps/api/.env — copy .env.example first."; exit 1; }
npm run dev
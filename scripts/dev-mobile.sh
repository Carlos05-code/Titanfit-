#!/usr/bin/env bash
# Run the Flutter app. Defaults to the live API; pass a BASE_URL to override.
set -euo pipefail
cd "$(dirname "$0")/../apps/mobile"
BASE_URL="${1:-}"
if [ -n "$BASE_URL" ]; then
  flutter run --dart-define=API_BASE_URL="$BASE_URL"
else
  flutter run
fi
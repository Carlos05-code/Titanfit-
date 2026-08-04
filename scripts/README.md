# Developer Scripts

Cross-platform developer tooling for the TitanFit monorepo. All scripts are POSIX `bash`
and usable in CI (GitHub Actions) or on macOS/Linux. Windows users can run them inside
WSL/Git-Bash or use the underlying commands directly.

| Script | Purpose |
|---|---|
| `check.sh` | Runs the full quality gate: backend build+tests, mobile format+analyze+tests |
| `dev-api.sh` | Starts the API locally with the expected env (requires `apps/api/.env`) |
| `dev-mobile.sh` | Boots the Flutter app against a local/free backend (dart-define override) |
| `seed.sh` | Runs the Prisma seed (idempotent) |

## Usage

```bash
./scripts/check.sh      # full CI-equivalent gate locally
./scripts/dev-api.sh    # API on :3000
./scripts/dev-mobile.sh # runs flutter run with API_BASE_URL override
```

The canonical CI pipeline is defined in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)
and mirrors `check.sh`.
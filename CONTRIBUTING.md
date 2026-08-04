# Contributing to TitanFit

First off, thank you for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to TitanFit. Use your best judgment, and
feel free to propose changes to this document.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Style Guidelines](#style-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Testing](#testing)
- [Review Process](#review-process)

## Code of Conduct

This project and everyone participating in it is governed by our
[Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository on GitHub.
2. Clone your fork and add the upstream remote:

   ```bash
   git clone https://github.com/<your-username>/Titanfit-.git
   cd Titanfit-
   git remote add upstream https://github.com/Carlos05-code/Titanfit-.git
   ```

3. Set up your local environment:
   - Backend: see [apps/api/.env.example](apps/api/.env.example) and run `npm install`.
   - Mobile: `flutter pub get` in `apps/mobile`.
4. Create a working branch: `git checkout -b feat/<short-description>`.

## How Can I Contribute?

- **Reporting bugs** — open an issue with a clear reproduction path.
- **Suggesting features** — open a discussion or issue describing the problem & proposed solution.
- **Submitting changes** — small, focused pull requests are always welcome.

## Development Workflow

Always branch from `main`, keep your branch up to date, and open a pull request when ready.

```bash
git checkout main && git pull upstream main
git checkout -b feat/my-change
# ...make changes...
git add -A
git commit -m "feat(scope): concise description"
git push -u origin feat/my-change
```

## Style Guidelines

**Flutter / Dart**

- Run `flutter analyze` — no new diagnostics allowed.
- Format with `dart format` before committing.
- Follow the existing feature-first folder structure (`features/<feature>/{presentation,data}`).
- No dead imports; prune unused dependencies via `flutter pub deps`.

**Node.js / TypeScript**

- The project runs with `strict` mode — new code must type-check with `npm run build`.
- Validate external input with Zod schemas.
- Never `console.log` secrets; use the centralized error handler; forward errors via `next(err)`.

## Commit Guidelines

Use [Conventional Commits](https://www.conventionalcommits.org):

```
<type>(<optional scope>): <description>

Examples:
  feat(auth): add biometric unlock
  fix(sleep): validate sleepTime/wakeTime before scoring
  refactor(core): extract shared stat card widget
  docs(api): document endpoint contracts
  test(workout): cover session timer edge cases
  ci(github): add backend test job
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`, `security`, `style`.

## Testing

- Backend changes should include Jest unit/integration tests under `apps/api/tests/`.
- Mobile changes should include `flutter test` unit/widget tests.
- All tests must pass in CI before a PR merges.

## Review Process

- Keep PRs small and single-purpose.
- Reference the issue you address (`Closes #12`).
- A maintainer will review; address feedback in new commits (no force-push history rewrites).
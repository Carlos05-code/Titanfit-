# Security Policy

We take the security of TitanFit seriously. This document describes how to
report vulnerabilities and the guarantees the project makes.

## Supported Versions

| Version | Supported |
|---|---|
| 1.0.x (initial release) | ✅ |

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately to:

- Email: `carlosmasawe4@gmail.com`
- Subject prefixed with `[SECURITY]`

You can expect:

1. An acknowledgement within **48 hours**.
2. A first assessment of severity and impact within **5 business days**.
3. A fixed version or a mitigation plan.

Please include:

- Description of the vulnerability
- Steps to reproduce
- Affected endpoints/components
- Suggested fix (optional)

## Security Posture

### Secrets & credentials

- `.env` files are **never committed**. Only `.env.example` placeholders live in the repo.
- JWT signing secrets **must not** use the code fallbacks in
  `apps/api/src/config/index.ts` in any environment that matters.
  On Render they are generated at deploy time (`generateValue: true` in `render.yaml`).

### Report responsibly

We practice responsible disclosure and appreciate coordinated efforts. We will
not pursue legal action against researchers who:

- Make a good-faith effort to avoid privacy violations and data destruction.
- Allow us a reasonable window to respond before public disclosure.
- Report findings through this policy.

## Hardening Checklist

Production deployments should ensure:

- ✅ `NODE_ENV=production` (suppresses stack traces in API responses)
- ✅ Strong `JWT_SECRET` / `JWT_REFRESH_SECRET` (never the fallback values)
- ✅ Rate limiting enabled on `/auth/*`
- ✅ CORS allowlist set via `CORS_ORIGINS`
- ✅ Android `allowBackup=false` in the app manifest
- ✅ Unique, complex app secrets outside source control
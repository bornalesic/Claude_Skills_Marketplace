# Contract: environment variables

Version 1.0 (2026-10-26)

Every app validates its env with Zod (`parseEnv` from `@upskillzz/shared`) at startup and exits with one readable error listing every problem. Locally, all apps read the worktree root's `.env.local`. In Fly.io, values are app secrets or `[env]` entries in the Fly config. `.env.example` lists every variable with a safe local default.

| Variable | Used by | Required | Local default | Production | Notes |
|---|---|---|---|---|---|
| `NODE_ENV` | all | yes | `development` | `production` | |
| `WORKSTREAM` | scripts | no | `main` | — | Informational, set by `setup-worktrees.sh` |
| `WEB_PORT` | web | yes | `3000` (per worktree) | `3000` | Fly maps it |
| `MCP_PORT` | mcp | yes | `3001` (per worktree) | `3001` | |
| `APP_URL` | web, mcp, content, payments | yes | `http://localhost:3000` | `https://upskillzz.com` | No trailing slash. Used for links and Stripe return URLs |
| `MCP_URL` | web, mcp, auth | yes | `http://localhost:3001/mcp` | `https://mcp.upskillzz.com/mcp` | Exact OAuth resource identifier |
| `DATABASE_URL` | web, mcp, content CLI | yes | `postgres://upskillzz:upskillzz@localhost:5432/upskillzz` | Neon pooled URL | Database name differs per worktree |
| `BETTER_AUTH_SECRET` | web | yes | random per worktree | secret | At least 32 random bytes |
| `BETTER_AUTH_URL` | web | yes | `= APP_URL` | `= APP_URL` | |
| `GOOGLE_CLIENT_ID` | web | prod only | empty | secret | Google sign-in hidden when empty in dev |
| `GOOGLE_CLIENT_SECRET` | web | prod only | empty | secret | |
| `DEV_LOGIN_ENABLED` | web | no | `true` | must be unset | App refuses to start if `true` with `NODE_ENV=production` |
| `AUTH_ISSUER` | mcp | yes | `http://localhost:3000/api/auth` | `https://upskillzz.com/api/auth` | Must equal Better Auth's issuer exactly; W1 confirms |
| `AUTH_JWKS_URL` | mcp | yes | `http://localhost:3000/api/auth/jwks` | `https://upskillzz.com/api/auth/jwks` | W1 confirms |
| `RATE_LIMIT_PER_MIN` | mcp | no | `60` | `60` | Tool calls per user per minute |
| `LOG_LEVEL` | web, mcp | no | `info` | `info` | pino levels |
| `STRIPE_SECRET_KEY` | web, content CLI | yes for checkout | `sk_test_...` | live key, secret | |
| `STRIPE_WEBHOOK_SECRET` | web | yes for webhooks | from `stripe listen` | secret | |
| `STRIPE_AUTOMATIC_TAX` | web | no | `false` | `true` | Needs Stripe Tax configured in the dashboard |
| `CONTENT_DIR` | content | no | `<repo>/content` | `<repo>/content` | |
| `CONTENT_INCLUDE_SAMPLES` | content | no | `true` | must be unset | Loads `_samples` skills and packs |
| `SENTRY_DSN` | web, mcp | no | empty | optional | Error tracking, off when empty |

Rules:
- Never read `process.env` outside an app's `env.ts`. Pass config down.
- Never prefix secrets with `NEXT_PUBLIC_`. The website reads `MCP_URL` on the server and renders it.
- Adding a variable is a contract change: request it, then add it here and to `.env.example`.

## Changelog

- 1.0 (2026-10-26): initial version.

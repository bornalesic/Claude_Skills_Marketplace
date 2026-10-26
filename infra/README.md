# infra

How Upskillzz runs outside your laptop.

| Piece | Where | Notes |
|---|---|---|
| Website (`apps/web`) | Fly.io app, Frankfurt, always on | Behind Cloudflare |
| MCP server (`apps/mcp`) | Fly.io app, Frankfurt, always on | `mcp.<domain>`, DNS-only by default |
| Database | Neon Postgres, Frankfurt | Free plan to start |
| DNS, TLS, caching | Cloudflare Free | |
| Payments | Stripe | Test mode on staging |

Locally, `pnpm db:up` starts Postgres from `docker-compose.dev.yml`.

Environments: **staging** deploys on every push to `main`; **production** deploys on approval or a version tag. Operating instructions: `docs/RUNBOOK.md` (written by W7). Expected cost: about $6 to $10 a month to start (`docs/DECISIONS.md` D2).

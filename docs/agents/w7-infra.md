# Brief: W7 infrastructure and deploy

**Branch:** `ws/w7-infra` · **Phase:** 2 (may start once W0 is merged) · **Ports:** 3080 / 3081 · **DB:** `upskillzz_w7`

## Mission

Ship Upskillzz to staging and production cheaply and reliably: two always-on Fly.io apps in Frankfurt, Neon Postgres, Cloudflare in front, and a pipeline where merging to `main` migrates, syncs content, and deploys in the right order. Write the runbook Borna will use when something breaks.

## Read first

- `docs/DECISIONS.md` D2 (hosting and costs), D3 (Anthropic egress range and OAuth constraints), `docs/ARCHITECTURE.md` (public URLs, flow 4), `docs/contracts/env.md`, `docs/LAUNCH_CHECKLIST.md`
- `infra/CLAUDE.md`

## You own

`infra/**` except `infra/docker-compose.dev.yml` and `infra/postgres-init/**`; `.github/workflows/deploy*.yml`; `docs/RUNBOOK.md` (new).

## Verify before building

Fly.io: Dockerfile deploys, `fly.toml` (`min_machines_running`, `auto_stop_machines`, health checks, `[env]`, secrets), regions and current pricing, GitHub Actions deploy with `flyctl`. Neon: pooled vs direct connection strings, branches for staging, point-in-time restore on the free plan. Cloudflare: proxied vs DNS-only records, cache rules, WAF and Bot Fight Mode exceptions. Turborepo `prune` for Docker builds. Next.js standalone output.

## Deliverables

1. **Dockerfiles** `infra/docker/web.Dockerfile` and `infra/docker/mcp.Dockerfile`: multi-stage, `turbo prune` for a minimal context, pnpm with cache mounts, non-root user, Next.js standalone output for web, `node dist/index.js` for MCP, health checks. The web build runs `content:build` first so the catalog is baked in. Images under 250 MB if feasible.
2. **Fly configs** `infra/fly/web.production.toml`, `web.staging.toml`, `mcp.production.toml`, `mcp.staging.toml`: region `fra`, one always-on machine each (`min_machines_running = 1`, no auto-stop in production), smallest shared CPU size that passes a basic load test (start at 512 MB for web, 256 or 512 MB for MCP), HTTP health checks on `/api/health` and `/healthz`, graceful shutdown timeouts.
3. **Environments:** staging (`staging.upskillzz.com`, `mcp-staging.upskillzz.com`, Stripe test mode, Neon branch or separate project, `CONTENT_INCLUDE_SAMPLES=true` allowed) and production. A table in the runbook of every secret per app and environment, matching `env.md`.
4. **Deploy workflow** `.github/workflows/deploy.yml`: on push to `main` → staging; production on a manual approval or a `v*` tag. Steps in order: CI checks → `db:migrate` → `content:sync -- --stripe` → deploy MCP → deploy web → smoke test (`/api/health`, `/healthz`, an unauthenticated `POST /mcp` returns `401` with `WWW-Authenticate`). Stop on the first failure.
5. **Cloudflare guide** in `infra/cloudflare.md`: DNS records; web proxied with caching for static assets; never cache `/api/*`, `/.well-known/*` or HTML for signed-in pages; MCP host DNS-only by default (or proxied with no challenges and the Anthropic range `160.79.104.0/21` allowed); Bot Fight Mode and WAF rules must not challenge `/api/auth/*`, `/.well-known/*` or the MCP host; TLS full (strict).
6. **Monitoring:** uptime checks on both health endpoints with a free service (document setup), Fly metrics, optional Sentry via `SENTRY_DSN`; Fly spend alert.
7. **`docs/RUNBOOK.md`:** deploy, rollback (previous image), rotate each secret, restore the database from Neon, rerun content sync, re-send a Stripe webhook, "Claude can't connect" checklist (401 header present? metadata reachable? issuer matches? egress range blocked? token endpoint slow?), and cost check.
8. **Cost note** in the runbook: actual monthly cost after a week of staging, compared with D2's estimate.

## Acceptance checks

- `docker build` succeeds for both images from a clean checkout; containers start with a test env and pass health checks locally.
- Staging is live: site loads over HTTPS, health endpoints green, `POST /mcp` without a token returns `401` with `resource_metadata`, and MCP Inspector completes OAuth against staging.
- The deploy workflow has run successfully at least once on staging.

## Out of scope

App code. Request changes from the owning workstream if a build needs something (for example a health check field).

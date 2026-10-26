# infra/ — CLAUDE.md

Owner: **W7**, except `docker-compose.dev.yml` and `postgres-init/` (**W0**, local development database). Brief: `docs/agents/w7-infra.md`. Hosting decision: `docs/DECISIONS.md` D2.

## Planned layout

```
infra/
  docker-compose.dev.yml     local Postgres 17 for all worktrees (W0)
  postgres-init/             creates upskillzz, upskillzz_w0 ... upskillzz_w8 (W0)
  docker/
    web.Dockerfile
    mcp.Dockerfile
  fly/
    web.production.toml  web.staging.toml
    mcp.production.toml  mcp.staging.toml
  cloudflare.md              DNS, caching and WAF settings
```

Deploy workflow: `.github/workflows/deploy.yml` (W7). Runbook: `docs/RUNBOOK.md` (W7).

## Rules

- Region `fra` for both apps and the database, close to the EU buyers and to each other.
- Both apps always on in production (`min_machines_running = 1`, no auto-stop). Cold starts are not acceptable for OAuth: Claude gives token endpoints 10 seconds.
- Deploy order: migrate → content sync → MCP → web → smoke test. Stop on the first failure.
- Secrets only as Fly secrets or GitHub Actions secrets. The runbook lists every one.
- Nothing in front of the OAuth endpoints or the MCP host may challenge or block Anthropic's egress range `160.79.104.0/21`.
- `DEV_LOGIN_ENABLED` and `CONTENT_INCLUDE_SAMPLES` are never set in production.

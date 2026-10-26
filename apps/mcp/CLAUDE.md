# apps/mcp — CLAUDE.md

The MCP server Claude connects to. Owner: **W2**. Spec: `docs/contracts/mcp.md`.

Per request: verify the bearer token → load the user's owned skills (short cache) → build a fresh MCP server with one tool per owned skill (plus two fixed tools and any action tools) → handle the request. Paid content leaves this service only here, only to owners.

## Structure

```
src/
  index.ts                  boot: env, db, http server, graceful shutdown
  env.ts                    Zod-validated config; the only place reading process.env
  http/
    app.ts                  Hono app: routes, CORS, error handling
    protected-resource.ts   /.well-known/oauth-protected-resource[/mcp]
    auth-gate.ts            401 / 403 with the exact WWW-Authenticate headers
  auth/
    verify.ts               re-exports createTokenVerifier (stub until W1 merges)
  server/
    build-server.ts         McpServer per request: info, instructions, tools
  tools/
    library.ts              upskillzz_library
    load-skill.ts           upskillzz_load_skill
    skill-tool.ts           one tool per owned skill
    action-tool.ts          one tool per action
    format.ts               delivery and reference text formats from the contract
  delivery/
    watermark.ts            applyWatermark (no-op in v1)
  limits/
    rate-limit.ts           per-user token bucket
  cache/
    owned-skills.ts         30 s per-user cache
  usage/
    log-usage.ts            async insert into mcp_usage
test/
  fixtures/                 seed data, test issuer (jose key pair + JWKS server), sample action registry
  *.test.ts
```

## Rules

- Follow `docs/contracts/mcp.md` to the letter: tool names, descriptions, input schemas, output text, error texts, headers. The tutorial and tests depend on them.
- Accept MCP protocol 2026-07-28 and 2025-11-25. Never configure the SDK to reject legacy clients.
- Unauthenticated requests get `401`, never `200`. Include `resource_metadata` in `WWW-Authenticate`.
- Re-check ownership inside each tool handler before returning paid text; the cached tool list is not an authorization check.
- Every piece of paid text goes through `applyWatermark` right before it is returned.
- Never log tokens, emails or paid text. Log `userId`, tool, outcome, duration.
- Usage logging must never slow down or fail a response.
- Don't import `@upskillzz/auth` (the server instance); import only `@upskillzz/auth/verify`.
- No session store. If you think you need state between requests, raise it in your status file first.

## Testing

Vitest with a real local Postgres (`withTestDb`) and the MCP SDK client against an in-process server. A test issuer in `test/fixtures` signs tokens and serves a JWKS, so tests don't need the website running. `pnpm --filter @upskillzz/mcp test`.

Manual: `npx @modelcontextprotocol/inspector` → Streamable HTTP → `http://localhost:$MCP_PORT/mcp`. With Claude Code: `claude mcp add --transport http upskillzz-local http://localhost:$MCP_PORT/mcp`, then `/mcp`.

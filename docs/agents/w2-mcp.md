# Brief: W2 MCP server

**Branch:** `ws/w2-mcp` · **Phase:** 1 · **Ports:** 3030 / 3031 · **DB:** `upskillzz_w2`

## Mission

Build `apps/mcp`, the server buyers connect Claude to. It verifies the user's token, shows exactly the tools for the skills they own, and delivers skill instructions, references and action results. It must be fast, never leak paid content to non-owners, and work with every Claude surface.

## Read first

- `docs/contracts/mcp.md` (your main spec), `interfaces.md` (`@upskillzz/auth/verify`, `@upskillzz/entitlements`, `@upskillzz/content/actions`, `@upskillzz/shared`), `database.md` (`mcp_usage`, catalog tables), `env.md`
- `docs/ARCHITECTURE.md` flows 2 and 3, `docs/DECISIONS.md` D4 to D6, D8, D10
- `apps/mcp/CLAUDE.md`

## You own

`apps/mcp/**`.

## Verify before building

- MCP TypeScript SDK v2: server, Streamable HTTP handler, stateless mode, how it serves both 2026-07-28 and 2025-11-25 clients, tool registration with Zod or JSON Schema, annotations, `structuredContent`: https://github.com/modelcontextprotocol/typescript-sdk
- MCP spec 2026-07-28: stateless core, `server/discover`, required headers, and the caching utility (does it apply to `tools/list`?): https://modelcontextprotocol.io/specification/2026-07-28
- Better Auth's resource-server helpers (`createMcpProtectedRequestHandler`, challenge builders): https://better-auth.com/docs/plugins/mcp
- Claude's requirements for the `401` and protected resource metadata: https://claude.com/docs/connectors/building/authentication.md

## Stubs until others merge

| You need | From | Until merged |
|---|---|---|
| `createTokenVerifier` | W1 (`@upskillzz/auth/verify`) | Implement the same signature in `src/auth/verify-stub.ts` with `jose`; in tests, generate a key pair and serve a local JWKS |
| `listOwnedSkills`, `getOwnedSkillContent`, `getOwnedReference` | W4 (`@upskillzz/entitlements`) | Implement simple versions in `src/data/entitlements-stub.ts` against the schema in `database.md` |
| `actionRegistry` | W3 (`@upskillzz/content/actions`) | A hand-written registry in `test/fixtures/` with one sample action |
| Catalog rows in the DB | W3 sync | A seed script in `test/fixtures/seed.ts` (two users, three skills, one with a reference and an action, one archived, one pack) |

Keep stubs behind the same import names so swapping is a one-line change. List them in your status file.

## Deliverables

1. **HTTP app** (Hono on Node): `/mcp`, both protected-resource metadata routes, `/healthz`, CORS exactly as in `mcp.md`.
2. **Auth gate** in front of the MCP handler: `401` / `403` responses with the exact `WWW-Authenticate` headers in `mcp.md`. Never a `200` for unauthenticated requests.
3. **Per-request server:** verify token → owned skills (30-second per-user cache) → build an `McpServer` with the server name, version and instructions from `mcp.md` → register tools → handle the request. Accept both protocol versions.
4. **Tools** exactly as named and described in `mcp.md`: `upskillzz_library`, `upskillzz_load_skill`, one per owned skill, one per action. Ownership is re-checked inside every handler (don't trust the cached list alone for content). Outputs in the exact delivery and reference formats.
5. **Actions runtime:** look up `actionRegistry[slug][name]`, validate input, run with `ctx` and a 10-second abort, map results and errors as specified.
6. **`applyWatermark`** in `src/delivery/watermark.ts`, called on every piece of paid text; returns its input unchanged in v1.
7. **Rate limiting** per user (token bucket, `RATE_LIMIT_PER_MIN`).
8. **Usage logging** to `mcp_usage` after the response, non-blocking.
9. **Logging** with pino: user id, tool, outcome, duration; never tokens, emails or paid text.
10. **Graceful shutdown** (close DB pool on SIGTERM) and a startup log line with version and protocol versions accepted.

## Tests (Vitest, against a real local Postgres)

Use the MCP SDK's client to talk to an in-process server:

- Unauthenticated `POST /mcp` → `401` with the correct `WWW-Authenticate`; protected-resource metadata body matches the contract.
- Wrong audience → `401`; missing `skills` scope → `403`.
- User A sees `upskillzz_library`, `upskillzz_load_skill`, their skill tools and action tools, and nothing of user B's.
- Calling a skill tool returns the delivery format; `reference` returns the reference format; unknown reference → `isError`.
- `upskillzz_load_skill` for an owned skill works; for an unowned one returns the purchase message; for an unknown slug the not-found message.
- An archived skill is still delivered to its owner; a draft never is.
- Action: valid input returns structured content; invalid input → `isError`; a slow action is aborted at 10 s (use fake timers or a short test timeout setting).
- Rate limit returns the contract message after the limit.
- A client negotiating 2025-11-25 and one using 2026-07-28 both list and call tools.
- `mcp_usage` rows are written with the right outcome.
- Paid text never appears in log output (capture logs in a test).

## Acceptance checks

- `pnpm --filter @upskillzz/mcp test` green.
- MCP Inspector connects to `http://localhost:3031/mcp` using your stub verifier setup (document how in the status file) and lists the seeded user's tools.
- After W1 merges: Inspector completes the real OAuth flow against the W1 auth server and lists tools.
- A tool call on a warm cache completes in under 50 ms locally (log it in your status file).

## Out of scope

Issuing tokens (W1), granting ownership (W4), loading content files (W3).

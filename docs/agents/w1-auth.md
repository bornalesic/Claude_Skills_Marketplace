# Brief: W1 auth and OAuth

**Branch:** `ws/w1-auth` · **Phase:** 1 · **Ports:** 3020 / 3021 · **DB:** `upskillzz_w1`

## Mission

Buyers sign in with Google on the site. Claude signs in through the site too: the website must be a standards-compliant OAuth 2.1 authorization server that claude.ai, the Claude desktop and mobile apps, and Claude Code can all connect through. This is the riskiest part of the project. Get it working end to end early and test it against real clients as soon as staging exists.

## Read first

- `docs/DECISIONS.md` D3 and D4 (Claude's exact OAuth requirements are listed there)
- `docs/ARCHITECTURE.md` flow 2
- `docs/contracts/interfaces.md` (`@upskillzz/auth`), `http-routes.md` (Better Auth section, `/sign-in`, `/consent`), `mcp.md` (Authentication), `env.md`, `database.md` (Better Auth tables)
- `packages/auth/CLAUDE.md`, `apps/web/CLAUDE.md`

## You own

`packages/auth/**`, `packages/db/src/schema/auth.ts`, `apps/web/src/app/api/auth/**`, `apps/web/src/app/(auth)/**`, `apps/web/src/app/.well-known/**`, `apps/web/src/lib/auth-client.ts`, `apps/web/src/lib/session.ts`, and the Next.js request middleware/proxy file.

## Verify before building

- Better Auth core, Google provider, Drizzle adapter: https://better-auth.com/docs
- Better Auth MCP plugin: https://better-auth.com/docs/plugins/mcp (and the OAuth Provider, CIMD and JWT plugin pages it links)
- Claude's connector auth requirements: https://claude.com/docs/connectors/building/authentication.md and the lazy-authentication and troubleshooting pages next to it
- MCP authorization spec, versions 2025-11-25 and 2026-07-28: https://modelcontextprotocol.io/specification

Record what you verified in your status file.

## Deliverables

1. **Better Auth instance** in `packages/auth` (`auth`, `getSessionUser`) using the Drizzle adapter on `@upskillzz/db`:
   - Google provider with scopes `openid email profile`. Hidden when `GOOGLE_CLIENT_ID` is empty (dev).
   - Dev login ("Continue as test user", a fixed test user plus an optional second one for tests) only when `DEV_LOGIN_ENABLED=true`. If that is set with `NODE_ENV=production`, throw at startup.
   - JWT plugin, `mcp()` plugin with `resource = MCP_URL`, `loginPage: "/sign-in"`, `consentPage: "/consent"`, scopes `openid profile email offline_access skills`; CIMD plugin; DCR explicitly enabled (unauthenticated registration, application type inferred so loopback clients register as native).
   - Access tokens about 1 hour; refresh tokens rotate (keep Better Auth's short reuse window for retries).
2. **Redirect URI acceptance:** `https://claude.ai/api/mcp/auth_callback` exactly; `http://localhost:<any port>/callback` and `http://127.0.0.1:<any port>/callback` port-agnostic (Claude Code). Write a test for each.
3. **Discovery.** Authorization server metadata at the RFC 8414 location for the issuer (and OpenID discovery if Better Auth provides it), containing everything listed in `http-routes.md`. Confirm the exact issuer string and JWKS URL and update `.env.example` defaults through a contract change request if they differ from `env.md`.
4. **Token endpoint behaviour:** accepts `application/x-www-form-urlencoded`; invalid refresh returns `invalid_grant`; responds well under 10 seconds (aim for under 500 ms locally).
5. **Pages.**
   - `/sign-in?next=`: "Continue with Google", plus the dev button when enabled. Works both for normal site sign-in and when Better Auth sends the user here mid-OAuth (resume the flow after sign-in).
   - `/consent`: shows the client's name, the redirect URI's **hostname prominently**, an extra warning when the client only has loopback redirect URIs, the scope in plain words ("See which Upskillzz skills you own and load them in Claude"), Allow and Deny. Use W5's design tokens (or neutral Tailwind until they exist).
6. **Web helpers** exactly as in the "Inside apps/web" section of `interfaces.md`: `src/lib/session.ts` (`getCurrentUser`, `requireUser`) and `src/lib/auth-client.ts` (`signInWithGoogle`, `signInAsTestUser`, `signOut`). W5 uses these for the header and protected pages.
7. **`@upskillzz/auth/verify`:** `createTokenVerifier` exactly as in `interfaces.md` (JWKS cached, refetch on unknown `kid`, checks iss, aud, exp, required scopes, typed errors). It must not import the Better Auth server instance or anything that needs the database.
8. **Schema:** keep `schema/auth.ts` in sync with your plugin set (regenerate with the CLI). Don't generate migrations; tell the orchestrator in your status file when it changed.

## Tests

- Verifier: valid token; wrong audience; wrong issuer; expired; missing scope; unknown `kid` triggers one JWKS refetch.
- Full authorization code + PKCE flow against a running local server, scripted (no browser needed with the dev login): through CIMD, and through DCR. Then refresh, then refresh again with the old token (rotation).
- Redirect URI matching cases from deliverable 2.
- Production guard: dev login enabled with `NODE_ENV=production` throws.
- Manual: MCP Inspector against your worktree once W2's endpoint answers `401` correctly (or a tiny local protected route you write in a test).

## Acceptance checks

- Dev login and (with credentials) Google login work on `http://localhost:3020`.
- A scripted client obtains a token with `aud = MCP_URL` and `scope` containing `skills` through both CIMD and DCR.
- `createTokenVerifier` verifies that token from a separate process using only the JWKS URL.
- Status file lists the final issuer, metadata URL(s), JWKS URL and Google callback path.

## Later, on staging (Phase 3)

Connect from claude.ai, Claude Desktop, Claude mobile and Claude Code. If CIMD fails with any of them, confirm DCR works and record which surface used which.

## Out of scope

The MCP server itself (W2), page design beyond the two auth pages (W5), purchases (W4).

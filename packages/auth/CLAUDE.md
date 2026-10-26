# packages/auth — CLAUDE.md

Owner: **W1**. Spec: `docs/contracts/interfaces.md` (`@upskillzz/auth`), `docs/DECISIONS.md` D3.

Better Auth configuration for the whole product: Google sign-in for buyers, the dev-only test login, and the OAuth 2.1 provider (MCP plugin, JWT, CIMD, DCR) that Claude signs in through. Plus a lightweight token verifier for `apps/mcp`.

## Entry points

| Import | Used by | May depend on |
|---|---|---|
| `@upskillzz/auth` | `apps/web` (server only) | `better-auth` and plugins, `@upskillzz/db`, `@upskillzz/shared` |
| `@upskillzz/auth/verify` | `apps/mcp` | `jose` (or Better Auth's resource-server helper if it has no server-side dependencies), `@upskillzz/shared` only |

Keep `verify` free of anything that needs the database, Google secrets or the Better Auth instance. A test should import it in isolation.

## Structure

```
src/
  index.ts           exports auth, getSessionUser, SessionUser
  config.ts          builds the Better Auth instance from validated options
  dev-login.ts       test-user login; throws if enabled in production
  scopes.ts          scope list and plain-language descriptions (consent page uses them)
  redirect-uris.ts   claude.ai callback + port-agnostic loopback matching
  verify/
    index.ts         createTokenVerifier, TokenError, types
test/
```

## Rules

- Claude's OAuth requirements in `docs/DECISIONS.md` D3 are hard requirements, not suggestions. Each has a test.
- CIMD and DCR both enabled. Don't remove DCR without a confirmed reason; Claude falls back to it.
- `resource` in the MCP plugin equals `MCP_URL` exactly, including the path.
- The issuer, the authorization server metadata location, `AUTH_ISSUER` and the first `authorization_servers` entry in the MCP server's metadata must all agree. If you change one, update `.env.example` and raise a contract change for `env.md`.
- When your plugin set changes, regenerate `packages/db/src/schema/auth.ts` with the Better Auth CLI and say so in your status file. Never generate migrations.
- Never log tokens, codes, secrets or full emails.

## Testing

`pnpm --filter @upskillzz/auth test`: verifier unit tests with a generated key pair; redirect URI matching; production guard; and an integration test that runs the full code + PKCE flow (CIMD and DCR) against a running local web server using the dev login.

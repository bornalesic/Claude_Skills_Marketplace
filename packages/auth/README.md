# @upskillzz/auth

Authentication for Upskillzz, built on Better Auth.

- Buyers sign in with Google (a test-user login exists for local development only).
- The website acts as an OAuth 2.1 authorization server so Claude (web, desktop, mobile, Claude Code) can connect to the MCP server on the buyer's behalf.
- `@upskillzz/auth/verify` lets the MCP server check access tokens using only the public JWKS.

```ts
import { auth, getSessionUser } from "@upskillzz/auth";          // apps/web
import { createTokenVerifier } from "@upskillzz/auth/verify";     // apps/mcp
```

Contract: `docs/contracts/interfaces.md`. Agent rules: `CLAUDE.md`.

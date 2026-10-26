# Local development

## Prerequisites

- Node 24 LTS (`.nvmrc`), with pnpm through Corepack: `corepack enable`
- Docker (for local Postgres)
- Stripe CLI, logged in to your test account: `stripe login`
- Claude Code
- Optional: MCP Inspector, run on demand with `npx @modelcontextprotocol/inspector`

## First run (any worktree)

```bash
pnpm install
pnpm db:up          # starts Postgres on localhost:5432 and creates upskillzz, upskillzz_w0 ... upskillzz_w8
pnpm db:push        # applies the current schema to this worktree's database
pnpm content:build  # builds the public catalog (includes _samples when CONTENT_INCLUDE_SAMPLES=true)
pnpm content:sync   # loads skills and packs into this worktree's database
pnpm dev            # web on WEB_PORT, MCP server on MCP_PORT
```

Each worktree reads its own `.env.local` at the repo root of that worktree. `scripts/setup-worktrees.sh` creates it from `.env.example` with the right ports, database name and a random `BETTER_AUTH_SECRET`. It never overwrites an existing `.env.local`.

## Signing in locally

With `DEV_LOGIN_ENABLED=true` (the default in `.env.example`), the sign-in page shows **Continue as test user**. That is enough for building and automated tests.

To test real Google sign-in, put your OAuth client's ID and secret in `.env.local` and register these redirect URIs on the Google client (one per worktree port you use):

```
http://localhost:3000/api/auth/callback/google
http://localhost:3010/api/auth/callback/google
http://localhost:3020/api/auth/callback/google
http://localhost:3030/api/auth/callback/google
http://localhost:3040/api/auth/callback/google
http://localhost:3050/api/auth/callback/google
http://localhost:3060/api/auth/callback/google
http://localhost:3070/api/auth/callback/google
http://localhost:3080/api/auth/callback/google
http://localhost:3090/api/auth/callback/google
```

Add the staging and production URIs later (`https://<domain>/api/auth/callback/google`). W1 confirms the exact callback path against Better Auth's current docs and updates this list if it differs.

## Stripe in test mode

```bash
stripe listen --forward-to localhost:$WEB_PORT/api/stripe/webhook
```

Copy the `whsec_...` it prints into `STRIPE_WEBHOOK_SECRET` in `.env.local`. Pay with test card `4242 4242 4242 4242`, any future date, any CVC.

Stripe Tax needs a business address and tax registrations configured in the Stripe dashboard before `automatic_tax` works. Until then keep `STRIPE_AUTOMATIC_TAX=false` locally.

## Testing the MCP server

**MCP Inspector (fastest).** Run `npx @modelcontextprotocol/inspector`, choose Streamable HTTP, URL `http://localhost:$MCP_PORT/mcp`. It walks through the OAuth flow against your local site.

**Claude Code (real client, works with localhost).**

```bash
claude mcp add --transport http upskillzz-local http://localhost:$MCP_PORT/mcp
```

Then run `/mcp` inside Claude Code to sign in. Remove it later with `claude mcp remove upskillzz-local`.

**claude.ai, Claude Desktop, Claude mobile.** These connect from Anthropic's servers, so they need public HTTPS URLs. Test them against the staging deployment (W7 sets it up), not localhost. On claude.ai: Settings → Connectors → Add custom connector → paste the MCP URL.

## Resetting

```bash
pnpm db:reset       # drops and recreates this worktree's database, then db:push and content:sync
```

## Troubleshooting

- **Port already in use:** another worktree may be running with your ports; check `.env.local`.
- **Wrong database:** confirm `DATABASE_URL` ends with your worktree's database name.
- **OAuth works in Inspector but not Claude Code:** check that loopback redirects match `localhost` and `127.0.0.1` on any port.

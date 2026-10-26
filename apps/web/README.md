# @upskillzz/web

The Upskillzz website (Next.js, App Router).

- Store: home, catalog, skill and pack pages (statically generated from the public catalog)
- Library: owned skills, "Connect Claude" instructions, order history
- Checkout: Stripe Checkout redirect, success and cancel pages, webhook
- Tutorial: step-by-step guide for connecting Claude, with screenshot and video slots
- Auth: Google sign-in, and the OAuth authorization server Claude signs in through (Better Auth)

## Run

From the repo root:

```bash
pnpm dev                              # web and MCP together
pnpm --filter @upskillzz/web dev      # web only, on WEB_PORT
pnpm --filter @upskillzz/web test
pnpm --filter @upskillzz/web build    # runs content:build first so the catalog is baked in
```

Config comes from the repo root's `.env.local` (see `docs/contracts/env.md`).

Routes and API shapes: `docs/contracts/http-routes.md`. Agent rules and design tokens: `CLAUDE.md` in this folder.

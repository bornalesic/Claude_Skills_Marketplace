# Decisions

Each entry records what was decided, why, and what it costs. Facts about third-party services were checked on 26 October 2026; links are at the bottom. Re-check prices and plan limits before launch.

New decisions are appended by the orchestrator. Don't rewrite old entries; mark them superseded.

---

## D1. TypeScript monorepo

**Decision.** One pnpm + Turborepo monorepo in TypeScript for the website, the MCP server and all shared packages.

**Why.** The website and the MCP server share a lot: database schema, skill types, the entitlement rules, token claims. In one language those contracts become shared code that every parallel agent compiles against, so mismatches show up as type errors instead of runtime bugs. The two libraries this design leans on hardest, Better Auth's MCP plugin and the official MCP TypeScript SDK v2, are TypeScript-first. Next.js and Stripe's Node SDK cover the storefront well.

**Cost.** Borna's strongest language is Python. The agents write most of the code, and TypeScript reads close enough to Python to review.

**Rejected.** Python backend (FastAPI + MCP Python SDK) with a separate frontend: two languages, contracts duplicated by hand.

## D2. Hosting: Fly.io + Neon + Cloudflare

**Decision.** `apps/web` and `apps/mcp` run as two always-on Fly.io apps in Frankfurt (`fra`). Postgres on Neon in Frankfurt. Cloudflare in front for DNS, TLS and static caching. Everything ships as Docker images, so the host can change later.

**Estimated cost to start.**

| Item | Per month |
|---|---|
| Fly.io web machine (shared CPU, 512 MB, always on) | about $3 to $4 |
| Fly.io MCP machine (shared CPU, 256 to 512 MB, always on) | about $2 to $4 |
| Neon Free | $0 |
| Cloudflare Free | $0 |
| Domain | about $1 ($10 to $15 a year) |
| **Total** | **about $6 to $10** |

Fly.io's pricing page lists a shared-cpu-1x machine with 256 MB at $1.94 a month and a 512 MB shared machine at $3.89 in Ashburn; other regions are priced slightly differently.

Per sale: Stripe's processing fee plus 0.5% for Stripe Tax (see D9).

**Why this keeps performance up.** Machines are always on, so there are no cold starts. Catalog pages are static and cached at the edge. The one compromise: Neon Free suspends compute after 5 idle minutes (not configurable on Free) and the next query typically waits under a second. Signed-in actions and MCP calls can hit that after a quiet period. When there are paying customers, move to a paid Neon plan with scale-to-zero disabled.

**Rejected.**
- Vercel Hobby: free, but Vercel restricts Hobby to non-commercial personal use. A store is commercial.
- Vercel Pro: $20 per user per month. A good choice if you'd rather pay for zero-ops Next.js hosting; the MCP server could then run as a route or on Fly. Keep as the fallback.
- Railway: Hobby is $5 a month, but according to Railway's own forum its terms limit Hobby to non-commercial use, so a store would need Pro at $20.
- Hetzner VPS: was the cheapest option, but after two price rises in 2026 its cost-optimised plans showed as unavailable in September 2026, with regular plans from about €12. Also means running the server yourself.
- Cloudflare Workers for everything: cheap and fast, but Next.js needs an adapter there, and Better Auth's CIMD support requires injecting a custom secure fetch transport on non-Node runtimes. More risk for parallel agents.

## D3. Auth: Better Auth, Google sign-in, site is the OAuth server

**Decision.** Better Auth in `apps/web` with the Google provider for buyers, plus the `@better-auth/mcp` plugin (with the JWT plugin and the `@better-auth/cimd` companion) so the website is the OAuth 2.1 authorization server for MCP clients. Buyers sign in with the same Google account on the site and in Claude.

**Why.** Claude's connectors expect OAuth with either Dynamic Client Registration or a Client ID Metadata Document, PKCE S256, protected-resource discovery, and refresh-token rotation. Better Auth's MCP plugin implements an OAuth 2.1 provider with MCP resource binding and serves protected-resource metadata, and it can verify tokens on a separate resource server through the JWKS. Writing an OAuth server by hand would be the riskiest part of the project.

**What Claude requires (from Anthropic's connector auth docs).**
- Unauthenticated requests must get a `401` with `WWW-Authenticate: Bearer resource_metadata="..."`. Claude ignores that header on a `200`.
- The protected-resource `resource` must equal the MCP URL exactly as the user enters it. Claude uses only the first entry in `authorization_servers`.
- Claude uses CIMD only when the authorization server metadata advertises both `client_id_metadata_document_supported: true` and `none` in `token_endpoint_auth_methods_supported`; otherwise it falls back to DCR.
- Redirect URIs: `https://claude.ai/api/mcp/auth_callback` for the Claude apps; Claude Code uses loopback redirects on a random port, so `http://localhost/callback` and `http://127.0.0.1/callback` must match with the port ignored.
- PKCE S256 on every request, advertised in `code_challenge_methods_supported`.
- The token endpoint must accept `application/x-www-form-urlencoded` and respond within 10 seconds (30 for refresh). Invalid refresh tokens return `invalid_grant`. Refresh tokens for public clients must rotate.
- Claude adds `offline_access` when the server advertises it, to get a refresh token.
- Anthropic's outbound traffic comes from `160.79.104.0/21`; firewalls must let it reach both the MCP server and the OAuth endpoints.

**Our choices.** Enable CIMD (preferred) and also enable DCR, because Claude falls back to DCR and Better Auth never enables DCR implicitly. One scope for MCP access: `skills`.

**Risk to verify early (W1).** Better Auth's docs pair the 2026-07-28 MCP profile with a pinned CIMD draft. Confirm a real claude.ai and Claude Code connection works against staging; if CIMD fails, DCR must still work.

## D4. MCP protocol versions: accept both

**Decision.** `apps/mcp` accepts the stateless 2026-07-28 protocol and the earlier 2025-11-25 protocol.

**Why.** The 2026-07-28 spec moved MCP to a stateless request/response core, and the official SDKs support it. Anthropic said support is rolling out across Claude products, so some Claude surfaces may still speak the older version. Better Auth's example sets `legacy: "reject"`; we deliberately do not.

## D5. Separate MCP service

**Decision.** `apps/mcp` is its own Node service on `mcp.upskillzz.com`, not a route inside Next.js.

**Why.** Claude's docs allow the authorization server on a different host from the MCP server. A separate service isolates MCP latency and failures from the storefront, scales on its own, and gives one agent clean ownership. It costs one extra small machine (about $2 to $4 a month).

## D6. One tool per owned skill, plus two fixed tools

**Decision (Borna's choice).** Each skill a user owns appears as its own MCP tool whose description says when to use it. Two tools are always present: `upskillzz_library` (what do I own) and `upskillzz_load_skill` (load any owned skill by slug).

**Why the fixed tools.** People have reported that Claude's desktop and mobile apps cache a connector's tool list from when it was added, until the user chooses "Refresh tools list"; claude.ai on the web and Claude Code fetch a fresh list per conversation. Without a fallback, a skill bought after connecting might not show up in those apps. `upskillzz_load_skill` makes new purchases usable immediately everywhere.

**Cost.** Each tool adds to Claude's context. Fine for tens of skills per user; revisit if someone owns hundreds.

## D7. Content as folders in the repo

**Decision (Borna's choice).** Each skill is `content/skills/<slug>/` with `skill.yaml` (store metadata), `SKILL.md` (paid instructions, standard Agent Skills frontmatter), `preview.md` (public), optional `references/` and `actions/`. Packs are YAML files. Merging to `main` syncs everything to the database and Stripe.

**Why.** Version history, review through pull requests, no admin UI to build. Using the standard SKILL.md frontmatter means a skill can be tested locally in Claude Code before it is sold.

**Cost.** The repository must stay private. An admin UI can come later.

## D8. Script logic runs on the server

**Decision (Borna's choice).** Skills ship text and reference files only. Anything that needs code becomes a server-side action: a TypeScript function in the skill folder, exposed as an extra MCP tool and run inside `apps/mcp`.

**Why.** Code sent to the buyer could be copied; code that runs on our server can't. Actions are written by Borna only, so they run in-process with a timeout rather than in a sandbox.

## D9. Payments: Stripe Checkout, one-time, Stripe Tax

**Decision (Borna's choice: Stripe directly, one-time purchases).** Stripe Checkout in payment mode. Prices in EUR, VAT-inclusive. Stripe Tax calculates VAT with automatic tax in Checkout. Promotion codes allowed.

**What this means.** Without a merchant of record, Upskillzz is the seller: it registers for VAT where required (for EU consumers, typically the OSS scheme) and files returns itself, using Stripe Tax's reports. Stripe Tax's no-code pricing is 0.5% per transaction in jurisdictions where you are registered. EU consumers buying digital content normally have a 14-day withdrawal right unless they expressly consent to immediate delivery and acknowledge losing it, so checkout collects that consent. Confirm all of this with an accountant; see `docs/LAUNCH_CHECKLIST.md`.

**Packs.** A pack grants every skill in it. In v1 a pack costs its full price even if the buyer already owns some of its skills; the UI warns them.

## D10. Watermarking later

**Decision (Borna's choice).** No per-buyer watermarking in v1. All delivered text passes through one `applyWatermark` function that does nothing for now, so it can be added without touching the tools.

## D11. Google-only sign-in, dev login for local work

**Decision (Borna's choice: Google only).** Buyers sign in with Google. For local development and tests only, a "Continue as test user" login exists when `DEV_LOGIN_ENABLED=true`; the app refuses to start with it enabled in production.

## D12. Parallel agents: worktrees, ownership, contracts

**Decision.** One worktree and branch per workstream. Every path has exactly one owning workstream. Shared shapes live in `docs/contracts/` and change only through the orchestrator. Only the orchestrator generates migrations and resolves lockfile conflicts. Each agent reports in its own status file; the orchestrator keeps `docs/agents/BOARD.md`.

**Why.** Path ownership prevents merge conflicts; contracts let agents build against each other before the other side exists; single-writer migrations avoid colliding migration numbers.

## D13. English only, clean neutral design, written tutorial

**Decision (Borna's choice).** English UI. Brand name Upskillzz. Neutral palette with one accent colour. The tutorial is written pages with screenshot slots and a placeholder for a video on each page.

---

## Sources

- Vercel fair use guidelines (Hobby is non-commercial): https://vercel.com/docs/limits/fair-use-guidelines
- Vercel Hobby plan: https://vercel.com/docs/plans/hobby
- Railway Hobby and commercial use (forum answer): https://station.railway.com/questions/terms-of-service-only-non-commercial-us-8302c41c
- Hetzner cheap cloud tier unavailable after 2026 price rises: https://www.vincentschmalbach.com/hetzner-cheap-cloud-unavailable-price-increases/
- Fly.io pricing: https://fly.io/pricing.md
- Neon scale-to-zero and cold starts: https://neon.com/faqs/postgres-hosting-options-auto-pause-database
- Claude connector authentication requirements: https://claude.com/docs/connectors/building/authentication.md
- Building custom connectors via remote MCP (plans, transports, callback URL): https://support.claude.com/en/articles/11503834-building-custom-connectors-via-remote-mcp-servers
- Tool list caching in desktop and mobile apps (bug report): https://github.com/anthropics/claude-code/issues/38324
- "Refresh tools list" option (third-party help article): https://help.usewheelhouse.com/en/articles/15908885-refreshing-your-claude-connector-to-get-new-tools
- Better Auth MCP plugin: https://better-auth.com/docs/plugins/mcp
- MCP 2026-07-28 rollout in Claude: https://claude.com/blog/bringing-mcp-2026-07-28-to-claude
- Example of a one-click "add connector" link and the Claude Code command: https://www.recraft.ai/docs/mcp-reference/remote-server.md
- Stripe Tax pricing: https://support.stripe.com/questions/understanding-stripe-tax-pricing

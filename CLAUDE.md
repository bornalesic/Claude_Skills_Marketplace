# CLAUDE.md — Upskillzz

Upskillzz sells Claude skills. The website (`apps/web`) handles Google sign-in, Stripe checkout, the buyer's library and a beginner tutorial, and it is the OAuth authorization server Claude signs in through. The MCP server (`apps/mcp`) is what Claude connects to: it exposes one tool per skill the signed-in user owns and returns the skill's instructions when called. Skills are written as folders in `content/`.

Several Claude Code agents work on this repo at the same time, each in its own git worktree and branch. Read this whole file, then follow the reading order.

## Reading order

1. This file.
2. Your brief: `docs/agents/<workstream>.md`. The prompt that started you names your workstream. If none was named and you are in the main checkout, you are the orchestrator: read `docs/agents/orchestrator.md`.
3. `docs/WORKSTREAMS.md`: who owns which paths.
4. The contracts your brief lists, in `docs/contracts/`.
5. The `CLAUDE.md` inside each package or app you touch.
6. The latest status board: `git show main:docs/agents/BOARD.md` (your worktree copy may be stale).

## Rules

1. **Edit only paths your workstream owns** (see `docs/WORKSTREAMS.md`). If you need a change elsewhere, write it under "Requests" in your status file and work against a local stub meanwhile. Exception: you may add dependencies to the `package.json` of a package you work in.
2. **Contracts are the source of truth** for anything shared: database tables, package APIs, MCP tools, content format, env vars, HTTP routes. Code to them exactly. Don't edit them. Propose changes under "Contract change requests" in your status file and keep building against the current version.
3. **Never generate database migrations.** Edit the schema files you own and run `pnpm db:push` against your own local database. The orchestrator generates migrations on main.
4. **Keep paid content private.** See the security invariants below. A leak is a release blocker.
5. **No secrets in git.** A new env var needs an entry in `docs/contracts/env.md` (request it) and in `.env.example`. Validate env with Zod at startup and fail fast.
6. **Check current docs before building on external services.** Better Auth, the MCP SDK and spec, Stripe, Next.js and Claude's connector behaviour all change quickly. Read the docs your brief links instead of relying on memory, and record what you verified (with links) in your status file.
7. **Tests ship with the feature.** A task is done only when the Definition of done below holds.
8. **Git hygiene.** Commit small and often on your branch with Conventional Commits (`feat(mcp): ...`, `fix(web): ...`). Never commit to `main`, never touch other branches. When the board says main moved, run `git rebase main` in your worktree (worktrees share one repository, no fetch needed), then compare `.env.example` with your `.env.local` and add any new keys.
9. **Report.** Update `docs/agents/status/<workstream>.md` (create it from `_TEMPLATE.md`) whenever you finish a milestone, get blocked, or stop. It is the only way others know what you did.
10. **Decide small things yourself.** When product behaviour is unclear, pick the simplest option consistent with the contracts, write the assumption in your status file and keep going. Stop and ask only before anything that can't be undone or crosses ownership: deleting data, changing a contract, editing another workstream's files.

## Security invariants (never break these)

- Paid text (SKILL.md bodies, reference files, action code and results) is served only by `apps/mcp`, only to a request with a valid token whose user owns that skill.
- The public catalog and the website's build output contain only the public fields listed in `docs/contracts/content-format.md`. A test enforces this.
- Checkout prices come from the database, never from the client.
- Entitlements are granted only from a verified Stripe webhook, or by the free-claim route for €0 skills. Webhook handling is idempotent.
- Published skills are never deleted. They are archived, and existing owners keep access.
- The dev-only test login cannot be enabled in production (the app refuses to start).
- `apps/mcp` verifies every access token locally against the JWKS: signature, issuer, audience equal to the MCP URL, expiry, and the `skills` scope.
- Never log access tokens, refresh tokens, full email addresses or paid content.

## Stack and conventions

- TypeScript strict, ESM everywhere, Node 24 LTS, pnpm workspaces, Turborepo.
- Zod at every boundary: env, HTTP input, content files, MCP tool input.
- Named exports. Default exports only where a framework requires them (Next.js pages, layouts, configs).
- File names in kebab-case. React components exported in PascalCase.
- Biome for lint and format. Vitest for unit and integration tests, Playwright for end-to-end.
- Logging with pino (JSON) in server code.
- Money as integer cents plus a lowercase ISO currency (`eur`). Prices shown to buyers include VAT.
- Timestamps as `timestamptz`, stored in UTC.
- App table IDs: `uuid` with `gen_random_uuid()` default. User IDs are Better Auth's string IDs (`text`).

## Local environment

Each worktree gets its own `.env.local` (created by `scripts/setup-worktrees.sh`) with its own ports and database, so agents can run dev servers at the same time.

| Workstream | Web port | MCP port | Local database |
|---|---|---|---|
| main (orchestrator) | 3000 | 3001 | `upskillzz` |
| w0-foundation | 3010 | 3011 | `upskillzz_w0` |
| w1-auth | 3020 | 3021 | `upskillzz_w1` |
| w2-mcp | 3030 | 3031 | `upskillzz_w2` |
| w3-content | 3040 | 3041 | `upskillzz_w3` |
| w4-payments | 3050 | 3051 | `upskillzz_w4` |
| w5-web | 3060 | 3061 | `upskillzz_w5` |
| w6-tutorial | 3070 | 3071 | `upskillzz_w6` |
| w7-infra | 3080 | 3081 | `upskillzz_w7` |
| w8-qa | 3090 | 3091 | `upskillzz_w8` |

All databases live in one local Postgres container (`pnpm db:up`). With `DEV_LOGIN_ENABLED=true` the sign-in page offers "Continue as test user", so you don't need Google credentials locally. Details: `docs/LOCAL_DEV.md`.

## Commands

`pnpm install`, `pnpm db:up`, `pnpm db:push`, `pnpm dev`, `pnpm build`, `pnpm test`, `pnpm typecheck`, `pnpm lint`, `pnpm format`, `pnpm content:validate`, `pnpm content:build`, `pnpm content:sync -- --dry-run`, `pnpm e2e`. Run a single package with `pnpm --filter @upskillzz/<name> <script>`. `pnpm db:generate` is for the orchestrator only.

## Definition of done

- `pnpm typecheck && pnpm lint && pnpm test` pass from the repo root.
- New behaviour has tests, and the code matches the contracts exactly.
- No files outside your owned paths changed: check `git diff --stat main...HEAD`.
- Your status file says what is done, how to try it, what is left, and any requests.

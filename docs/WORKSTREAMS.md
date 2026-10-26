# Workstreams

Every path in the repo has exactly one owner. An agent edits only what its workstream owns. Anything else goes through a request in its status file.

## Overview

| ID | Name | Branch | Phase | Depends on | Brief |
|---|---|---|---|---|---|
| — | Orchestrator | `main` | all | — | [orchestrator.md](agents/orchestrator.md) |
| W0 | Foundation | `ws/w0-foundation` | 0 | — | [w0-foundation.md](agents/w0-foundation.md) |
| W1 | Auth and OAuth | `ws/w1-auth` | 1 | W0 | [w1-auth.md](agents/w1-auth.md) |
| W2 | MCP server | `ws/w2-mcp` | 1 | W0 (uses stubs for W1, W3, W4) | [w2-mcp.md](agents/w2-mcp.md) |
| W3 | Content pipeline | `ws/w3-content` | 1 | W0 (stubs W4's Stripe sync) | [w3-content.md](agents/w3-content.md) |
| W4 | Payments and entitlements | `ws/w4-payments` | 1 | W0 | [w4-payments.md](agents/w4-payments.md) |
| W5 | Website storefront | `ws/w5-web` | 1 | W0 (uses stubs for W1, W3, W4) | [w5-web.md](agents/w5-web.md) |
| W6 | Tutorial and legal pages | `ws/w6-tutorial` | 2 (can start after W0) | W0, W5's design tokens | [w6-tutorial.md](agents/w6-tutorial.md) |
| W7 | Infrastructure and deploy | `ws/w7-infra` | 2 (can start after W0) | W0 | [w7-infra.md](agents/w7-infra.md) |
| W8 | QA and end-to-end tests | `ws/w8-qa` | 2 | W1 to W5 merged | [w8-qa.md](agents/w8-qa.md) |

## Phases

- **Phase 0, one terminal:** W0 turns the empty repo into a building monorepo with shared types, schema and app skeletons. Nothing else starts until the orchestrator merges W0.
- **Phase 1, five terminals plus orchestrator:** W1, W2, W3, W4, W5 in parallel. Each builds against contracts and stubs, so none waits for another.
- **Phase 2:** W6 and W7 (they may start as soon as W0 is merged if you have terminals free), then W8 once Phase 1 is merged.
- **Phase 3, integration and launch:** orchestrator plus Borna. Staging deploy, real Claude connections, launch checklist.

Suggested merge order in Phase 1, so dependents can drop their stubs early: W3 → W1 → W4 → W2 → W5. Merge whatever is ready; the order is a preference.

## Path ownership

More specific paths win. "Request" means: write it under "Requests" in your status file; the owner or the orchestrator does it.

| Path | Owner | Notes |
|---|---|---|
| `docs/**` (except below), `README.md`, `CLAUDE.md` | Orchestrator | |
| `docs/contracts/**` | Orchestrator | Change requests only |
| `docs/agents/BOARD.md` | Orchestrator | Agents read it with `git show main:docs/agents/BOARD.md` |
| `docs/agents/status/<id>.md` | That workstream | Created from `_TEMPLATE.md` |
| `docs/RUNBOOK.md` | W7 | New file |
| `docs/TESTING.md` | W8 | New file |
| Root configs: `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `tsconfig*.json`, `biome.json`, `.gitignore`, `.nvmrc`, `.env.example` | W0, then orchestrator | After W0 merges, request changes |
| `pnpm-lock.yaml` | Shared | Conflicts resolved by the orchestrator |
| `scripts/**` | W0, then orchestrator | `setup-worktrees.sh` already exists |
| `.github/workflows/ci.yml` | W0, then orchestrator | |
| `.github/workflows/deploy*.yml` | W7 | |
| `packages/shared/**` | W0, then orchestrator | Request changes |
| `packages/db/src/schema/auth.ts` | W1 | W0 generates the first version |
| `packages/db/**` (rest) | W0, then orchestrator | Agents may propose schema edits as requests; orchestrator applies them and generates migrations |
| `packages/db/migrations/**` | Orchestrator | Never generated on a branch |
| `packages/auth/**` | W1 | |
| `packages/content/**` | W3 | |
| `content/**` | Borna; W3 for format, templates and `_samples/` | Agents never edit Borna's real skills |
| `content/package.json` | W0 | |
| `packages/entitlements/**` | W4 | |
| `packages/payments/**` | W4 | |
| `apps/mcp/**` | W2 | W0 creates the skeleton |
| `apps/web/package.json`, `next.config.*`, `tsconfig.json` | W0, then W5 | Anyone may add dependencies |
| `apps/web/src/app/api/auth/**` | W1 | |
| `apps/web/src/app/(auth)/**` | W1 | Sign-in and consent pages |
| `apps/web/src/app/.well-known/**` | W1 | OAuth discovery routes |
| `apps/web/src/lib/auth-client.ts`, `apps/web/src/lib/session.ts` | W1 | |
| `apps/web/src/proxy.ts` or `src/middleware.ts` | W1 | Whichever name the installed Next.js version uses |
| `apps/web/src/app/api/checkout/**`, `api/claim/**`, `api/orders/**`, `api/buy-state/**`, `api/stripe/**` | W4 | |
| `apps/web/src/server/commerce/**` | W4 | Server helpers pages call |
| `apps/web/src/app/tutorial/**`, `apps/web/src/content/tutorial/**`, `apps/web/src/components/tutorial/**`, `apps/web/public/tutorial/**` | W6 | |
| `apps/web/src/app/legal/**`, `apps/web/src/content/legal/**` | W6 | |
| `apps/web/**` (everything else) | W5 | Includes design tokens in `src/app/globals.css` |
| `infra/docker-compose.dev.yml`, `infra/postgres-init/**` | W0 | |
| `infra/**` (rest) | W7 | |
| `e2e/**` | W8 | |

If a path isn't listed and isn't under an owned folder, ask the orchestrator before creating it.

## Ports and databases

See the table in the root `CLAUDE.md`. `scripts/setup-worktrees.sh` writes these into each worktree's `.env.local`.

## Worktree layout

```
parent-folder/
  upskillzz/                  main checkout: orchestrator
  upskillzz-wt/
    w0-foundation/            branch ws/w0-foundation
    w1-auth/                  branch ws/w1-auth
    ...
    w8-qa/                    branch ws/w8-qa
```

The orchestrator reads an agent's live status file at `../upskillzz-wt/<id>/docs/agents/status/<id>.md`.

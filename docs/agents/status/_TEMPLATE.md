# Status: <ID> <name>

Copy this file to `docs/agents/status/<id>.md` and keep it current. Newest information first within each section. Keep it short: the orchestrator reads every status file.

**State:** in progress | blocked | ready for review | done
**Branch:** ws/<id>
**Last updated:** YYYY-MM-DD HH:MM

## Done

- Short bullet per milestone, with the commit hash.

## How to try it

Exact commands someone else can run to see it working, for example:

```bash
pnpm --filter @upskillzz/mcp test
pnpm dev   # then open http://localhost:30x0/...
```

## In progress / next

- What you are doing now, and what comes after.

## Stubs and mocks in use

| Stub | Replaces | Remove when |
|---|---|---|
| e.g. local `createTokenVerifier` in `apps/mcp/src/auth/verify-stub.ts` | `@upskillzz/auth/verify` | W1 merged |

## Assumptions made

- Product or technical choices you made because the docs didn't say. One line each, with why.

## Verified against current docs

- What you checked, with the link and date, e.g. "Better Auth MCP plugin: `requireMcpAuth` options (https://better-auth.com/docs/plugins/mcp, 2026-10-27)".

## Requests

Changes you need in paths you don't own.

| To | Path | What and why |
|---|---|---|

## Contract change requests

| Contract | Proposed change | Why | Breaking? |
|---|---|---|---|

## Blockers

- Anything stopping you, and what would unblock it.

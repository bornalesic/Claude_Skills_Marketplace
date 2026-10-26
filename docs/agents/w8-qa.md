# Brief: W8 QA and end-to-end tests

**Branch:** `ws/w8-qa` · **Phase:** 2 (after W1 to W5 are merged) · **Ports:** 3090 / 3091 · **DB:** `upskillzz_w8`

## Mission

Prove the whole thing works together, and keep it working: end-to-end tests for the buyer journey and the Claude connection, a content-leak scan of real build output, and a manual test script for the Claude apps that can't be automated.

## Read first

All contracts, `docs/ARCHITECTURE.md`, the security invariants in `CLAUDE.md`, `docs/LAUNCH_CHECKLIST.md`, and every merged workstream's status file ("How to try it").

## You own

`e2e/**`, `docs/TESTING.md` (new).

## Deliverables

1. **Playwright suite** in `e2e/` against a locally running stack (web, MCP, Postgres, samples synced, `stripe listen` forwarding):
   - Browse: home → catalog filter → skill page shows price and preview.
   - Dev login → claim the free sample → it appears in the library.
   - Buy the paid sample with card 4242 through Stripe Checkout (test mode) → success page turns to "It's yours" → library shows it.
   - Buy the pack → both skills owned; the pack page shows "owned".
   - Waiver unticked → can't proceed.
   - Signed-out visit to `/library` → redirected to sign-in, then back.
2. **MCP end-to-end** (Vitest or Playwright request context, using the MCP SDK client):
   - Full OAuth through the real authorization server (dev login, scripted consent), CIMD path and DCR path.
   - After the purchases above: `tools/list` shows exactly the owned skills and their actions; calling them returns content; another test user sees none of it.
   - Refund the order through Stripe's test API → after the cache TTL, the tool disappears and `upskillzz_load_skill` refuses.
3. **Content-leak scan** of the production build: run `next build`, then W3's leak checker over `.next/` output and the catalog JSON. Wire it into CI.
4. **CI integration:** an `e2e` job (or nightly workflow) that runs the suite with Postgres and stripe-mock or Stripe test mode; request the CI changes from the orchestrator if they touch `ci.yml`.
5. **Manual test script** in `docs/TESTING.md`: step-by-step checks for claude.ai web, Claude Desktop, Claude mobile and Claude Code against staging (connect, sign in, tool list, call a skill, buy a new skill while connected, refresh behaviour, disconnect and reconnect), with a results table to fill in per release.
6. **Bug reports:** anything you find goes to the owning workstream through your status file "Requests" table, with steps to reproduce. Don't fix other workstreams' code.

## Acceptance checks

- `pnpm e2e` passes locally from a clean database with one command plus `stripe listen`.
- The leak scan runs in CI and fails on a planted canary.
- `docs/TESTING.md` explains how to run everything and contains the manual script.

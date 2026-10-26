# Status board

Owned by the orchestrator. Agents read the current version with `git show main:docs/agents/BOARD.md`.

Last updated: 2026-10-26 (skeleton)

## Current phase

**Phase 0: foundation.** Only W0 is running. Everyone else waits for W0 to merge.

## Workstreams

| ID | State | Last merged to main | Notes |
|---|---|---|---|
| W0 foundation | not started | — | |
| W1 auth | waiting for W0 | — | |
| W2 MCP | waiting for W0 | — | |
| W3 content | waiting for W0 | — | |
| W4 payments | waiting for W0 | — | |
| W5 web | waiting for W0 | — | |
| W6 tutorial | waiting for W0 | — | Phase 2, may start early |
| W7 infra | waiting for W0 | — | Phase 2, may start early |
| W8 QA | waiting for W1 to W5 | — | |

States: not started, in progress, blocked, ready for review, merged, done.

## Main moved (rebase now)

Agents listed here should run `git rebase main` and check `.env.example` for new variables.

- (none yet)

## Contract changes

| Date | Contract | Version | Change | Affects |
|---|---|---|---|---|
| 2026-10-26 | all | 1.0 | Initial versions | everyone |

## Open requests

Requests from status files that need the orchestrator or another workstream.

| From | To | Request | Status |
|---|---|---|---|
| — | — | — | — |

## Decisions needed from Borna

- [ ] Buy the domain (placeholder: upskillzz.com) or choose another; update `APP_URL` and `MCP_URL` for staging and production.
- [ ] Create the Google OAuth client and Stripe test account (needed by Phase 3, not before).
- [ ] Pick 3 launch skills and start writing them in `content/skills/` (see `content/README.md`).

## Merge log

| Date | Branch | Commit | Notes |
|---|---|---|---|
| — | — | — | — |

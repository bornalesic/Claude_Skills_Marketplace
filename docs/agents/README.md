# Running the agents

You run one Claude Code session per terminal. Each session works in its own git worktree on its own branch, so they never edit the same checkout. One extra session in the main folder acts as the orchestrator: it reviews and merges branches, keeps the board, and owns the contracts.

## One-time setup

```bash
cd upskillzz
git init -b main
git add -A && git commit -m "chore: planning skeleton"
chmod +x scripts/setup-worktrees.sh
scripts/setup-worktrees.sh main        # creates .env.local for the main checkout
scripts/setup-worktrees.sh             # creates ../upskillzz-wt/<id> for every workstream
```

The script is safe to re-run. It creates branch `ws/<id>` from `main`, a worktree at `../upskillzz-wt/<id>`, and a `.env.local` with that workstream's ports, database name and a random auth secret. It never overwrites an existing `.env.local`.

Worktrees created before W0 merges start from the skeleton. After W0 merges, each agent's first step is `git rebase main` (the prompts below include it).

## Phase 0: foundation (1 terminal + orchestrator)

Terminal A:

```bash
cd ../upskillzz-wt/w0-foundation && claude
```

Prompt:

```
You are workstream W0 (foundation) on branch ws/w0-foundation. Read CLAUDE.md, then docs/agents/w0-foundation.md, then the contracts it lists. Create docs/agents/status/w0-foundation.md from the template and keep it updated. Work until the brief's acceptance checks pass, then report in the status file and stop.
```

Orchestrator terminal (in `upskillzz/`):

```bash
claude
```

Prompt:

```
You are the orchestrator on main. Read CLAUDE.md and docs/agents/orchestrator.md. W0 is running in ../upskillzz-wt/w0-foundation. When its status says ready, review and merge it following your brief, update docs/agents/BOARD.md, and tell me when Phase 1 can start.
```

## Phase 1: core build (5 terminals + orchestrator)

For each workstream, open a terminal:

```bash
cd ../upskillzz-wt/<id> && claude
```

and paste (replace `<ID>`, `<id>` and `<name>`):

```
You are workstream <ID> (<name>) on branch ws/<id>. First run `git rebase main`. Read CLAUDE.md, then docs/agents/<id>.md, then every contract it lists and the CLAUDE.md of each package you own. Read the latest board with `git show main:docs/agents/BOARD.md`. Create docs/agents/status/<id>.md from the template. Build against contracts and stubs; don't wait for other workstreams. Commit often. Update your status file at each milestone, and stop when the brief's acceptance checks pass.
```

| Terminal | ID | id | name |
|---|---|---|---|
| B | W1 | w1-auth | auth and OAuth |
| C | W2 | w2-mcp | MCP server |
| D | W3 | w3-content | content pipeline |
| E | W4 | w4-payments | payments and entitlements |
| F | W5 | w5-web | website storefront |

Give the orchestrator a nudge whenever an agent reports ready:

```
Check the status files of all workstreams, merge whatever is ready following your brief, update the board, and list what each agent should do next.
```

When the board says main moved, tell the affected agents:

```
main moved. Run `git rebase main`, fix anything that broke, remove stubs that the merged work replaces, and continue.
```

## Phase 2: tutorial, infrastructure, QA

Same pattern with W6 (`w6-tutorial`), W7 (`w7-infra`) and W8 (`w8-qa`). W6 and W7 can start any time after W0 is merged if you have terminals free. W8 starts once W1 to W5 are merged.

## Phase 3: integration and launch

Work with the orchestrator on staging: real Google sign-in, Stripe test payments, connecting real Claude apps, then `docs/LAUNCH_CHECKLIST.md`.

## Tips

- Five agents plus an orchestrator is a lot to watch. If it feels like too much, run W1 to W3 first, then W4 and W5.
- If an agent asks you something, answer in its terminal. If the answer affects others (a contract, a product rule), also tell the orchestrator so it updates the docs.
- If two agents need the same file, the ownership table in `docs/WORKSTREAMS.md` decides. Ask the orchestrator to move ownership rather than letting both edit.
- Agents can lose context in long sessions. Their status file is their memory: tell a fresh session "Read your status file and continue".

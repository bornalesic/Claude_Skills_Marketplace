# Writing skills for Upskillzz

Each skill you sell is a folder in `content/skills/`. Each pack is a YAML file in `content/packs/`. When you merge to `main`, the pipeline validates everything, updates the database and Stripe, and redeploys the store.

> This is a starter guide. W3 expands it with screenshots of the validator output and a full walkthrough once the tooling exists.

## Create a skill

1. Copy the template: `cp -r content/skills/_template content/skills/my-skill-name`. The folder name is the skill's permanent ID (lowercase, words joined with hyphens).
2. Edit the four files:

| File | Who sees it | What to write |
|---|---|---|
| `skill.yaml` | Store (public) | Title, price, summary, category, outcomes, which Claude apps it works with |
| `SKILL.md` | Paying owners' Claude only | The frontmatter `name` (same as the folder) and `description` (when Claude should use it), then the instructions |
| `preview.md` | Everyone | What it does, who it's for, an example request and a shortened example result |
| `references/*.md` | Paying owners' Claude only | Optional extra material Claude loads when the instructions say so |

3. Validate: `pnpm content:validate`. Fix whatever it lists.
4. Preview the store page: `pnpm content:build && pnpm dev`, then open `http://localhost:<WEB_PORT>/skills/my-skill-name`.
5. Publish: set `status: published`, open a pull request, merge.

## Test it in Claude Code before selling

`SKILL.md` uses the standard skills format, so Claude Code can load the folder directly:

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)/content/skills/my-skill-name" ~/.claude/skills/my-skill-name
```

Start Claude Code, ask for something the skill should handle, and check that Claude picks it up and follows it. Remove the link when done.

## Write a good `description`

It is the only thing Claude sees before deciding to use the skill. Say when to use it and when not to:

> Use when the user wants to write or improve a B2B cold email or follow-up sequence. Do not use for newsletters or replies to existing threads.

## Change a published skill

- Edit the instructions or references, then **bump `version`** (`1.0.0` → `1.1.0`). Sync refuses changed content without a version bump. Owners get the update automatically.
- Change the price freely. New buyers pay the new price.
- Never rename the folder or `tool_name` after publishing. To replace a skill, archive it and create a new one.
- To stop selling: `status: archived` (or delete the folder). Owners keep access.

## What makes a skill sell

- One narrow job, done better than Claude does it alone.
- Outcomes a buyer can picture ("a first email plus two follow-ups").
- A preview with a real example result.
- Built on expertise people can't get from a generic prompt.

Full format rules: `docs/contracts/content-format.md`.

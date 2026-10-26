# @upskillzz/content

Turns the `content/` folder into what the rest of Upskillzz needs.

| Command | What it does |
|---|---|
| `pnpm content:validate` | Checks every skill and pack, lists all problems with file and field |
| `pnpm content:build` | Writes the public catalog (`generated/catalog.json`) and the action registry (`generated/actions.ts`) |
| `pnpm content:sync -- --dry-run` | Shows what would change in the database (and Stripe with `--stripe`) |
| `pnpm content:sync` | Applies it: creates, updates, archives |

How to write a skill: `content/README.md`. Format: `docs/contracts/content-format.md`.

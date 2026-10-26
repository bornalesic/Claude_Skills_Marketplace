# packages/content — CLAUDE.md

Owner: **W3**. Spec: `docs/contracts/content-format.md`, the `@upskillzz/content` section of `docs/contracts/interfaces.md`, and the catalog tables in `docs/contracts/database.md`.

Reads `content/`, validates it, and produces: the public catalog JSON (for the website), database rows (for the MCP server), and the action registry (for the MCP server). Also the `content` CLI.

## Entry points

| Import | Used by | Contains paid text? |
|---|---|---|
| `@upskillzz/content` | CLI, tests, deploy pipeline | yes (loader output) |
| `@upskillzz/content/catalog` | `apps/web` | **no**, public fields only |
| `@upskillzz/content/actions` | `apps/mcp` | yes (action code) |

`/catalog` must never import the loader or anything that reads SKILL.md, references or action files. A test checks the import graph or the bundle.

## Structure

```
src/
  index.ts
  load/          read folders, parse YAML and frontmatter, collect issues
  validate/      cross-file rules
  hash.ts        contentHash
  catalog/       buildPublicCatalog, getPublicCatalog (reads generated/catalog.json)
  actions/       registry generation, Zod → JSON Schema
  sync/          syncContentToDb, plan printing
  leak-guard.ts  checker exported for W8 and CI
  cli.ts         content validate | build | sync
generated/       catalog.json, actions.ts (gitignored, written by `content build`)
test/
  fixtures/      valid and deliberately broken content trees
```

## Rules

- Collect every validation issue, then throw once. Messages name the file and field in plain English.
- Sync runs in one transaction, is idempotent, archives instead of deleting, and enforces immutable slugs and tool names plus the version-bump rule.
- Only `syncContentToDb` writes catalog tables (except the Stripe ID columns, which `syncCatalogToStripe` in `@upskillzz/payments` writes).
- `--dry-run` writes nothing, anywhere.
- Never edit Borna's real skills in `content/skills/`. Your files there are `_template/`, `_samples/` and the docs.

## Testing

`pnpm --filter @upskillzz/content test`: one test per validation rule, hash stability, catalog has only public fields, leak guard (with a leaky fixture that must fail), sync create / update / archive / immutability / version bump / idempotency, action registry and JSON Schema output.

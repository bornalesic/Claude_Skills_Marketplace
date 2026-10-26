# packages/shared — CLAUDE.md

Owner: **W0**, then the **orchestrator**. Spec: the `@upskillzz/shared` section of `docs/contracts/interfaces.md`, and `docs/contracts/content-format.md` for the content schemas.

Types, Zod schemas, constants and tiny helpers used by more than one package. It is the bottom of the dependency graph.

## Structure

```
src/
  index.ts
  constants.ts        regexes, CATEGORIES, WORKS_WITH, MCP_SCOPE, RESERVED_TOOL_PREFIX
  content-schemas.ts  SkillYamlSchema, SkillFrontmatterSchema, PackYamlSchema
  catalog.ts          PublicSkill, PublicPack, PublicCatalog (+ schema)
  actions.ts          defineAction, ActionDefinition, ActionContext
  env.ts              parseEnv
  money.ts            formatPrice
  errors.ts           AppError
  claude-links.ts     claudeAddConnectorUrl, claudeCodeAddCommand
test/
```

## Rules

- Runtime dependency on `zod` only. Never import another workspace package.
- Everything exported here is a contract. After W0 merges, changes go through a contract change request, even small ones.
- Content schemas enforce every rule in `content-format.md` that can be checked on a single file (patterns, lengths, enums, price rules). Cross-file rules (references exist, pack members exist) belong in `packages/content`.
- Error messages from schemas are shown to Borna when he writes content: make them readable.
- `parseEnv` reports all problems at once, never secret values.

## Testing

One test per schema rule with valid and invalid examples; `formatPrice` cases; `claudeAddConnectorUrl` encoding. `pnpm --filter @upskillzz/shared test`.

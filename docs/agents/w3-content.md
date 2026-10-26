# Brief: W3 content pipeline

**Branch:** `ws/w3-content` · **Phase:** 1 · **Ports:** 3040 / 3041 · **DB:** `upskillzz_w3`

## Mission

Make `content/` the one place Borna writes skills, and turn it into three things: a validated public catalog the website builds from, database rows the MCP server reads, and a registry of server-side actions. Make authoring pleasant: clear errors, a template, samples, and a guide a non-developer can follow.

## Read first

- `docs/contracts/content-format.md` (your main spec), `interfaces.md` (`@upskillzz/content`, `@upskillzz/shared`, `syncCatalogToStripe`), `database.md` (catalog tables), `env.md`
- `docs/ARCHITECTURE.md` flow 4, `docs/DECISIONS.md` D7 and D8
- `packages/content/CLAUDE.md`, `content/CLAUDE.md`

## You own

`packages/content/**`; in `content/`: `README.md`, `CLAUDE.md`, `skills/_template/**`, `skills/_samples/**`, `packs/_template.yaml`, `packs/_samples/**`. Never edit Borna's real skills.

## Verify before building

- Agent Skills SKILL.md format (frontmatter fields and limits): https://docs.claude.com (search "Agent Skills")
- Drizzle upserts (`onConflictDoUpdate`) and transactions
- `zod-to-json-schema` or Zod's built-in JSON Schema output (whichever the installed Zod version supports)
- How Claude Code loads personal skills from `~/.claude/skills/`, for the authoring guide

## Stubs until others merge

`syncCatalogToStripe` (W4): call it through the `@upskillzz/payments` import; until W4 merges, W0's stub throws "not implemented", so `--stripe` prints a clear message and skips. Your DB sync must not depend on Stripe.

## Deliverables

1. **Loader and validator** (`loadContent`): reads `CONTENT_DIR`, applies every rule in `content-format.md` using the Zod schemas from `@upskillzz/shared`, parses SKILL.md frontmatter, checks referenced files exist, checks size limits, checks pack membership, computes `contentHash` (sha256 over instructions, references in name order, and action source files). Collects **all** issues and throws one `ContentValidationError`. Error messages name the file and field in plain English ("content/skills/cold-email-writer/skill.yaml: price_eur must be 0 or at least 0.50").
2. **Public catalog** (`buildPublicCatalog`): published skills and packs only, public fields only, sorted by title; `separatePriceCents` for packs. `content build` writes it to `packages/content/generated/catalog.json`. `@upskillzz/content/catalog` reads that file (`getPublicCatalog`, `getPublicSkill`, `getPublicPack`) and throws a helpful error if it hasn't been built.
3. **Leak guard test**: builds the catalog from samples and fails if any line longer than 30 characters from any SKILL.md body, SKILL.md description, reference file or action file appears in the catalog JSON. Export the checker as a function so W8 can run it over the website build output too.
4. **Action registry**: `content build` also generates `packages/content/generated/actions.ts` that statically imports every `actions/*.ts` from included skills and exports `actionRegistry`. Each action's Zod input becomes JSON Schema for `skill_action.input_schema`. `@upskillzz/content/actions` exports it.
5. **DB sync** (`syncContentToDb`), in one transaction: upsert skills, references, actions, packs, pack items by slug; archive what disappeared; enforce immutable slug and tool name after publish; enforce the version-bump rule; set `published_at` once. `--dry-run` prints the plan as a readable table and writes nothing. Running it twice in a row changes nothing the second time.
6. **CLI** (`content validate | build | sync [--dry-run] [--stripe]`) wired to the root scripts, with exit code 1 on any error.
7. **Template** in `content/skills/_template/` and `content/packs/_template.yaml`: every field with a comment explaining it.
8. **Samples** in `_samples/`: three skills and one pack that exercise everything:
   - a paid skill with two references (for example "Meeting Notes to Action Items", €9),
   - a paid skill with one action (for example "Cold Email Writer" with a `score` action, €19),
   - a free skill (for example "Prompt Polisher", €0),
   - a pack containing the two paid skills (€24).
   Write them as real, useful skills (they are also demo content), with honest previews.
9. **Authoring guide** in `content/README.md`, written for Borna: create a skill from the template, write a good `description` (when to use and when not to), test it locally in Claude Code by linking the folder into `~/.claude/skills/<slug>`, validate, preview the store page locally, set the price, publish through a pull request, update (bump version), archive. Include a short "what makes a skill sell" checklist (narrow job, concrete outcomes, a preview that shows a real result).

## Tests

Validation (one test per rule, valid and invalid), frontmatter parsing, hash stability, catalog contains only public fields, leak guard (including a deliberately leaky fixture that must fail), sync create / update / archive / immutable-identifier error / version-bump error / idempotency, action registry generation and JSON Schema output.

## Acceptance checks

- `pnpm content:validate` passes on the samples and fails with clear messages on a broken fixture.
- `pnpm content:build` writes the catalog and action registry; `pnpm content:sync` loads samples into `upskillzz_w3`; running it again reports no changes.
- `content/README.md` is enough for someone new to publish a skill without asking questions.

## Out of scope

Stripe product sync itself (W4 implements `syncCatalogToStripe`; you only call it), website pages (W5), MCP delivery (W2).

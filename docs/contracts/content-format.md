# Contract: content format

Version 1.0 (2026-10-26)

How skills and packs are written in `content/`, what is public and what is paid, and the rules the validator and sync enforce. The Zod schemas in `packages/shared` implement this file.

## Layout

```
content/
  package.json                      # workspace package so actions can import @upskillzz/shared and zod
  README.md                         # authoring guide for Borna
  skills/
    _template/                      # copy this to start a skill (always ignored by the loader)
    _samples/                       # sample skills for dev and tests (loaded only when CONTENT_INCLUDE_SAMPLES=true)
      <slug>/...
    <slug>/                         # one folder per real skill
      skill.yaml                    # store metadata (public except where noted)
      SKILL.md                      # PAID instructions, Agent Skills frontmatter
      preview.md                    # PUBLIC sample shown on the skill page
      references/                   # optional, PAID
        <name>.md
      actions/                      # optional, PAID code that runs on the server
        <name>.ts
  packs/
    _template.yaml                  # ignored
    _samples/<slug>.yaml            # loaded only when CONTENT_INCLUDE_SAMPLES=true
    <slug>.yaml
```

Any folder or file whose name starts with `_` is ignored, except `_samples` when `CONTENT_INCLUDE_SAMPLES=true`. Production never sets it.

## Slugs and names

| Thing | Pattern | Example | Mutable after publish? |
|---|---|---|---|
| Skill slug (folder name) | `^[a-z0-9]+(-[a-z0-9]+)*$`, 3 to 48 chars | `cold-email-writer` | No |
| Pack slug (file name) | same | `sales-starter-pack` | No |
| Tool name | `^[a-z][a-z0-9_]{2,47}$`, must not start with `upskillzz_` | `cold_email_writer` | No |
| Reference name | `^[a-z0-9]+(-[a-z0-9]+)*$`, at most 40 chars | `objection-handling` | Yes |
| Action name | `^[a-z][a-z0-9_]{1,15}$` | `score` | Yes |

Skill slugs and pack slugs share one namespace (a pack can't have a skill's slug). `<tool_name>__<action>` must be at most 64 characters.

## `skill.yaml`

```yaml
title: Cold Email Writer                 # required, at most 60 chars
tool_name: cold_email_writer             # required, see pattern
version: 1.0.0                           # required, semver; bump when paid content changes
status: published                        # draft | published | archived
price_eur: 19                            # required; VAT-inclusive; 0 = free; otherwise 0.50 or more, at most 2 decimals
summary: >-                              # required, at most 140 chars, shown on cards
  Write short, specific B2B cold emails that get replies.
category: sales                          # required, one of the categories below
tags: [email, outreach, b2b]             # 0 to 8 tags, kebab-case
outcomes:                                # 1 to 6 bullets for the skill page, each at most 120 chars
  - A first email plus two follow-ups, tailored to one prospect
  - Subject lines tested against common spam triggers
works_with: [claude-web, claude-desktop, claude-mobile, claude-code]   # any non-empty subset
references:                              # optional
  - name: objection-handling
    title: Objection handling cheatsheet
    file: references/objection-handling.md
actions:                                 # optional
  - file: actions/score.ts
updated: 2026-10-26                      # required, ISO date, shown on the page
```

Categories (v1): `writing`, `sales`, `marketing`, `productivity`, `research`, `data`, `engineering`, `design`, `education`, `career`, `finance`, `other`. Adding one is a contract change.

## `SKILL.md`

Standard Agent Skills format, so the same folder can be tested locally in Claude Code before it is sold.

```markdown
---
name: cold-email-writer                  # must equal the folder name
description: >-                          # becomes the MCP tool description; at most 1024 chars
  Use when the user wants to write or improve a B2B cold email or follow-up
  sequence. Do not use for marketing newsletters or replies to existing threads.
---

# Cold Email Writer

...instructions Claude follows...
```

Rules:
- The frontmatter is parsed and stripped. Only the body is stored in `skill.instructions_md` and delivered.
- `description` should say when to use the skill and when not to. It is shown only to owners' Claude, never on the website.
- The body may mention reference names; Claude loads them by calling the skill's tool with `{ "reference": "<name>" }`. The delivery footer explains that automatically, so authors don't need to.
- Maximum body size 60 KB. Reference files at most 100 KB each.

## `preview.md`

Public Markdown shown on the skill page: what the skill does, who it is for, an example request and a shortened example result. It must not contain the instructions. Maximum 8 KB.

## `references/*.md`

Paid Markdown. Loaded on demand through the skill's tool. Listed in `skill.yaml` with a title.

## `actions/*.ts`

Server-side code exposed as extra MCP tools named `<tool_name>__<action name>`.

```ts
import { defineAction } from "@upskillzz/shared";
import { z } from "zod";

export const action = defineAction({
  name: "score",
  description: "Scores a draft cold email from 0 to 100 and lists concrete fixes. Call after drafting.",
  readOnly: true,
  input: z.object({ subject: z.string().max(200), body: z.string().max(5000) }),
  async run(input, ctx) {
    // ctx: { userId, skillSlug, logger, signal }
    return { score: 72, fixes: ["Cut the first sentence"] };
  },
});
```

Rules: one named export `action` per file; no network or filesystem access unless the action needs it and the skill's README in the PR says why; must finish within 10 seconds (the server aborts through `ctx.signal`); return a JSON-serialisable value or a string; never read other users' data.

## Packs: `packs/<slug>.yaml`

```yaml
title: Sales Starter Pack                # at most 60 chars
status: published
price_eur: 39                            # greater than 0
summary: >-
  Three skills for outbound sales, from first email to discovery call.
skills: [cold-email-writer, discovery-call-prep, linkedin-outreach]   # 2 or more skill slugs
updated: 2026-10-26
```

A published pack may contain only published skills.

## Public vs paid fields

**Public** (may appear in the public catalog, website pages, Stripe product data):
skill `slug`, `title`, `summary`, `version`, price, `category`, `tags`, `outcomes`, `works_with`, `updated`, `preview.md` content, reference titles and count, whether it has actions; pack `slug`, `title`, `summary`, price, skill slugs, `updated`.

**Paid** (only in the database and MCP responses to owners):
SKILL.md body, SKILL.md `description`, reference file contents, action code, action descriptions and input schemas, `tool_name`.

The public catalog shape is `PublicCatalog` in `docs/contracts/interfaces.md`. A test fails the build if any line of paid text longer than 30 characters appears in the catalog JSON or the website's build output.

## Validation and sync rules

The validator (`pnpm content:validate`) reports every problem with file path and field, not just the first. The sync (`pnpm content:sync`) then enforces:

1. **Immutable identifiers.** A skill or pack that has `published_at` in the database can't change its slug or tool name. To "rename", archive and create a new one.
2. **Version bumps.** If a skill's `content_hash` changed but its `version` didn't, sync fails with a message telling the author to bump the version.
3. **Archive, never delete.** A skill or pack in the database but missing from `content/` (or with `status: archived`) becomes `archived`: hidden from the store, not purchasable, still delivered to existing owners.
4. **Drafts.** `status: draft` is synced to the database but is never public, never purchasable and never delivered.
5. **Prices.** A changed price creates a new Stripe price and makes it active; the old one is deactivated. Existing owners are unaffected.
6. **Packs.** A pack can't contain draft or archived skills; sync fails if it does.
7. **Dry run.** `--dry-run` prints the full plan (create, update, archive, Stripe changes) and writes nothing.

## Changelog

- 1.0 (2026-10-26): initial version.

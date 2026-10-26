# content/ — CLAUDE.md

This folder holds the products: Borna's skills and packs. Format: `docs/contracts/content-format.md`.

## Ownership

- `skills/<slug>/` and `packs/<slug>.yaml` (anything not starting with `_`) are **Borna's**. Agents never create, edit or delete them unless Borna asks in the conversation.
- W3 owns `README.md`, this file, `skills/_template/`, `skills/_samples/`, `packs/_template.yaml` and `packs/_samples/`.
- W0 owns `package.json` (this folder is the workspace package `@upskillzz/content-src` so action files type-check).

## Rules

- `SKILL.md`, `references/` and `actions/` are paid content. Never copy them into anything public: website code, the public catalog, Stripe product descriptions, logs, tests that snapshot public output.
- Samples must be realistic and useful (they double as demo content) but clearly samples: they live under `_samples/` and load only with `CONTENT_INCLUDE_SAMPLES=true`.
- Run `pnpm content:validate` after any change here.

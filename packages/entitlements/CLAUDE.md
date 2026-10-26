# packages/entitlements — CLAUDE.md

Owner: **W4**. Spec: the `@upskillzz/entitlements` section of `docs/contracts/interfaces.md`, and the access rule and `entitlement` table in `docs/contracts/database.md`.

The single source of truth for "does this user own this skill". The MCP server's security depends on it.

## Structure

```
src/
  index.ts
  access-rule.ts     the SQL condition for "owns", used by every read
  read.ts            listOwnedSkills, listOwnedSlugs, ownsSkill, getOwnedSkillContent, getOwnedReference
  grant.ts           grantForPaidOrder, grantFree, grantManual
  revoke.ts          revokeForOrder
test/
```

## Rules

- One implementation of the access rule (non-revoked entitlement, skill `published` or `archived`), reused by every read. Drafts are never accessible.
- Grants are idempotent through the unique index plus `on conflict do nothing`. Calling any grant twice must leave the same rows.
- `grantForPaidOrder` refuses orders that are not `paid`. Packs expand to one row per skill (`source = 'pack'`, `pack_id` set).
- `revokeForOrder` touches only that order's rows.
- Only this package writes the `entitlement` table.
- `listOwnedSkills` runs on every MCP request: one query, indexed, no N+1. Measure it in a test with 50 owned skills.
- No Stripe or HTTP here. `@upskillzz/payments` calls into this package, never the reverse.

## Testing

Real local Postgres via `withTestDb`. Cover every function, idempotency, pack expansion, revoke isolation (same skill owned through two routes), drafts and archived skills, and the 50-skill performance check. `pnpm --filter @upskillzz/entitlements test`.

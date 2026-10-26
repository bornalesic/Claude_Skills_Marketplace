# Contract: database

Version 1.0 (2026-10-26)

Postgres 16 or newer (Neon in production, Docker locally). Drizzle ORM. Schema files live in `packages/db/src/schema/`, one file per area. Migrations live in `packages/db/migrations/` and are generated only by the orchestrator on `main`.

Conventions: snake_case table and column names; `id uuid primary key default gen_random_uuid()` for app tables; `created_at` and `updated_at` as `timestamptz not null default now()` on every app table unless noted; money in integer cents; currency lowercase ISO (`eur`).

## Better Auth tables (`schema/auth.ts`, owned by W1)

Generated with Better Auth's CLI for the Drizzle adapter from the exact plugin set W1 configures: core (`user`, `session`, `account`, `verification`), the JWT plugin (`jwks`), and the MCP / OAuth provider plugin (`oauthClient`, `oauthAccessToken`, `oauthRefreshToken`, `oauthConsent`, `oauthClientAssertion`, plus whatever the CIMD plugin adds). Use the names Better Auth generates; don't rename them.

App tables reference `user.id`, which is Better Auth's string ID: **`user_id` columns are `text`**, with a foreign key to `user.id` and `on delete restrict` (we never silently drop purchase history).

W0 generates the first version of this file so foreign keys have a target; W1 owns it afterwards.

## Enums

| Enum | Values |
|---|---|
| `catalog_status` | `draft`, `published`, `archived` |
| `order_status` | `pending`, `paid`, `failed`, `expired`, `refunded`, `partially_refunded` |
| `order_item_type` | `skill`, `pack` |
| `entitlement_source` | `purchase`, `pack`, `free`, `grant` |
| `usage_outcome` | `ok`, `not_owned`, `rate_limited`, `error` |

## Catalog tables (`schema/catalog.ts`)

Written **only** by `packages/content` sync, with one exception: the `stripe_product_id` and `stripe_price_id` columns are written by `syncCatalogToStripe` in `packages/payments`. Everyone else reads.

### `skill`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | |
| `slug` | text not null unique | Folder name. Immutable once published |
| `tool_name` | text not null unique | MCP tool name. Immutable once published |
| `title` | text not null | |
| `summary` | text not null | Card text, at most 140 chars |
| `description` | text not null | The MCP tool description (SKILL.md frontmatter `description`). Shown to Claude for owners; not in the public catalog |
| `version` | text not null | Semver from `skill.yaml` |
| `status` | `catalog_status` not null | |
| `price_cents` | integer not null | VAT-inclusive. `0` means free |
| `currency` | text not null default `'eur'` | |
| `category` | text not null | |
| `tags` | text[] not null default `'{}'` | |
| `instructions_md` | text not null | **PAID.** SKILL.md body without frontmatter |
| `content_hash` | text not null | sha256 over instructions, references and action sources |
| `stripe_product_id` | text | Null for free skills |
| `stripe_price_id` | text | Current active price. Null for free skills |
| `published_at` | timestamptz | Set on first publish, never cleared |
| `archived_at` | timestamptz | |
| `created_at`, `updated_at` | timestamptz | |

Indexes: unique `slug`, unique `tool_name`, index on `status`.

### `skill_reference`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | |
| `skill_id` | uuid not null fk → `skill.id` on delete cascade | |
| `name` | text not null | Kebab-case, used as the tool's `reference` argument |
| `title` | text not null | |
| `body_md` | text not null | **PAID** |
| `sort` | integer not null default 0 | |

Unique (`skill_id`, `name`).

### `skill_action`

Metadata only. The code lives in the content folder and is compiled into the action registry.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | |
| `skill_id` | uuid not null fk → `skill.id` on delete cascade | |
| `name` | text not null | Snake_case |
| `description` | text not null | Tool description |
| `input_schema` | jsonb not null | JSON Schema generated from the action's Zod schema |
| `read_only` | boolean not null default true | Becomes the MCP `readOnlyHint` |

Unique (`skill_id`, `name`).

### `pack`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | |
| `slug` | text not null unique | Immutable once published |
| `title`, `summary` | text not null | |
| `status` | `catalog_status` not null | |
| `price_cents` | integer not null | VAT-inclusive, greater than 0 |
| `currency` | text not null default `'eur'` | |
| `stripe_product_id`, `stripe_price_id` | text | |
| `published_at`, `archived_at`, `created_at`, `updated_at` | timestamptz | |

### `pack_item`

| Column | Type | Notes |
|---|---|---|
| `pack_id` | uuid fk → `pack.id` on delete cascade | |
| `skill_id` | uuid fk → `skill.id` on delete restrict | |
| `sort` | integer not null default 0 | |

Primary key (`pack_id`, `skill_id`). No timestamps.

## Commerce tables (`schema/commerce.ts`)

Written by `packages/payments` (orders, events) and `packages/entitlements` (entitlements).

### `orders`

Named `orders` because `order` is a reserved word.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | Also sent to Stripe as `client_reference_id` |
| `user_id` | text not null fk → `user.id` | |
| `status` | `order_status` not null default `'pending'` | |
| `stripe_checkout_session_id` | text unique | Null until the session is created |
| `stripe_payment_intent_id` | text | |
| `currency` | text not null | |
| `subtotal_cents` | integer not null | Sum of item prices (VAT-inclusive) |
| `tax_cents` | integer not null default 0 | VAT portion reported by Stripe |
| `total_cents` | integer not null | Amount actually charged |
| `withdrawal_waiver_at` | timestamptz not null | When the buyer consented to immediate access |
| `paid_at`, `refunded_at` | timestamptz | |
| `created_at`, `updated_at` | timestamptz | |

Indexes: (`user_id`, `created_at` desc).

### `order_item`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | |
| `order_id` | uuid not null fk → `orders.id` on delete cascade | |
| `item_type` | `order_item_type` not null | |
| `skill_id` | uuid fk → `skill.id` | Set when `item_type = 'skill'` |
| `pack_id` | uuid fk → `pack.id` | Set when `item_type = 'pack'` |
| `unit_price_cents` | integer not null | Price at purchase time |

Check constraint: exactly one of `skill_id`, `pack_id` is set and matches `item_type`. v1 orders have one item.

### `entitlement`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid pk | |
| `user_id` | text not null fk → `user.id` | |
| `skill_id` | uuid not null fk → `skill.id` | |
| `source` | `entitlement_source` not null | |
| `order_id` | uuid fk → `orders.id` | Set for `purchase` and `pack` |
| `pack_id` | uuid fk → `pack.id` | Set for `pack` |
| `note` | text | For manual grants |
| `granted_at` | timestamptz not null default now() | |
| `revoked_at` | timestamptz | |

Unique index on (`user_id`, `skill_id`, `source`, `order_id`) **NULLS NOT DISTINCT**, which makes grants idempotent (one free claim per user and skill; one row per order and skill).
Index on (`user_id`) where `revoked_at is null`.

**Access rule:** a user owns a skill when at least one entitlement row for (user, skill) has `revoked_at is null`, and the skill's status is `published` or `archived`. Draft skills are never accessible.

### `stripe_event`

| Column | Type | Notes |
|---|---|---|
| `id` | text pk | Stripe event ID (`evt_...`) |
| `type` | text not null | |
| `received_at` | timestamptz not null default now() | |
| `processed_at` | timestamptz | Null until handled successfully |
| `error` | text | Last processing error |

No `created_at` / `updated_at`.

## Usage table (`schema/usage.ts`)

Written by `apps/mcp`, asynchronously.

### `mcp_usage`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint generated always as identity pk | |
| `user_id` | text not null | No foreign key (logging must never fail on it) |
| `skill_id` | uuid | Null for `upskillzz_library` |
| `tool_name` | text not null | |
| `client_id` | text | OAuth client from the token, if present |
| `outcome` | `usage_outcome` not null | |
| `duration_ms` | integer not null | |
| `created_at` | timestamptz not null default now() | |

Index on (`user_id`, `created_at` desc). No `updated_at`.

## Changelog

- 1.0 (2026-10-26): initial version.

# Contract: package interfaces

Version 1.0 (2026-10-26)

What each workspace package exports. Signatures are TypeScript. Anything not listed is internal and may change freely. Packages take a `Db` (and other clients) as arguments instead of creating their own, so apps control connections and tests can pass a test database.

Package names: `@upskillzz/shared`, `@upskillzz/db`, `@upskillzz/auth`, `@upskillzz/content`, `@upskillzz/entitlements`, `@upskillzz/payments`, `@upskillzz/web` (app), `@upskillzz/mcp` (app), `@upskillzz/content-src` (the `content/` folder).

## `@upskillzz/shared`

No dependencies on other workspace packages. Runtime dependency: `zod` only.

```ts
// constants
export const SLUG_RE: RegExp;
export const TOOL_NAME_RE: RegExp;
export const REFERENCE_NAME_RE: RegExp;
export const ACTION_NAME_RE: RegExp;
export const RESERVED_TOOL_PREFIX = "upskillzz_";
export const MCP_SCOPE = "skills";
export const CATEGORIES: readonly ["writing", "sales", "marketing", "productivity", "research", "data", "engineering", "design", "education", "career", "finance", "other"];
export const WORKS_WITH: readonly ["claude-web", "claude-desktop", "claude-mobile", "claude-code"];
export type Category = (typeof CATEGORIES)[number];
export type WorksWith = (typeof WORKS_WITH)[number];

// content file schemas (see content-format.md)
export const SkillYamlSchema: z.ZodType<SkillYaml>;
export const SkillFrontmatterSchema: z.ZodType<{ name: string; description: string }>;
export const PackYamlSchema: z.ZodType<PackYaml>;

// public catalog (the only content shape the website may import)
export type PublicSkill = {
  slug: string;
  title: string;
  summary: string;
  version: string;
  priceCents: number;
  currency: "eur";
  category: Category;
  tags: string[];
  outcomes: string[];
  worksWith: WorksWith[];
  previewMd: string;
  referenceTitles: string[];
  hasActions: boolean;
  packSlugs: string[];
  updated: string;            // ISO date
};
export type PublicPack = {
  slug: string;
  title: string;
  summary: string;
  priceCents: number;
  currency: "eur";
  skillSlugs: string[];
  separatePriceCents: number; // sum of the skills' prices, for "save X"
  updated: string;
};
export type PublicCatalog = { generatedAt: string; skills: PublicSkill[]; packs: PublicPack[] };
export const PublicCatalogSchema: z.ZodType<PublicCatalog>;

// server-side actions
export type ActionContext = {
  userId: string;
  skillSlug: string;
  logger: { info(obj: object, msg?: string): void; warn(obj: object, msg?: string): void; error(obj: object, msg?: string): void };
  signal: AbortSignal;
};
export type ActionDefinition<I extends z.ZodTypeAny = z.ZodTypeAny> = {
  name: string;
  description: string;
  readOnly: boolean;
  input: I;
  run(input: z.infer<I>, ctx: ActionContext): Promise<unknown>;
};
export function defineAction<I extends z.ZodTypeAny>(def: ActionDefinition<I>): ActionDefinition<I>;

// connecting Claude (used by the library page and the tutorial)
export function claudeAddConnectorUrl(mcpUrl: string): string;
// -> "https://claude.ai/customize/connectors?modal=add-custom-connector&connectorName=Upskillzz&connectorUrl=<encoded mcpUrl>"
//    (link format seen in other vendors' docs; W6 verifies it still works and reports if not)
export function claudeCodeAddCommand(mcpUrl: string): string;
// -> "claude mcp add --transport http upskillzz <mcpUrl>"

// env and misc
export function parseEnv<S extends z.ZodTypeAny>(schema: S, source?: Record<string, string | undefined>): z.infer<S>; // throws one readable error listing every problem
export function formatPrice(cents: number, currency: "eur"): string;   // "€19.00"
export class AppError extends Error { code: string; status: number }
```

## `@upskillzz/db`

```ts
export type Db;                                    // Drizzle database instance
export function createDb(databaseUrl: string, opts?: { max?: number }): { db: Db; close(): Promise<void> };
export * as schema from "./schema";                // all tables and enums from database.md
export function withTestDb<T>(fn: (db: Db) => Promise<T>): Promise<T>; // test helper: isolated schema or transaction rolled back
```

Driver: `postgres` (postgres.js). Use Neon's pooled connection string in production.

## `@upskillzz/auth` (W1)

Two entry points so `apps/mcp` never loads the full auth server.

```ts
// "@upskillzz/auth"  (server only; used by apps/web)
export const auth: BetterAuthInstance;             // created from env at import time
export type SessionUser = { id: string; email: string; name: string; image?: string | null };
export function getSessionUser(headers: Headers): Promise<SessionUser | null>;

// "@upskillzz/auth/verify"  (used by apps/mcp; depends only on jose-level verification)
export type AccessTokenClaims = {
  sub: string;          // user id
  iss: string;          // AUTH_ISSUER
  aud: string | string[]; // must include MCP_URL
  scope: string;        // space-separated, must include "skills"
  client_id?: string;   // or azp, whichever Better Auth emits
  exp: number;
  iat: number;
};
export type VerifiedToken = { userId: string; scopes: string[]; clientId: string | null };
export class TokenError extends Error { kind: "missing" | "invalid" | "expired" | "wrong_audience" | "insufficient_scope" }
export function createTokenVerifier(opts: { issuer: string; audience: string; jwksUrl: string; requiredScopes?: string[] }): (authorizationHeader: string | null) => Promise<VerifiedToken>; // JWKS cached and refreshed on unknown kid
```

Until W1 merges, W2 implements the same `createTokenVerifier` signature locally with `jose` and swaps the import afterwards.

## `@upskillzz/content` (W3)

```ts
export type LoadedSkill = {
  slug: string;
  yaml: SkillYaml;
  frontmatter: { name: string; description: string };
  instructionsMd: string;          // PAID
  previewMd: string;
  references: { name: string; title: string; bodyMd: string; sort: number }[]; // PAID bodies
  actions: { name: string; description: string; readOnly: boolean; inputJsonSchema: object; file: string }[];
  contentHash: string;
  isSample: boolean;
};
export type LoadedPack = { slug: string; yaml: PackYaml; isSample: boolean };
export type ContentBundle = { skills: LoadedSkill[]; packs: LoadedPack[] };
export class ContentValidationError extends Error { issues: { file: string; path: string; message: string }[] }

export function loadContent(opts?: { dir?: string; includeSamples?: boolean }): Promise<ContentBundle>; // throws ContentValidationError
export function buildPublicCatalog(bundle: ContentBundle): PublicCatalog;   // published only, public fields only
export type SyncPlan = { creates: string[]; updates: string[]; archives: string[]; errors: string[] };
export function syncContentToDb(db: Db, bundle: ContentBundle, opts: { dryRun: boolean }): Promise<SyncPlan>;

// "@upskillzz/content/catalog"  (safe for apps/web; reads the generated JSON)
export function getPublicCatalog(): PublicCatalog;
export function getPublicSkill(slug: string): PublicSkill | undefined;
export function getPublicPack(slug: string): PublicPack | undefined;

// "@upskillzz/content/actions"  (used by apps/mcp only)
export const actionRegistry: Record<string /* skill slug */, Record<string /* action name */, ActionDefinition>>;
```

CLI (wired to root scripts): `content validate`, `content build` (writes the catalog JSON and the action registry), `content sync [--dry-run] [--stripe]`. With `--stripe`, after the DB sync it calls `syncCatalogToStripe` from `@upskillzz/payments`.

## `@upskillzz/entitlements` (W4)

```ts
export type OwnedSkill = {
  skillId: string;
  slug: string;
  toolName: string;
  title: string;
  description: string;         // tool description
  version: string;
  status: "published" | "archived";
  references: { name: string; title: string }[];
  actions: { name: string; description: string; readOnly: boolean; inputSchema: object }[];
};
export type SkillContent = OwnedSkill & { instructionsMd: string; contentHash: string };

export function listOwnedSkills(db: Db, userId: string): Promise<OwnedSkill[]>;          // one query, ordered by title
export function listOwnedSlugs(db: Db, userId: string): Promise<string[]>;
export function ownsSkill(db: Db, userId: string, slug: string): Promise<boolean>;
export function getOwnedSkillContent(db: Db, userId: string, slug: string): Promise<SkillContent | null>; // null when not owned
export function getOwnedReference(db: Db, userId: string, slug: string, referenceName: string): Promise<{ title: string; bodyMd: string } | null>;

export function grantForPaidOrder(db: Db, orderId: string): Promise<{ granted: number }>;   // idempotent; expands packs
export function grantFree(db: Db, userId: string, slug: string): Promise<{ granted: boolean }>; // only for published skills priced 0
export function grantManual(db: Db, userId: string, slug: string, note: string): Promise<void>;
export function revokeForOrder(db: Db, orderId: string): Promise<{ revoked: number }>;
```

## `@upskillzz/payments` (W4)

```ts
export type PaymentsDeps = { db: Db; stripe: Stripe; appUrl: string; automaticTax: boolean };
export function createStripe(secretKey: string): Stripe;   // pins the API version

export class AlreadyOwnedError extends AppError {}
export class NotPurchasableError extends AppError {}
export class WaiverRequiredError extends AppError {}

export function createCheckoutSession(
  deps: PaymentsDeps,
  input: { userId: string; email: string; item: { type: "skill" | "pack"; slug: string }; withdrawalWaiver: true }
): Promise<{ orderId: string; url: string }>;

export function handleStripeWebhook(
  deps: PaymentsDeps,
  input: { rawBody: string; signature: string | null; webhookSecret: string }
): Promise<{ result: "processed" | "duplicate" | "ignored" }>;   // throws on bad signature

export function getOrderForUser(db: Db, userId: string, orderId: string): Promise<{ id: string; status: string; items: { type: "skill" | "pack"; slug: string; title: string }[] } | null>;
export function listOrdersForUser(db: Db, userId: string): Promise<{ id: string; status: string; totalCents: number; currency: string; paidAt: string | null; items: { type: "skill" | "pack"; slug: string; title: string }[] }[]>;

export type StripeSyncPlan = { products: { created: string[]; updated: string[]; archived: string[] }; prices: { created: string[]; deactivated: string[] } };
export function syncCatalogToStripe(deps: Pick<PaymentsDeps, "db" | "stripe">, opts: { dryRun: boolean }): Promise<StripeSyncPlan>; // reads skill/pack rows; writes stripe ids back
```

## Inside `apps/web`: helpers shared between workstreams

```ts
// apps/web/src/lib/session.ts (W1)
export function getCurrentUser(): Promise<SessionUser | null>;      // server components and route handlers
export function requireUser(next: string): Promise<SessionUser>;    // redirects to /sign-in?next=...

// apps/web/src/lib/auth-client.ts (W1, client components)
export function signInWithGoogle(next?: string): Promise<void>;
export function signInAsTestUser(next?: string): Promise<void>;     // only works when DEV_LOGIN_ENABLED=true
export function signOut(): Promise<void>;

// apps/web/src/server/commerce/index.ts (W4, server only)
export type BuyState =
  | { kind: "signed_out" }
  | { kind: "buy"; priceCents: number }
  | { kind: "claim_free" }
  | { kind: "owned" }
  | { kind: "pack_partially_owned"; priceCents: number; ownedSlugs: string[] };
export function getBuyState(user: SessionUser | null, item: { type: "skill" | "pack"; slug: string }): Promise<BuyState>;
export function getLibrary(userId: string): Promise<{ skills: OwnedSkill[]; orders: Awaited<ReturnType<typeof listOrdersForUser>> }>;
```

## Changelog

- 1.0 (2026-10-26): initial version.

# Brief: W4 payments and entitlements

**Branch:** `ws/w4-payments` · **Phase:** 1 · **Ports:** 3050 / 3051 · **DB:** `upskillzz_w4`

## Mission

Take money correctly and record ownership correctly. Buyers pay once through Stripe Checkout for a skill or a pack; a verified webhook grants ownership; refunds take it away; free skills can be claimed. Ownership is the security boundary for paid content, so these rules must be airtight and idempotent.

## Read first

- `docs/contracts/interfaces.md` (`@upskillzz/entitlements`, `@upskillzz/payments`), `database.md` (commerce tables, access rule), `http-routes.md` (checkout, claim, orders, webhook, buy-area states), `env.md`
- `docs/ARCHITECTURE.md` flow 1, `docs/DECISIONS.md` D9, `docs/LAUNCH_CHECKLIST.md` (tax and withdrawal items)
- `packages/payments/CLAUDE.md`, `packages/entitlements/CLAUDE.md`

## You own

`packages/payments/**`, `packages/entitlements/**`, `apps/web/src/app/api/checkout/**`, `apps/web/src/app/api/claim/**`, `apps/web/src/app/api/orders/**`, `apps/web/src/app/api/buy-state/**`, `apps/web/src/app/api/stripe/**`, `apps/web/src/server/commerce/**`.

## Verify before building

- Stripe Checkout one-time payments, `client_reference_id`, `metadata`, `customer_email`, `allow_promotion_codes`, `custom_text`, `consent_collection`: https://docs.stripe.com/payments/checkout
- Stripe Tax with Checkout (`automatic_tax`, tax-inclusive prices, product tax codes): https://docs.stripe.com/tax/checkout
- Webhooks: signature verification on the raw body, retries, ordering, idempotency: https://docs.stripe.com/webhooks
- Products and Prices (`lookup_key`, `transfer_lookup_key`, deactivating prices), and the current API version to pin

## Stubs until others merge

- Session user in route handlers: use `getSessionUser` from `@upskillzz/auth`; until W1 merges, a small local helper in `apps/web/src/server/commerce/session-stub.ts` that returns a fixed test user when `DEV_LOGIN_ENABLED=true`.
- Catalog rows: seed them in tests directly with Drizzle (W3's sync isn't required for your tests).

## Deliverables

### Entitlements (`@upskillzz/entitlements`)

1. Every function in `interfaces.md`, applying the access rule in `database.md` (non-revoked entitlement and skill status `published` or `archived`; drafts never).
2. `listOwnedSkills` in a single query (joins references and actions), fast enough to run on every MCP request with an index.
3. `grantForPaidOrder`: only for orders with status `paid`; expands pack items into one entitlement per skill with `source = 'pack'`; skill items get `source = 'purchase'`; safe to run any number of times (unique index plus `on conflict do nothing`).
4. `revokeForOrder`: sets `revoked_at` on that order's entitlements only. Ownership from other orders, packs or free claims stays.

### Payments (`@upskillzz/payments`)

5. `createStripe` with a pinned API version.
6. `createCheckoutSession`:
   - Requires `withdrawalWaiver: true` (else `WaiverRequiredError`).
   - Loads the item by slug from the database; must be published and priced above 0 with a `stripe_price_id` (else `NotPurchasableError`). Skill already owned: `AlreadyOwnedError`.
   - Creates a `pending` order with one item at the database price and `withdrawal_waiver_at = now()`.
   - Creates a Checkout Session in payment mode with the stored Stripe price, `customer_email`, `client_reference_id = order.id`, `metadata { orderId, userId }`, `automatic_tax` when `STRIPE_AUTOMATIC_TAX=true`, `allow_promotion_codes: true`, success URL `/checkout/success?order=<id>` and cancel URL `/checkout/cancel?order=<id>` on `APP_URL`, and a short `custom_text` near the submit button repeating the immediate-access consent.
   - Saves the session ID on the order.
7. `handleStripeWebhook`:
   - Verify the signature on the raw body (`400` on failure).
   - Insert into `stripe_event`; if the ID already exists and was processed, return `duplicate`.
   - `checkout.session.completed` with `payment_status = 'paid'`, or `checkout.session.async_payment_succeeded`: mark the order `paid` (amounts and tax from the session), then `grantForPaidOrder`. Find the order through `client_reference_id`; cross-check `metadata.userId`.
   - `checkout.session.async_payment_failed`: `failed`. `checkout.session.expired`: `expired`.
   - `charge.refunded`: full refund → `refunded` + `revokeForOrder`; partial → `partially_refunded`, keep access (log it for Borna to decide manually).
   - Everything for one event in one transaction; set `processed_at` on success; on failure store `error` and rethrow so the route returns `500` and Stripe retries.
8. `getOrderForUser`, `listOrdersForUser`.
9. `syncCatalogToStripe`: for every published skill priced above 0 and every published pack, ensure a Stripe Product (metadata `type`, `slug`; name and description from title and summary) and an active Price in EUR with `tax_behavior: 'inclusive'` and `lookup_key` `skill:<slug>` or `pack:<slug>`. Price changed: create a new price, transfer the lookup key, deactivate the old one. Archived items: archive the product (`active: false`). Write the IDs back to the `skill` / `pack` rows. Dry run prints the plan. Idempotent.

### Web routes and server helpers

10. Route handlers per `http-routes.md` for checkout, claim, orders, buy-state and the webhook (Node runtime, raw body for the webhook, Zod validation, error shape from the contract).
11. `apps/web/src/server/commerce/index.ts` helpers for W5's server components, exactly as in the "Inside apps/web" section of `interfaces.md`: `getBuyState` and `getLibrary`.

## Tests (real local Postgres; Stripe mocked at the HTTP boundary or stripe-mock)

- Price tampering is impossible: the request has no price field; the session uses the database price ID.
- Waiver missing → `400 waiver_required`; already owned → `409`; draft, archived or free → `404`.
- Webhook: bad signature → `400`; valid `completed` grants once; replaying the same event → `duplicate`, no extra rows; out-of-order `expired` after `paid` doesn't downgrade a paid order.
- Pack purchase grants each skill; refund revokes only that order's entitlements; a skill also owned through a free claim or another order stays owned.
- Free claim: grants once, second call `granted: false`, paid skill → `404 not_free`.
- `syncCatalogToStripe`: creates, is idempotent, rotates price on change, archives removed.

Build signed webhook payloads with the Stripe SDK's test header helper.

## Acceptance checks

- With `stripe listen` forwarding to `localhost:3050`, buying a seeded skill with card 4242... ends with the order `paid` and the entitlement present; refunding it in the Stripe dashboard revokes it.
- `pnpm --filter @upskillzz/payments test` and `pnpm --filter @upskillzz/entitlements test` green.

## Out of scope

Page design (W5 builds the buy area, success and cancel pages using your helpers and routes), content loading (W3).

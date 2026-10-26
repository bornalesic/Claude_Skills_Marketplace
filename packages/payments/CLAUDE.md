# packages/payments — CLAUDE.md

Owner: **W4**. Spec: the `@upskillzz/payments` section of `docs/contracts/interfaces.md`, the commerce tables in `docs/contracts/database.md`, the checkout and webhook routes in `docs/contracts/http-routes.md`, and `docs/DECISIONS.md` D9.

Stripe integration: checkout sessions, webhook processing, and syncing products and prices from the catalog.

## Structure

```
src/
  index.ts
  stripe.ts          createStripe (pinned API version)
  checkout.ts        createCheckoutSession
  webhook.ts         handleStripeWebhook and per-event handlers
  orders.ts          getOrderForUser, listOrdersForUser
  catalog-sync.ts    syncCatalogToStripe
  errors.ts          AlreadyOwnedError, NotPurchasableError, WaiverRequiredError
test/
```

## Rules

- Prices always come from the database row's `stripe_price_id`. Requests never carry a price.
- Every Checkout Session: payment mode, `client_reference_id = order.id`, `metadata { orderId, userId }`, `customer_email`, `allow_promotion_codes: true`, `automatic_tax` when enabled, success and cancel URLs from `APP_URL`.
- Webhooks: verify the signature on the raw body; record the event in `stripe_event` first; process each event in one transaction; set `processed_at` on success; on failure store the error and rethrow (the route returns `500` so Stripe retries). Never downgrade a `paid` order because of a late or out-of-order event.
- Ownership changes go through `@upskillzz/entitlements`; never write `entitlement` rows here.
- Prices are EUR, VAT-inclusive (`tax_behavior: 'inclusive'`).
- Never log card data (we never see it), full emails, or webhook secrets.

## Testing

Real local Postgres; Stripe mocked at the HTTP boundary or via stripe-mock; signed webhook payloads built with the Stripe SDK's test helper. `pnpm --filter @upskillzz/payments test`. Manual end-to-end with `stripe listen` is described in `docs/LOCAL_DEV.md`.

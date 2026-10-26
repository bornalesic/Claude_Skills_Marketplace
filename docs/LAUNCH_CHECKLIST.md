# Launch checklist

Everything here must be true before real customers pay. The business, tax and legal items are pointers for a conversation with an accountant and a lawyer in Croatia, not advice.

## Business, tax and legal (Borna, with professionals)

- [ ] A legal form that can sell online (for example an obrt or a d.o.o.), and the Stripe account opened in that name.
- [ ] VAT on digital services to EU consumers: decide with the accountant whether and when to register for the EU One-Stop Shop (Union scheme) and Croatian VAT, and how thresholds apply. Upskillzz is the seller of record because it uses Stripe directly, not a merchant of record.
- [ ] Stripe Tax configured: origin address, tax registrations, product tax code for electronically supplied services, prices marked tax-inclusive. Then set `STRIPE_AUTOMATIC_TAX=true` in production.
- [ ] Stripe receipt emails turned on, with the business details the law requires.
- [ ] Terms of sale, privacy policy (GDPR), refund policy and a skill license (personal or internal business use, no resale or redistribution). W6 writes drafts marked DRAFT; a lawyer reviews them.
- [ ] Withdrawal right for digital content: checkout asks for express consent to immediate access and acknowledgement that the 14-day withdrawal right is lost; the consent is stored on the order and confirmed in the receipt or a follow-up. Confirm the wording with the lawyer.
- [ ] Company or trader details shown on the site as required.
- [ ] Cookie banner only if non-essential cookies or analytics are added. v1 uses none.

## Accounts and configuration

- [ ] Domain bought; DNS on Cloudflare.
- [ ] Fly.io apps for production and staging (web and MCP), spend alerts set.
- [ ] Neon project in Frankfurt; backup and restore tested; decide on a paid plan with scale-to-zero disabled once sales start.
- [ ] Google OAuth client: production redirect URI, consent screen branding and support email, app published (we only request `openid`, `email`, `profile`).
- [ ] Stripe live keys and live webhook endpoint (`https://<domain>/api/stripe/webhook`) with the events listed in `docs/contracts/http-routes.md`.
- [ ] All production secrets set in Fly, none in git. `DEV_LOGIN_ENABLED` unset in production.
- [ ] Cloudflare: Anthropic's egress range `160.79.104.0/21` is never challenged or blocked on `/api/auth/*`, `/.well-known/*` or the MCP host. If unsure, keep the MCP host DNS-only (not proxied).

## Product checks on staging

- [ ] Buy a paid skill, a pack and a free skill with test cards; entitlements appear; Stripe shows tax correctly.
- [ ] Refund in Stripe; the skill disappears from the buyer's tool list.
- [ ] Connect from claude.ai (web), Claude Desktop, Claude mobile and Claude Code with a Pro account; sign in with Google; tools match what the account owns.
- [ ] Buy a new skill while connected; confirm it works in a new chat on the web, after "Refresh tools list" on desktop and mobile, and through `upskillzz_load_skill` without refreshing.
- [ ] Tutorial followed start to finish by someone non-technical in under 5 minutes. Note where they got stuck.
- [ ] Every tutorial screenshot slot filled; videos added or placeholders hidden.
- [ ] Content leak test passes on the production build.
- [ ] Lighthouse 90+ on home, catalog and a skill page (mobile).

## Operations

- [ ] Uptime checks on `/api/health` and the MCP `/healthz`, alerting to your email or phone.
- [ ] Error tracking (optional `SENTRY_DSN`) or at least log retention you can search.
- [ ] `docs/RUNBOOK.md` covers rollback, secret rotation, database restore and "Claude can't connect".
- [ ] At least three real skills published, each with a preview, clear outcomes and a good tool description.

## Later (not v1)

- Per-buyer watermarking (`applyWatermark` hook is already in place).
- Admin page for orders and manual grants.
- Submitting the connector to Claude's connectors directory (requires review).
- Upgrade pricing for packs when the buyer already owns some skills.

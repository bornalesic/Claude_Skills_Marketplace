# Contract: HTTP routes (website)

Version 1.0 (2026-10-26)

Routes served by `apps/web`. The MCP server's routes are in `mcp.md`.

## Pages

| Path | Owner | Auth | Rendering | Purpose |
|---|---|---|---|---|
| `/` | W5 | no | static | Home: what Upskillzz is, how it works in 3 steps, featured skills, link to tutorial |
| `/skills` | W5 | no | static, client-side filters | Catalog. Query params `category`, `tag`, `q` filter in the browser |
| `/skills/[slug]` | W5 | no | static (`generateStaticParams`) | Skill page: summary, outcomes, preview, works with, price, packs containing it, buy area |
| `/packs` | W5 | no | static | Pack list |
| `/packs/[slug]` | W5 | no | static | Pack page with included skills and savings |
| `/library` | W5 | yes | dynamic | Owned skills, "Connect Claude" panel, order history |
| `/checkout/success` | W5 | yes | dynamic | `?order=<id>`. Polls `GET /api/orders/[id]` until `paid`, then shows next steps |
| `/checkout/cancel` | W5 | yes | dynamic | `?order=<id>`. Reassures, links back to the item |
| `/sign-in` | W1 | no | dynamic | `?next=<path>`. "Continue with Google"; "Continue as test user" in dev |
| `/consent` | W1 | yes | dynamic | OAuth consent for MCP clients |
| `/tutorial` and `/tutorial/[step]` | W6 | no | static (MDX) | Beginner guide |
| `/legal/terms`, `/legal/privacy`, `/legal/refunds`, `/legal/license`, `/legal/imprint` | W6 | no | static (MDX) | Drafts until a lawyer reviews them |
| `/sitemap.xml`, `/robots.txt` | W5 | no | static | |
| not found, error | W5 | | | |

Auth-required pages redirect signed-out visitors to `/sign-in?next=<current path>`.

Buy area states on `/skills/[slug]` and `/packs/[slug]` (a small client component that calls `GET /api/buy-state`; the rest of the page stays static):
- signed out: "Buy €19" → sign in, then back to the page
- signed in, not owned, paid: "Buy €19" → waiver dialog → `POST /api/checkout` → redirect to Stripe
- signed in, not owned, free: "Get it free" → `POST /api/claim` → show "Added to your library"
- owned: "In your library" with a link to `/library`
- pack where the user owns some skills: show which, and that v1 charges the full pack price

The waiver dialog text (W6 may refine the wording; the meaning is fixed): "You'll get access immediately after payment. I agree to immediate access and understand that I therefore lose my 14-day right of withdrawal." Checkbox must be ticked to continue.

Library "Connect Claude" panel shows: the MCP URL with a copy button; an "Add to Claude" link built with `claudeAddConnectorUrl(MCP_URL)`; the Claude Code command from `claudeCodeAddCommand(MCP_URL)`; and the note: "Bought something new? Start a new chat on claude.ai. In the desktop or mobile app, open the connector's menu and choose Refresh tools list, or just ask Claude to load it." Link to `/tutorial`.

## API routes

All JSON. Errors use `{ "error": { "code": string, "message": string } }` with the HTTP status shown. Request bodies are validated with Zod; invalid input is `400 validation_error`.

### Better Auth (W1)

| Route | Notes |
|---|---|
| `/api/auth/*` | Better Auth handler: sign-in, sign-out, session, Google callback (`/api/auth/callback/google`), JWKS (`/api/auth/jwks`), OAuth endpoints (`/api/auth/oauth2/authorize`, `/token`, `/register`, `/userinfo`) |
| `/.well-known/oauth-authorization-server[...]` | Authorization server metadata at the RFC 8414 location for `AUTH_ISSUER`. W1 confirms the exact path(s) |
| `/.well-known/openid-configuration[...]` | OpenID discovery, if Better Auth serves it for the issuer |

Required in the authorization server metadata: `code_challenge_methods_supported: ["S256"]`, `token_endpoint_auth_methods_supported` including `"none"`, `client_id_metadata_document_supported: true`, `registration_endpoint`, `scopes_supported` including `offline_access` and `skills`.

### `POST /api/checkout` (W4)

Request: `{ "item": { "type": "skill" | "pack", "slug": string }, "withdrawalWaiver": true }`

| Status | Body |
|---|---|
| 200 | `{ "url": string, "orderId": string }` |
| 400 | `waiver_required`, `validation_error` |
| 401 | `unauthenticated` |
| 404 | `not_purchasable` (unknown, draft, archived, or free) |
| 409 | `already_owned` (skills only) |

### `POST /api/claim` (W4)

Request: `{ "slug": string }`

| Status | Body |
|---|---|
| 200 | `{ "granted": boolean }` (`false` if already owned) |
| 401 | `unauthenticated` |
| 404 | `not_free` (unknown, not published, or not priced 0) |

### `GET /api/orders/[id]` (W4)

| Status | Body |
|---|---|
| 200 | `{ "id": string, "status": "pending" \| "paid" \| "failed" \| "expired" \| "refunded" \| "partially_refunded", "items": [{ "type": "skill" \| "pack", "slug": string, "title": string }] }` |
| 401 | `unauthenticated` |
| 404 | `not_found` (also for other users' orders) |

### `GET /api/buy-state?type=skill|pack&slug=<slug>` (W4)

Lets static skill and pack pages render the buy area in the browser without becoming dynamic. Never cached (`Cache-Control: private, no-store`).

| Status | Body |
|---|---|
| 200 | A `BuyState` object (see `interfaces.md`, "Inside apps/web"), e.g. `{ "kind": "buy", "priceCents": 1900 }` or `{ "kind": "signed_out" }` |
| 404 | `not_found` (unknown or unpublished item) |

### `POST /api/stripe/webhook` (W4)

Raw body, `Stripe-Signature` header. Events handled: `checkout.session.completed`, `checkout.session.async_payment_succeeded`, `checkout.session.async_payment_failed`, `checkout.session.expired`, `charge.refunded`. Others are recorded and ignored.

| Status | When |
|---|---|
| 200 | Processed, duplicate, or ignored |
| 400 | Bad or missing signature |
| 500 | Processing failed (Stripe retries; the event row keeps the error) |

### `GET /api/health` (W5)

`200 { "ok": true }` when the database answers within 1 s, else `503 { "ok": false }`.

## Changelog

- 1.0 (2026-10-26): initial version.

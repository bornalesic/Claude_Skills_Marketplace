# apps/web — CLAUDE.md

The Next.js website: storefront, library, checkout pages, tutorial, legal pages, sign-in and consent, and the HTTP side of auth and payments. Several workstreams own parts of this app; check the table before editing.

## Ownership inside this app

| Path | Owner |
|---|---|
| `src/app/api/auth/**`, `src/app/(auth)/**`, `src/app/.well-known/**`, `src/lib/session.ts`, `src/lib/auth-client.ts`, the middleware/proxy file | W1 |
| `src/app/api/checkout/**`, `src/app/api/claim/**`, `src/app/api/orders/**`, `src/app/api/buy-state/**`, `src/app/api/stripe/**`, `src/server/commerce/**` | W4 |
| `src/app/tutorial/**`, `src/content/tutorial/**`, `src/components/tutorial/**`, `public/tutorial/**`, `src/app/legal/**`, `src/content/legal/**` | W6 |
| Everything else, including `src/app/globals.css` and `src/components/**` | W5 |

Anyone may add dependencies to `package.json`. Config files (`next.config.*`, `tsconfig.json`) belong to W5 after W0's scaffold; request changes.

## Structure

```
src/
  app/
    layout.tsx, globals.css, not-found.tsx, error.tsx      W5
    page.tsx                                               W5  home
    skills/page.tsx, skills/[slug]/page.tsx                W5
    packs/page.tsx, packs/[slug]/page.tsx                  W5
    library/page.tsx                                       W5
    checkout/success/page.tsx, checkout/cancel/page.tsx    W5
    sitemap.ts, robots.ts                                  W5
    api/health/route.ts                                    W5
    (auth)/sign-in/page.tsx, (auth)/consent/page.tsx       W1
    api/auth/[...all]/route.ts                             W1
    .well-known/...                                        W1
    api/{checkout,claim,orders,buy-state,stripe}/...       W4
    tutorial/page.tsx, tutorial/[step]/page.tsx            W6
    legal/[page]/page.tsx                                  W6
  components/
    ui/          shadcn/ui primitives                      W5
    store/       SkillCard, PackCard, Price, BuyArea, ...  W5
    shared/      CopyField, CodeCommand, Callout, ...      W5 (W6 reuses)
    tutorial/    Screenshot, VideoPlaceholder, Steps, ...  W6
  content/
    tutorial/*.mdx, legal/*.mdx                            W6
  lib/
    env.ts       the only place that reads process.env     W5 (W0 scaffold)
    session.ts, auth-client.ts                             W1
    ...                                                    W5
  server/
    commerce/    getBuyState, getLibrary                   W4
```

## Rules

- Server components by default. A client component only for interaction (buy area, filters, copy buttons, menus, dialogs, tutorial tabs).
- Content comes only from `@upskillzz/content/catalog`. Never import `@upskillzz/content` (root), `@upskillzz/entitlements`, `@upskillzz/payments` or `@upskillzz/db` into client components. Server code may use them.
- Catalog, skill and pack pages are statically generated. Don't read cookies or headers in them; the buy area fetches `/api/buy-state` from the browser.
- Route handlers validate input with Zod and return the error shape in `docs/contracts/http-routes.md`. Webhook and auth routes run on the Node runtime.
- Read config from `src/lib/env.ts` only. The MCP URL is rendered from the server; no `NEXT_PUBLIC_` secrets.
- "Claude" appears only as a word. No Anthropic or Claude logos or artwork. Footer says "Upskillzz is not affiliated with Anthropic."
- Store copy is for non-technical readers. Don't say "MCP" on store pages; say "connect Claude to Upskillzz".

## Design tokens (W5 defines in `globals.css`; W1 and W6 consume)

Clean, neutral, calm. Lots of white space, borders over shadows, one accent colour.

| Token (shadcn names) | Light | Dark |
|---|---|---|
| `--background` | `#FFFFFF` | `#0B0B0C` |
| `--foreground` | `#18181B` | `#FAFAFA` |
| `--muted` | `#F4F4F5` | `#18181B` |
| `--muted-foreground` | `#71717A` | `#A1A1AA` |
| `--border`, `--input` | `#E4E4E7` | `#27272A` |
| `--primary` (accent) | `#4338CA` | `#818CF8` |
| `--primary-foreground` | `#FFFFFF` | `#0B0B0C` |
| `--accent` (soft accent background) | `#EEF2FF` | `#1E1B4B` |
| `--success` | `#15803D` | `#4ADE80` |
| `--warning` | `#B45309` | `#FBBF24` |
| `--destructive` | `#B91C1C` | `#F87171` |
| `--radius` | `0.625rem` (cards); buttons and inputs one step smaller | |

- Type: Inter via `next/font` for everything; JetBrains Mono for commands and URLs. Body 16 px / 1.6. Headings semibold with slightly tight tracking. Scale: 14, 16, 18, 20, 24, 30, 36, 48.
- Layout: content max width 1120 px; gutters 24 px (16 px under 640 px); spacing on a 4 px grid, mostly multiples of 8.
- Icons: lucide-react, 1.5 px stroke, 16 or 20 px.
- Motion: short (150 to 200 ms) opacity and transform transitions only, disabled under `prefers-reduced-motion`.
- Theme follows the system setting.

W5 may refine values but must keep the token names, since W1's and W6's pages use them.

## Testing

Vitest with React Testing Library for components; route handler tests call the handler functions directly with a test database; Playwright smoke tests live in `e2e/` (W8). Run `pnpm --filter @upskillzz/web test`.

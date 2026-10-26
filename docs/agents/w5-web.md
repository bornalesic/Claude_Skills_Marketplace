# Brief: W5 website storefront

**Branch:** `ws/w5-web` · **Phase:** 1 · **Ports:** 3060 / 3061 · **DB:** `upskillzz_w5`

## Mission

Build the public face of Upskillzz: a clean, fast, trustworthy store that explains what Claude skills are to people who barely use Claude, lets them buy in a few clicks, and then gets them connected. Most buyers are not technical. Every page should answer "what do I get, and what do I do next?"

## Read first

- `docs/contracts/http-routes.md` (pages, buy-area states, library panel), `interfaces.md` (`PublicCatalog`, the "Inside apps/web" helpers, `claudeAddConnectorUrl`, `claudeCodeAddCommand`), `env.md`
- `docs/ARCHITECTURE.md` flow 1 and the performance notes, `docs/DECISIONS.md` D13
- `apps/web/CLAUDE.md` (structure, design tokens, rules)

## You own

Everything in `apps/web/**` that isn't owned by W1, W4 or W6 (see `docs/WORKSTREAMS.md`), including the design tokens in `src/app/globals.css`, `src/components/**` (except `components/tutorial/**`), layout, header and footer.

## Verify before building

Next.js (current stable): App Router, `generateStaticParams`, metadata API, `next/font`, static vs dynamic rendering, and whether Cache Components / partial prerendering is stable in the installed version. shadcn/ui and Tailwind for the installed versions. WCAG 2.2 AA basics.

## Stubs until others merge

| Need | From | Stub |
|---|---|---|
| `getCurrentUser`, `requireUser`, sign-in/out | W1 | Local versions in `src/lib/dev-session-stub.ts` returning a fixed user when `DEV_LOGIN_ENABLED=true`; keep W1's file names free |
| Public catalog | W3 | A fixture `PublicCatalog` in `src/lib/catalog-fixture.ts` matching the samples W3 plans (see `docs/agents/w3-content.md`), used only when `@upskillzz/content/catalog` throws "not built" |
| `getBuyState`, `getLibrary`, `/api/buy-state`, `/api/checkout`, `/api/claim`, `/api/orders/[id]` | W4 | Always call the real routes and helpers. In tests, mock `fetch` (for example with MSW) and the helper module. In the dev server, while the routes don't exist yet, the buy area shows a neutral "Purchases coming soon" state on a 404. Don't create files under W4's paths |

## Deliverables

1. **Design system.** Tokens in `globals.css` as specified in `apps/web/CLAUDE.md` (light and dark, following the system setting). shadcn/ui components themed with them. A small set of shared components: `SkillCard`, `PackCard`, `Price`, `CategoryBadge`, `CopyField` (value + copy button + "Copied" feedback), `CodeCommand` (monospace command with copy), `EmptyState`, `PageHeader`, `Callout`. W6 reuses `CopyField`, `CodeCommand` and `Callout` in the tutorial, so keep their props stable and documented.
2. **Layout.** Header: wordmark "Upskillzz" (text, no logo file yet), nav (Skills, Packs, Tutorial), sign-in button or user menu (Library, Sign out). Mobile menu. Footer: legal links, contact email placeholder, "Upskillzz is not affiliated with Anthropic."
3. **Home `/`:** hero ("Skills that make Claude better at your work", one-line explanation, buttons "Browse skills" and "How it works"); three steps (Buy a skill → Connect Claude once → Just ask Claude); featured skills (first six); "Works in Claude on the web, desktop, mobile and Claude Code" in text; short FAQ (what is a skill, which Claude plan do I need, what if it doesn't work for me) linking to the tutorial.
4. **Catalog `/skills`:** grid of `SkillCard`s; category chips and a search box filtering in the browser; URL reflects filters; empty state.
5. **Skill page `/skills/[slug]`:** title, summary, price, category, tags; outcomes; rendered `preview.md`; "Includes N reference files" and "Includes server tools" when relevant; works-with list; "Also in pack X (save €Y)"; buy area (client component calling `/api/buy-state`, all states in `http-routes.md`); waiver dialog with the contract text and a required checkbox; `POST /api/checkout` then redirect; free claim flow; JSON-LD `Product` with an `Offer` in EUR.
6. **Packs `/packs` and `/packs/[slug]`:** included skills as cards, total separate price and savings, buy area, partial-ownership notice.
7. **Library `/library`:** requires sign-in. Owned skills (title, version, short "Try asking Claude: ..." hint derived from the summary), the "Connect Claude" panel exactly as in `http-routes.md`, order history. Empty state pointing to the catalog.
8. **Checkout pages:** success polls `GET /api/orders/[id]` every 1.5 s for up to 30 s: pending → "Confirming your payment...", paid → "It's yours" with next steps (connect Claude if not yet, or start a new chat / refresh tools list), failed or expired → retry link. Cancel page with a way back.
9. **SEO and polish:** metadata per page, a static Open Graph image, `sitemap.xml` from the catalog, `robots.txt`, 404 and error pages, `GET /api/health` (contract).
10. **Accessibility:** keyboard navigation, focus rings, labelled controls, colour contrast AA in both themes, `prefers-reduced-motion` respected.
11. **Performance:** catalog, skill and pack pages statically generated; no client JavaScript beyond the buy area, filters, copy buttons and menus; images (if any) through `next/image`. Lighthouse mobile 90+ on home, catalog and a skill page.

## Rules

- Import content only from `@upskillzz/content/catalog`. Never import `@upskillzz/content`, `@upskillzz/entitlements` or `@upskillzz/db` in client components.
- Use "Claude" only as a word. No Anthropic or Claude logos or brand artwork.
- Write copy for non-technical readers. Avoid "MCP" on store pages; say "connect Claude to Upskillzz". The tutorial explains the details.

## Tests

Component tests for the buy area (every state), waiver dialog (can't continue unticked), catalog filtering, copy buttons; a Playwright smoke run of home → catalog → skill page → (dev login) → library. W8 builds the full E2E suite later.

## Acceptance checks

- Every page in `http-routes.md` that you own renders with sample content, in light and dark mode, at 375 px and 1280 px wide.
- With W1 and W4 merged: dev login, claim the free sample, buy a paid sample in Stripe test mode, and see both in the library.
- Lighthouse results recorded in your status file.

## Out of scope

Sign-in and consent pages (W1), API route logic (W4), tutorial and legal pages (W6).

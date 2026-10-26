# Brief: W6 tutorial and legal pages

**Branch:** `ws/w6-tutorial` · **Phase:** 2 (may start once W0 is merged) · **Ports:** 3070 / 3071 · **DB:** `upskillzz_w6`

## Mission

Most buyers have never connected anything to Claude. The tutorial must take someone from "I bought a skill" to "Claude used it" in under five minutes, on whichever Claude they use, without them needing to know what MCP is. Also draft the legal pages so a lawyer has something concrete to review.

## Read first

- `docs/contracts/mcp.md` (tool names and what Claude shows), `http-routes.md` (tutorial and legal routes, library "Connect Claude" panel), `interfaces.md` (`claudeAddConnectorUrl`, `claudeCodeAddCommand`)
- `docs/ARCHITECTURE.md` flows 2 and 3 (especially tool list freshness), `docs/DECISIONS.md` D6, D9, D13, `docs/LAUNCH_CHECKLIST.md`
- `apps/web/CLAUDE.md` (design tokens, shared components)

## You own

`apps/web/src/app/tutorial/**`, `apps/web/src/content/tutorial/**`, `apps/web/src/components/tutorial/**`, `apps/web/public/tutorial/**`, `apps/web/src/app/legal/**`, `apps/web/src/content/legal/**`.

## Verify before writing (and record dates)

Claude's interface and plans change. Check Anthropic's help center and docs at the time you write, and put a comment `{/* verified YYYY-MM-DD: <url> */}` next to each fact:

- Which Claude plans can add custom connectors, and any limit on the free plan: https://support.claude.com/en/articles/11503834-building-custom-connectors-via-remote-mcp-servers
- The exact steps and labels to add a custom connector on claude.ai, Claude Desktop and mobile, and how Team/Enterprise owners add one for their organization
- Whether the one-click link from `claudeAddConnectorUrl` opens the "add custom connector" dialog prefilled. If it doesn't, say so in your status file and write the manual steps only
- Claude Code: `claude mcp add --transport http upskillzz <MCP_URL>` and `/mcp` to sign in
- Where "Refresh tools list" lives for a connector in the desktop and mobile apps
- How tool permission prompts look ("Allow once" / "Always allow" or the current wording)

## Components (in `src/components/tutorial/`)

- `<Screenshot id="connect-web-01" alt="..." caption="..." />`: renders `/tutorial/<id>.png` (or `.webp`) when the file exists; otherwise a dashed 16:9 placeholder showing the id and the alt text as "Screenshot needed: ...". Checks existence at build time.
- `<VideoPlaceholder id="connect-web" title="..." src? poster? />`: a 16:9 block saying "Video coming soon" until `src` is set; then a lazy-loaded player (plain `<video>` for a file, or a privacy-friendly embed for YouTube/Vimeo). One per page, near the top.
- `<Steps>` / `<Step title>`: numbered steps.
- `<SurfaceTabs>`: tabs for Claude on the web / Desktop / Mobile / Claude Code, remembering the choice (localStorage, wrapped in try/catch).
- Reuse W5's `CopyField`, `CodeCommand` and `Callout`. Until W5 merges, write minimal local versions inside `components/tutorial/` and swap later.

## Pages (MDX in `src/content/tutorial/`, routed by `src/app/tutorial/`)

1. `/tutorial`: overview, "what you need" (a Claude plan that supports connectors, the Google account you bought with), a 3-step map, links to each step.
2. `what-are-skills`: Claude, skills, and Upskillzz in plain words; what happens when you ask Claude something; privacy (Upskillzz sees which skill Claude loaded and, for skills with server tools, the input Claude sends to those tools; it never sees the rest of your conversation).
3. `buy-your-first-skill`: browse, buy or claim free, where to find your library.
4. `connect-claude-web`: claude.ai, with screenshot slots for each click; the one-click link if it works.
5. `connect-claude-desktop-and-mobile`: same account, connector syncs or needs adding; "Refresh tools list".
6. `connect-claude-code`: the command (with `CodeCommand`), `/mcp` sign-in, how to check it worked.
7. `using-your-skills`: just ask; or name the skill; what the permission prompt means; how to tell a skill was used.
8. `after-you-buy-more`: new chat on the web; refresh tools list on desktop and mobile; or ask Claude to "load my <skill> skill from Upskillzz".
9. `troubleshooting`: "Couldn't reach the MCP server", sign-in loops, wrong Google account, tools missing, plan doesn't allow connectors, Team/Enterprise admin needs to add it, rate-limit message; each with a fix.
10. `faq`: refunds and the withdrawal waiver (plain words), updates to skills, using skills on several devices, sharing (not allowed), contact.

Use the library page's live values where possible: the MCP URL is read from env on the server and passed into MDX, never hard-coded.

Also produce `apps/web/src/content/tutorial/SCREENSHOTS.md`: a checklist of every `Screenshot` id, the page it's on, and exactly what to capture (which screen, which state, crop, light mode, 1600 px wide, blur personal data). Borna will take them.

## Legal drafts (MDX in `src/content/legal/`)

Terms of sale, privacy policy (GDPR: data we store, Google sign-in data, Stripe as processor, Neon and Fly as processors, retention, rights, contact), refund and withdrawal policy (digital content, consent to immediate access), skill license (personal or internal business use; no resale, redistribution, or sharing of delivered content), imprint (placeholders for business name, address, OIB, contact). Every page starts with a visible banner: "Draft: not yet reviewed by a lawyer." Keep the wording plain.

## Acceptance checks

- Every tutorial page renders with placeholders in light and dark mode on mobile and desktop; MDX type-checks; links are valid.
- `SCREENSHOTS.md` lists every slot; a test fails if a `Screenshot` id is missing from it.
- A non-technical reader can follow `/tutorial` start to finish (ask Borna to try it, or describe in your status file where they would need a screenshot most).
- Every fact about Claude's UI or plans has a verified-date comment.

## Out of scope

Store pages and components outside your folders (W5), auth and checkout behaviour.

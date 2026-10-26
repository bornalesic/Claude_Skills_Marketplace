# Contract: MCP server

Version 1.0 (2026-10-26)

What `apps/mcp` exposes to Claude. The tutorial (W6) and tests (W8) rely on these names and texts.

## Endpoint and protocol

- URL: `MCP_URL`, production `https://mcp.upskillzz.com/mcp`. This exact string is the OAuth resource identifier.
- Transport: Streamable HTTP, built with the official MCP TypeScript SDK v2.
- Protocol versions: accept **2026-07-28** (stateless) **and 2025-11-25**. Do not configure the SDK to reject legacy clients. Answer GET and DELETE on `/mcp` the way the SDK requires for the versions we accept.
- No server-side session store. Each request builds a fresh MCP server instance for the verified user.
- Server identity: name `upskillzz`, title `Upskillzz`, version from `apps/mcp/package.json`.
- Server instructions (sent in the handshake or discovery response):

  > Upskillzz gives you skills the user has bought. Each owned skill is a tool; call it before starting a matching task and follow the instructions it returns. If the user mentions a skill you have no tool for, call upskillzz_library, then upskillzz_load_skill.

- CORS on `/mcp` and the well-known routes: allow any origin, allow headers `Authorization`, `Content-Type`, `Mcp-Protocol-Version`, `Mcp-Session-Id`, `Mcp-Method`, `Mcp-Name`, `Last-Event-ID`; expose `WWW-Authenticate`, `Mcp-Session-Id`, `Mcp-Protocol-Version`. Check the SDK and spec for any headers this list misses.

## Other routes

| Route | Auth | Response |
|---|---|---|
| `GET /.well-known/oauth-protected-resource/mcp` | none | Protected resource metadata (below) |
| `GET /.well-known/oauth-protected-resource` | none | Same document |
| `GET /healthz` | none | `200 {"ok":true}` when the database answers within 1 s, else `503` |

## Authentication

Every `/mcp` request needs `Authorization: Bearer <access token>`.

Protected resource metadata:

```json
{
  "resource": "https://mcp.upskillzz.com/mcp",
  "authorization_servers": ["<AUTH_ISSUER>"],
  "scopes_supported": ["openid", "profile", "email", "offline_access", "skills"],
  "bearer_methods_supported": ["header"],
  "resource_name": "Upskillzz"
}
```

`resource` is `MCP_URL` and `authorization_servers` has exactly one entry, `AUTH_ISSUER`.

| Situation | Response |
|---|---|
| No token, malformed token, bad signature, wrong issuer, expired | `401` with `WWW-Authenticate: Bearer resource_metadata="<MCP origin>/.well-known/oauth-protected-resource/mcp", scope="openid profile email skills"` and a JSON-RPC error body |
| Valid token, wrong audience | `401`, same header, plus `error="invalid_token"` |
| Valid token without the `skills` scope | `403` with `WWW-Authenticate: Bearer error="insufficient_scope", scope="skills", resource_metadata="..."` |

Never return a `200` for an unauthenticated request; Claude only starts sign-in on a `401`.

Verification is local: JWKS fetched from `AUTH_JWKS_URL`, cached, refetched when a token has an unknown `kid`. Claims are in `docs/contracts/interfaces.md` (`AccessTokenClaims`).

## Tools

The tool list is computed per request from `listOwnedSkills(db, userId)` (cached in memory per user for 30 seconds). If the 2026-07-28 spec's caching utility applies to `tools/list`, mark the result as private to this user with a TTL of 30 seconds or less.

### 1. `upskillzz_library` (always present)

- Description: `Lists the Upskillzz skills this user owns and what each is for. Call it when the user asks which skills they have, or when a task might match a purchased skill that has no tool of its own here.`
- Input: `{}`
- Annotations: `readOnlyHint: true`, `idempotentHint: true`, `openWorldHint: false`
- Output (text):

  ```
  You own 3 Upskillzz skills:

  - Cold Email Writer (slug: cold-email-writer, tool: cold_email_writer) — Write short, specific B2B cold emails that get replies.
  - ...

  If one of these has no tool in this conversation, call upskillzz_load_skill with its slug.
  Browse more: https://upskillzz.com/skills
  ```

  With no skills: `You don't own any Upskillzz skills yet. Browse them at https://upskillzz.com/skills.` (links use `APP_URL`).

### 2. `upskillzz_load_skill` (always present)

- Description: `Loads the instructions for an Upskillzz skill the user owns, by slug. Use it when a skill from upskillzz_library has no tool of its own in this conversation, for example right after a purchase. Pass reference to load one of the skill's reference files.`
- Input: `{ slug: string (SLUG_RE), reference?: string (REFERENCE_NAME_RE) }`
- Annotations: as above
- Output: the skill delivery format below; for a reference, the reference format.
- Not owned or unknown: tool result with `isError: true` and text `You don't own "<slug>". It's available at <APP_URL>/skills/<slug>.` (unknown slug: `No Upskillzz skill called "<slug>".`)

### 3. One tool per owned skill

- Name: the skill's `tool_name`.
- Description: `[Upskillzz] <title>. <SKILL.md description> Call this before starting; it returns the instructions to follow.` Truncate the middle part so the whole description stays within 1,024 characters.
- Input: `{ reference?: string }`. When the skill has references, `reference` is an enum of their names.
- Annotations: `readOnlyHint: true`, `idempotentHint: true`, `openWorldHint: false`, `title: <title>`
- Output without `reference`: skill delivery format. With `reference`: reference format.
- Archived skills still appear for their owners.

### 4. One tool per action of an owned skill

- Name: `<tool_name>__<action name>`
- Description: `[Upskillzz · <skill title>] <action description>`
- Input: JSON Schema from the action's Zod input
- Annotations: `readOnlyHint: <action.readOnly>`, `openWorldHint: false`
- Execution: validate input with the action's Zod schema; run with `ctx = { userId, skillSlug, logger, signal }`; abort after 10 seconds.
- Output: if the action returns a string, one text item; otherwise a text item with pretty-printed JSON and `structuredContent` with the value.
- Errors: validation failure or thrown error → `isError: true` with a short message. Never include stack traces.

### Skill delivery format (text)

```
# <title> — Upskillzz skill (v<version>)

Follow these instructions for the user's current task.

<instructions_md>

---
Reference files for this skill (load one by calling <tool_name> with {"reference": "<name>"}):
- objection-handling: Objection handling cheatsheet
```

Omit the reference section when there are none. When the skill has actions, add: `Tools for this skill: <tool_name>__score — <description>`. When loaded through `upskillzz_load_skill`, the reference hint says to call `upskillzz_load_skill` with `{"slug": "<slug>", "reference": "<name>"}` instead.

### Reference format (text)

```
# <reference title> — reference for <skill title>

<body_md>
```

### Watermark hook

All paid text passes through `applyWatermark(text, { userId, skillSlug, kind: "instructions" | "reference" })` immediately before it is returned. In v1 it returns `text` unchanged.

## Limits and logging

- Rate limit per user: `RATE_LIMIT_PER_MIN` tool calls per minute (default 60), token bucket in memory per machine. Over the limit: `isError: true`, text `Upskillzz rate limit reached. Try again in a minute.`, outcome `rate_limited`.
- Every `tools/call` writes one `mcp_usage` row after responding, without delaying the response. Failures to log are logged, never surfaced.
- Logs never contain tokens, emails or paid text. Log `userId`, tool name, outcome, duration.

## Changelog

- 1.0 (2026-10-26): initial version.

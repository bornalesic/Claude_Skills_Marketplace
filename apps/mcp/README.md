# @upskillzz/mcp

The MCP server buyers connect Claude to (`https://mcp.upskillzz.com/mcp` in production).

It checks the buyer's access token, lists one tool per skill they own (plus `upskillzz_library` and `upskillzz_load_skill`), and returns a skill's instructions when Claude calls its tool. Skills with server-side logic get extra action tools that run here.

## Run

```bash
pnpm --filter @upskillzz/mcp dev     # on MCP_PORT, hot reload
pnpm --filter @upskillzz/mcp test
pnpm --filter @upskillzz/mcp build   # outputs dist/
```

Health check: `GET /healthz`. Spec: `docs/contracts/mcp.md`. Agent rules: `CLAUDE.md` in this folder.

## Try it

- MCP Inspector: `npx @modelcontextprotocol/inspector`, Streamable HTTP, `http://localhost:$MCP_PORT/mcp`
- Claude Code: `claude mcp add --transport http upskillzz-local http://localhost:$MCP_PORT/mcp`, then `/mcp` to sign in
- claude.ai and the Claude apps need a public HTTPS URL: use staging

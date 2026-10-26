# e2e/ — CLAUDE.md

Owner: **W8** (W0 creates the Playwright setup and one smoke test). Brief: `docs/agents/w8-qa.md`.

End-to-end tests of the whole stack: the buyer journey in the browser, the Claude connection through the MCP SDK client, and the content-leak scan of production build output.

## Rules

- Tests run against a locally started stack (web, MCP, Postgres with samples synced, `stripe listen`), never against production.
- Use the dev login for sign-in; never real Google accounts in automated tests.
- Each test creates its own users and data; no ordering dependencies between tests.
- Bugs found here are reported to the owning workstream through your status file. Don't fix their code.
- How to run everything goes in `docs/TESTING.md`.

# Contracts

These files define everything more than one workstream depends on. Agents build against them exactly, so that code written in parallel fits together when merged.

| Contract | Defines | Main producers | Main consumers |
|---|---|---|---|
| [database.md](database.md) | Tables, columns, enums, indexes, who writes what | W0, W1 | everyone |
| [interfaces.md](interfaces.md) | Exported functions and types of each package | package owners | apps |
| [mcp.md](mcp.md) | MCP endpoint, auth handshake, tools, outputs, errors | W2 | Claude, W8, W6 (tutorial wording) |
| [content-format.md](content-format.md) | Skill and pack folders, YAML fields, public vs paid fields | W3 | W2, W4, W5, Borna |
| [http-routes.md](http-routes.md) | Website pages and API routes, request and response shapes | W1, W4, W5, W6 | W5, W8 |
| [env.md](env.md) | Environment variables per app | W0 | everyone |

## Rules

1. Only the orchestrator edits contracts.
2. To change one, add an entry under "Contract change requests" in your status file: which file, the exact change, and why. Keep building against the current version until the board says it changed.
3. Every change bumps the version at the top of the file and adds a changelog line at the bottom. The orchestrator announces it on `docs/agents/BOARD.md`.
4. Additive changes (a new optional field, a new function) are preferred over breaking ones.
5. If the code and a contract disagree, the contract is right until changed, even if the code is better. Raise it.

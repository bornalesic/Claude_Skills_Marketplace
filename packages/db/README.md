# @upskillzz/db

Postgres schema (Drizzle ORM), migrations and client for Upskillzz.

```ts
import { createDb, schema } from "@upskillzz/db";
const { db, close } = createDb(process.env.DATABASE_URL!);
```

| Command | What it does |
|---|---|
| `pnpm db:up` / `pnpm db:down` | Start or stop local Postgres (Docker) |
| `pnpm db:push` | Apply the schema to your local database (development) |
| `pnpm db:generate` | Generate a migration (orchestrator, on main only) |
| `pnpm db:migrate` | Apply migrations (CI and deploys) |
| `pnpm db:reset` | Recreate your local database, push the schema, sync content |

Tables and rules: `docs/contracts/database.md`.

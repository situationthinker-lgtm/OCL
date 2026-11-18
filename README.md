# Office Cricket League — Beta 1.0

Private league management for office cricket. Next.js 15 (App Router, TypeScript), Tailwind v4, Prisma 7 + libSQL (SQLite locally, Turso hosted), JWT-cookie auth, Vitest. Deploys to Vercel — see `DEPLOY.md`.

## Run it

```bash
npm install            # also runs `prisma generate`
npm run db:setup       # migrate + seed
npm run dev            # http://localhost:3000
```

The database starts empty apart from one admin login: `admin@ocl.local` / `password123` (change it in Settings). Add players manually or via Admin → Import SimpleScorer.

Want sample data to poke at? `npm run db:seed:demo` on a fresh database adds 14 fictional players, 2 teams and a match (plus `manager@ocl.local` / `player@ocl.local` logins, same password).

Other commands: `npm test`, `npm run build && npm start`, `npm run db:migrate` (applies `prisma/migrations` to whatever `DATABASE_URL` points at, local or Turso), `npm run db:migrate:dev` (generate a new migration after editing `prisma/schema.prisma`).

## Layout

- `prisma/schema.prisma` — full data model. Strings instead of enums so the datasource can move to PostgreSQL by changing provider + adapter.
- `src/lib/ratings.ts` — rating engine; formulas and benchmarks in `CONFIG`, documented in the file header. League-specific, not validated assessments.
- `src/lib/leaderboards.ts` — leaderboard queries with minimum-participation thresholds (`MIN`) and the league table (2 pts win, 1 tie).
- `src/lib/teams.ts` — squad rules (size, category requirements, finalize checks).
- `src/lib/scorecard.ts` — scorecard schema + consistency validation; `src/lib/aggregate.ts` — applies/backs out a match's performances to career stats (approve = +1, reopen = −1, so re-approval never double counts).
- `src/lib/auth.ts` — sessions, `requireRole` guards, audit helper. `src/middleware.ts` is a coarse first pass; pages and actions re-check.
- `src/app/<page>/actions.ts` — server actions for all mutations. Zod-validated, transactional where several tables change.
- `src/lib/storage.ts` — image storage: Vercel Blob when `BLOB_READ_WRITE_TOKEN` is set, else `./uploads` served by `/api/uploads/...`.
- `src/test/` — integration tests run the real server actions against `prisma/test.db`.

## Rating calibration

Benchmarks in `CONFIG` (`src/lib/ratings.ts`) are tuned to OCL's 3–5 over matches (strike rates 100–280, economies 24→9, wickets rare). Derived attributes and OVR are league-scaled ×1.33 (`CONFIG.scale`). Fielding, consistency, strength, stamina and captaincy gain experience per match played (`CONFIG.experience`, capped at +30); batting and bowling are pure performance. Strength/stamina/captaincy stored in the DB are the admin baselines; experience is added at read time so recalculation never compounds. After editing any of this, Admin → *Recalculate all ratings*. Admin → *Assign categories by OVR* applies the bands in `CONFIG.categoryThresholds` (Gold 76+, Silver 66+); categories never change on their own.

## Importing from SimpleScorer

Admin → Import SimpleScorer: upload `simplescorer-backup.json`, review the preview, confirm. Only completed matches count; players are merged by name across SimpleScorer teams; unmatched names become Bronze free agents with a guessed role; existing OCL players get the imported history as their baseline with any approved OCL matches kept on top. Teams and matches are not imported. Mapping details in `src/lib/simplescorer.ts`.

## Defaults chosen

- Uploads: JPG/PNG/WebP, 25 MB max (raise `MAX_IMAGE_BYTES` and `serverActions.bodySizeLimit` together to change). Player cards have two modes: photo-in-card or custom full card artwork.
- Manual attributes (strength, stamina, captaincy) default to 50 and are labelled as manually assessed.
- Little data shrinks ratings toward a baseline so one big innings doesn't produce a 95.
- New players are always free agents; category never changes automatically.
- Matches: innings-level scoring. Draft → Completed (consistency-checked, winner set) → Approved by admin (stats + ratings + standings update once). "Reopen for correction" backs the stats out; re-approve re-applies. A match with a temporary side is always casual (individual stats only).
- Highest score on reopen: if the match equalled the player's HS, HS is recomputed from their other approved matches; an admin-entered baseline HS equal to that score would need re-entering.
- Squads: max 5; a finalized team needs 5 players with at least one Gold, Silver and Bronze. Finalized squads are locked until an admin reopens them.

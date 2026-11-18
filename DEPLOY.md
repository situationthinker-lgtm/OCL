# Deploying OCL (Turso + Vercel Blob + Vercel)

Everything below is free-tier. Total: three accounts, ~20 minutes.

## 0. Push the code to GitHub
```
cd ocl
git init && git add . && git commit -m "OCL beta"
```
Create an empty repo on github.com (private is fine), then:
```
git remote add origin https://github.com/<you>/ocl.git
git push -u origin main
```
`.gitignore` already keeps `.env`, `node_modules`, `prisma/*.db` and `uploads/` out of the repo.

## 1. Database — Turso
1. Sign up at https://turso.tech and install the CLI (https://docs.turso.tech/cli/installation). Run `turso auth login`.
2. Create the database **from your existing local file** so all your players, stats and photos' records come with it:
   ```
   turso db create ocl --from-file prisma/dev.db
   ```
   (For an empty database instead: `turso db create ocl`, then `DATABASE_URL=libsql://... DATABASE_AUTH_TOKEN=... npm run db:migrate` and `npm run db:seed`.)
3. Get the two values you'll need:
   ```
   turso db show ocl --url
   turso db tokens create ocl
   ```

## 2. Hosting — Vercel
1. Sign up at https://vercel.com with GitHub, click **Add New → Project**, import the `ocl` repo. Framework is auto-detected as Next.js; leave build settings alone.
2. Before the first deploy, open **Environment Variables** and add:
   | Name | Value |
   |---|---|
   | `DATABASE_URL` | the `libsql://…` URL from step 1 |
   | `DATABASE_AUTH_TOKEN` | the token from step 1 |
   | `AUTH_SECRET` | a long random string (`openssl rand -hex 32` or any password generator, 40+ chars) |
3. Deploy. You'll get a `https://ocl-xxxx.vercel.app` URL. Log in with your admin account.

## 3. Photos — Vercel Blob
1. In the Vercel project: **Storage → Create → Blob**, connect it to the project. This adds `BLOB_READ_WRITE_TOKEN` to the project's env vars automatically. Redeploy once (Deployments → ⋯ → Redeploy).
2. Move the photos you already uploaded locally into Blob (run on your PC, once):
   ```
   # in .env temporarily point DATABASE_URL / DATABASE_AUTH_TOKEN at Turso and paste BLOB_READ_WRITE_TOKEN
   npm run db:push-images
   ```
   New uploads from the live site go straight to Blob.

## 4. Afterwards
- **Custom domain**: Vercel project → Settings → Domains.
- **Code changes**: `git push` → Vercel rebuilds automatically.
- **Schema changes**: edit `prisma/schema.prisma`, run `npm run db:migrate:dev` locally to generate the migration, then `DATABASE_URL=libsql://… DATABASE_AUTH_TOKEN=… npm run db:migrate` to apply it to Turso, then push.
- **Backups**: `turso db shell ocl .dump > backup.sql` or just keep the Turso dashboard's point-in-time restore. Photos live in Blob.
- **Local dev** keeps working exactly as before with `file:./prisma/dev.db` and `./uploads`.

Netlify works with the same code and the same env vars (Netlify also auto-detects Next.js when connected to the repo); only the Blob storage is Vercel-specific — on Netlify you'd leave `BLOB_READ_WRITE_TOKEN` empty, which is not an option there because the filesystem isn't persistent, so Vercel is the recommended host.

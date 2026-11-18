#!/usr/bin/env bash
# OCL — one-shot local runner (macOS/Linux). chmod +x run.sh && ./run.sh
set -e
cd "$(dirname "$0")"
command -v node >/dev/null || { echo "Node.js not found. Install Node 20+ from https://nodejs.org"; exit 1; }
[ "$(node -v | cut -c2- | cut -d. -f1)" -ge 20 ] || { echo "Need Node 20+ (found $(node -v))"; exit 1; }

[ -d node_modules/next ] || { echo "Installing dependencies (first run)..."; npm install --no-audit --no-fund; }
[ -f .env ] || cp .env.example .env
[ -f src/generated/prisma/client.ts ] || npx prisma generate
if [ ! -f prisma/dev.db ]; then
  echo "Creating database + seed data..."
  npm run db:migrate
  npm run db:seed
else
  echo "Database already exists - keeping your data (delete prisma/dev.db to reset)."
fi
echo; echo "Starting OCL at http://localhost:3000  (Ctrl+C to stop)"
echo "Logins: admin@ocl.local / manager@ocl.local / player@ocl.local  - password: password123"; echo
(sleep 4; (xdg-open http://localhost:3000 || open http://localhost:3000) >/dev/null 2>&1) &
npm run dev

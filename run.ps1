# OCL — one-shot local runner (Windows). Right-click > Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File .\run.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Host "Node.js not found. Install Node 20+ from https://nodejs.org then re-run." -ForegroundColor Red; exit 1 }
$v = [int](node -v).TrimStart('v').Split('.')[0]
if ($v -lt 20) { Write-Host "Node $v found; need 20+." -ForegroundColor Red; exit 1 }

function Run($label, $cmd) {
  Write-Host $label -ForegroundColor Cyan
  Invoke-Expression $cmd
  if ($LASTEXITCODE -ne 0) { Write-Host "`n'$cmd' failed (exit $LASTEXITCODE). See the npm output above." -ForegroundColor Red; exit 1 }
}
if (-not (Test-Path node_modules\next)) { Run "Installing dependencies (first run, ~1-2 min)..." "npm install --no-audit --no-fund" }
if (-not (Test-Path .env)) { Copy-Item .env.example .env }

if (-not (Test-Path src\generated\prisma\client.ts)) { Run "Generating Prisma client..." "npx prisma generate" }

if (-not (Test-Path prisma\dev.db)) {
  Write-Host "Creating database + seed data..." -ForegroundColor Cyan
  npx prisma migrate deploy
  if ($LASTEXITCODE -ne 0) { Write-Host "Prisma engine download failed, using fallback migrator." -ForegroundColor Yellow; Run "Applying migrations..." "npm run db:migrate:fallback" }
  Run "Seeding sample data..." "npm run db:seed"
} else { Write-Host "Database already exists - keeping your data (delete prisma\dev.db to reset)." -ForegroundColor DarkGray }

Write-Host "`nStarting OCL at http://localhost:3000  (Ctrl+C to stop)" -ForegroundColor Green
Write-Host "Logins: admin@ocl.local / manager@ocl.local / player@ocl.local  - password: password123`n"
Start-Process "http://localhost:3000"
npm run dev

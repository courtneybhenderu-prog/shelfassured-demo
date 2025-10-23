# ShelfAssured — Demo Prototype

**Live demo:** https://courtneybhenderu-prog.github.io/shelfassured-demo/

Single-file prototype with multiple “screens” (sections) navigated by buttons and a Quick Nav dropdown.

## Quick start
- Open `index.html` in a browser, or host via GitHub Pages.
- Roles: Shopper, Client, Admin (use buttons on Splash).
- Data is stored locally via `localStorage` (no backend).

## Key screens
Splash (#screen1) • Create Account (#screen2) • Sign In (#screen3) • Shopper Dashboard (#screen4) • Job Details (#screen5) • Photo Capture (#screen6) • Analysis (#screen7) • Client Dashboard (#screen8) • My Jobs (#screen9) • Brands (#screen10) • Profile (#screen11) • Brand Bio (#screen12) • Client New Job (#screen13) • Admin Dashboard (#screen14) • Admin Users (#screen15) • Admin Jobs (#screen16) • Admin Support (#screen17) • Client Snapshot (#screen19) • Create Job Form (#screen20).

## Dev notes
- **Navigation:** `go('screenX')` scrolls to a section ID. Quick Nav (≡ Menu) opens a dropdown with page shortcuts.
- **Demo data:** Jobs and submitted price live in `localStorage` keys like `sa_last_price`, `sa_jobs_pool`.
- **Images:** Demo photos referenced by filename; user uploads are stored as data URLs in `localStorage`.

## Known quirks
- Price field accepts formats like `2.99` (numbers + optional decimal).
- All content is front-end only; refreshing clears some in-memory UI (persistent values live in `localStorage`).

## Repo layout
- `index.html` — all UI + JS
- `docs/UX-PLAN.md` — page-by-page behavior
- `CHANGELOG.md` — notable changes

## Troubleshooting & Playbooks

### Database Issues
- **[TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md)** - Complete guide for "relation 'jobs' does not exist" errors and SKU reuse issues
- **[PRODUCTION-FINALIZATION-CHECKLIST.md](./PRODUCTION-FINALIZATION-CHECKLIST.md)** - Step-by-step production hardening checklist

### Common Issues
- **Job creation fails with duplicate SKUs**: See troubleshooting guide for 3-way junction table solution
- **RLS permission errors**: Check RLS posture configuration in step3-rls-posture.sql
- **PostgREST cache issues**: Run step1-postgrest-reload.sql

### Quick Fixes
- **Schema reload**: `NOTIFY pgrst, 'reload schema';`
- **Health check**: Run `simple-smoke-test.sql` to verify system status
- **Production deployment**: Follow the 6-step checklist in PRODUCTION-FINALIZATION-CHECKLIST.md

# Force rebuild Fri Oct 10 18:17:28 CDT 2025

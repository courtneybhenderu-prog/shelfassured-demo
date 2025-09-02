# ShelfAssured — Progress Log

**Baseline date:** 2025-09-01
**Owner:** Courtney B.
**Purpose:** Single source of truth for what exists, how it works, and what’s next. Store this file in the repo root as `PROGRESS.md`.

---

## 1) Repo snapshot

* Repo: `shelfassured-demo`
* Live demo: GitHub Pages
* Primary file: `index.html` (single-file app: Tailwind CDN + vanilla JS + Inter font)
* Supporting docs present: `CHANGELOG.md`, `SCREENS.md`, `STATE.md`, `TEST-PLAN.md`, `README*.md`, `DEPLOY.md`
* Assets: demo images and logo

> Note: Navigation uses `go('screenX')` with `scrollIntoView`. No router or build step. State is stored in `localStorage`.

---

## 2) Core roles & flows (current)

* **Shopper**

  * Dashboard (#screen4): sees jobs grouped by store (from `sa_jobs_pool`).
  * Job Details (#screen5), Photo Capture (#screen6), Analysis (#screen7).
  * Submission writes `sa_last_photo`, `sa_last_price`, `sa_last_submitted_at`.
* **Client/Brand**

  * Dashboard (#screen8): map toggle (static image vs lightweight map iframe).
  * Create Job Form (#screen20): writes to `sa_jobs_pool`.
  * Snapshot (#screen19): printable report (print CSS hides everything else).
* **Admin**

  * Dashboard (#screen14) + Queues (#screen15–17).
  * Add Client (#screen21): saves brand objects into `sa_brands` and returns to Brands (#screen10).

---

## 3) Screens (IDs) — implemented

* \#1 Splash
* \#2 Create Account
* \#3 Sign In
* \#4 Shopper Dashboard
* \#5 Job Details
* \#6 Photo Capture
* \#7 Analysis
* \#8 Client Dashboard
* \#9 My Jobs
* \#10 Brands
* \#11 Profile
* \#12 Brand Bio
* \#13 Client Job Tiers (or older Client New Job)
* \#14 Admin Dashboard
* \#15 Admin Users
* \#16 Admin Jobs
* \#17 Admin Support
* \#19 Client Snapshot (print-only)
* \#20 Create Job Form
* \#21 Add Client

> Keep these IDs stable; other behaviors reference them.

---

## 4) LocalStorage keys — current

* `sa_earnings` — Shopper aggregate earnings
* `sa_jobs_completed` — Shopper completed count
* `sa_last_price` — Last submitted price string (validated `^[0-9]+(\.[0-9]{1,2})?$`)
* `sa_last_store` — Last store string
* `sa_last_brand` — Last brand string
* `sa_last_photo` — Data URL of last uploaded/captured photo
* `sa_last_submitted_at` — ISO timestamp of last submission
* `sa_jobs_pool` — Array of jobs `{ id, brand, store, notes, type, payoutCents }`
* `sa_current_job_*` — Working set for the active job detail flow
* `sa_brands` — Array of brand objects `{ name, logoUrl, contactName, contactEmail, defaultTasks[], notes }`

---

## 5) Notable behaviors (keep)

* **Create Job (#20)** builds a brand `<datalist>` from `sa_brands`.
* **Shopper Dashboard (#4)** groups jobs by `store` and shows payout from `payoutCents` (integer cents).
* **Client Snapshot (#19)** prints cleanly (only #19 visible in print/PDF via print CSS).
* **Quick Nav** is a non-sticky dropdown; navigation via `scrollIntoView`.

---

## 6) Constraints & guardrails

* Single file HTML (+ minimal assets).
* Tailwind via CDN only; vanilla JS; Inter font.
* No routing libraries; no heavy refactors.
* Additive changes only; preserve screen IDs and existing layout.
* Privacy: demo data only; no secrets; local-only storage.

---

## 7) Recent progress (today)

* Pushed docs and assets to GitHub repo; enabled GitHub Pages for live demo.
* Assembled multiple docs: CHANGELOG, SCREENS, STATE, TEST-PLAN (see repo).
* Confirmed demo flows for Shopper and Client.

> If you added more today, list bullet points here with commit short SHAs for traceability.

---

## 8) Open questions / decisions needed

* Do we standardize job **types** to: `standard` (48h), `rush` (6h), `launch` (bundle/24h)?
* Confirm **price validation** edge cases (e.g., inputs with `$`, commas). Current regex accepts `2.99` but not `$2.99`.
* Map toggle default state on Client Dashboard (#8)?
* Minimal brand fields for MVP vs nice-to-have (logo optional?).
* **Snapshot v2**: should it render dynamic data from completed jobs + analysis?
* **Backend storage**: do we need Supabase/Airtable for multi-user persistence now, or is localStorage fine for demo?

---

## 9) Next small wins (low-risk)

1. **Persist Quick Nav last selection** in `localStorage` (usability).
2. **Pre-fill Create Job** from the last used brand/store (speed to create).
3. **Empty state cards** for #4 and #10 (clear guidance when lists are empty).
4. **Print CSS check**: ensure only #19 prints; add a small print watermark date/time.

---

## 10) Acceptance criteria (general)

* Screen IDs unchanged; navigation works end-to-end.
* New features store state in `localStorage` using the keys above or additive new keys.
* No console errors on load or common flows.
* GitHub Pages build loads and renders all sections; print-only behavior verified for #19.

---

## 11) Morning Kick-off (9 AM)

* Start with **Admin → Add Client** flow to confirm brand saving works end-to-end.
* Next, run through **Create Job with the new brand** to verify datalist + Shopper Dashboard update.
* Then complete the **Shopper flow (end-to-end)** including Analysis + submission.
* Finally, open **Client Snapshot (#19)** and print/save to PDF to validate reporting.

## 12) To-Do for Tomorrow

### Ship the code

* [ ] Replace your GitHub Pages `index.html` with the latest file (`shelfassured-prototype-add-client-your-brands.txt` contents).
* [ ] Push/verify GitHub Pages builds successfully.

### Start fresh

* [ ] Clear demo state (in browser dev tools → Application/Storage → `localStorage.clear()`), then refresh.

### Admin → Add Client

* [ ] From Splash → Admin Login → Admin Dashboard (#14).
* [ ] Tap Add Client → fill in a test brand (name + optional logo/contact) → Save.
* [ ] Confirm it routes to Brands (#10) and a "Your client brands" card appears.

### Create Job with the new brand

* [ ] Go Client Login → Create New Job (#13 → #20).
* [ ] In Product / Brand, type and pick your new brand from the datalist suggestions.
* [ ] Enter a store (e.g., “H-E-B – …”), choose job type, add notes → Publish Job.
* [ ] Confirm it shows on Shopper Dashboard (#4) under the correct store header.

### Shopper flow (end-to-end)

* [ ] Tap the job → Job Details (#5) → enter a valid price (e.g., 2.99).
* [ ] Start Job (#6) → upload a photo or use Auto Demo → Use This Photo.
* [ ] Analysis (#7) → Analyze This Photo → Submit for Review.
* [ ] Check My Jobs (#9) shows updated statuses.

### Client reporting

* [ ] In Client Dashboard (#8), confirm Latest Reported Shelf Price and location updated.
* [ ] Open Client Snapshot (#19) → brand/store/price/date/photo/analysis are present.
* [ ] Print / Save PDF works (print CSS shows only the snapshot).

### Quick regression checks

* [ ] Quick Nav opens/closes without covering content while scrolling.
* [ ] Map Toggle on #8 switches between static and live.
* [ ] Price validation rejects bad inputs (e.g., 2.9a, \$2.999).

### Parking lot / nice-to-haves (queue up next)

* [ ] Add Edit/Delete for client brands + prevent duplicate names.
* [ ] Use brand default tasks to auto-prefill job instructions.
* [ ] Keep a history of snapshots (not just “last” values).
* [ ] Optional receipt upload (Buy & Try) experiment.
* [ ] Plan migration from localStorage → lightweight backend (Supabase/Airtable) so Marc & Courtney can use it across devices with real approvals.

---

## 12) How to update this log

* Add a **date-stamped** entry at the top of section 7 (“Recent progress”).
* Cross-link commits like: `2025-09-01 — Added STATE.md (commit abc123)`.
* Keep sections 3–6 evergreen; update when you add screens/keys.

---

*End of baseline.*

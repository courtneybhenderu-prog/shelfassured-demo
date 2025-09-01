# App State (localStorage)

## Persistent keys
- `sa_earnings` (number cents) — total (starts 1500)
- `sa_jobs_completed` (number) — completed count (starts 2)
- `sa_last_price` (string) — last submitted shelf price (e.g., "2.99")
- `sa_last_store` (string)
- `sa_last_brand` (string)
- `sa_last_photo` (data URL or path)
- `sa_last_submitted_at` (ms since epoch)
- `sa_jobs_pool` (array) — published jobs: `{ id, brand, store, notes, type, payoutCents }`

## Ephemeral / helper keys
- `sa_current_job_brand`, `sa_current_job_store`, `sa_current_job_payout`
- `sa_last_photo_name` — for demo analysis branch
- `sa_last_analysis_html` — injected into Snapshot

## Functions (map to UI)
- `go(id)` — scroll to screen; also closes Quick Nav
- `toggleMapMode()` — switches static ↔ live map on screen8
- **Jobs flow**
  - `setJob(brand, store, payoutCents)` → seeds details page
  - `getPriceValue()` → strips non-digits except dot
  - `submitJob()` → validates `/^[0-9]+(\.[0-9]{1,2})?$/`, stores price/brand/store, bumps earnings/jobs, → screen9
- **Photos & analysis**
  - `togglePhotoMode()`, `setDemoSet(v)`, `loadDemoPhoto()`
  - `proceedToAnalysis()` → screen7
  - `runVisionAnalysis()` → sets `sa_last_analysis_html`
  - `buildReportFromState()`, `injectReportAnalysis()` → fills screen19
- **Publishing**
  - `publishJob()` → writes to `sa_jobs_pool`, calls `renderJobsPool()`, returns to 4
  - `renderJobsPool()` → renders dynamic jobs on screen4

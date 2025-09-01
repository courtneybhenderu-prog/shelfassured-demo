# ShelfAssured — Prototype (Patched)

A single-file prototype (SPA) that simulates shopper, client, and admin flows inside a mobile frame. Navigation is vertical (one “screen” per section) with a floating **Quick Nav** dropdown for admins.

## What’s included
- Role splash + auth stubs (Screens 1–3)
- Shopper dashboard, job details, photo capture, analysis, submission (4–7)
- Client dashboard, printable snapshot (8, 19)
- Brands gallery + brand bio (10, 12)
- Admin dashboard + queues (14–17)
- Create job (tiers + full form) that publishes to “Jobs Near You” (13, 20)
- LocalStorage state, including price capture and simple earnings counter
- Top-right **≡ Menu** opens Quick Nav; closes on scroll or mask tap

## How to run
Open `index.html` in a browser, or deploy via GitHub Pages (root: `/index.html`).

## Primary controls
- **Quick Nav**: top-right `≡ Menu` → jump to any screen (admin convenience)
- **Taskbar**: on shopper pages (4, 9–11) to switch Dashboard/Jobs/Brands/Profile
- **Client**: “Create New Job” (13 → 20), “Open Client Snapshot” (8 → 19)
- **Print**: Snapshot page has “Print / Save PDF” and print CSS for #screen19 only

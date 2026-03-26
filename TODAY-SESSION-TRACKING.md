# Today's Session - Items to Track & Revisit

**Last updated:** March 25, 2026
**Session focus:** Landing page deployment, repo consolidation, Shelfer UX cleanup

## ✅ Completed Today

### Landing Page & Architecture (`beshelfassured.com`)
1. **Pushed redesigned landing page** to `shelfassured-landing` repo.
2. **Fixed broken hero image** — replaced with a pure CSS responsive phone mockup showing real app UI.
3. **Added grayscale logo ticker** — infinite scroll animation for retailer trust bar (H-E-B, Whole Foods, Kroger, etc.).
4. **Fixed mobile layout** — headline now appears above the phone mockup on mobile screens.
5. **Cleaned up typography** — removed awkward em-dash in the hero subheadline.
6. **Fixed double Sign In button** — resolved mobile display issue showing both desktop and mobile nav buttons.
7. **Cleaned up architecture** — `shelfassured-demo` root `index.html` now correctly redirects directly to the sign-in page instead of showing a stale landing page.

### Shelfer App Experience (`dashboard/shelfer.html`)
8. **Removed "Brands" tab** from the Shelfer bottom navigation (irrelevant to their workflow).
9. **Fixed "Loading..." bug** on the Shelfer Profile page header.
10. **Cleaned up Sign In page** — removed the unnecessary Back button and converted "Forgot Password" to a clean text link.
11. **Drafted Shelfer Experience Product Spec** — documented the planned gamification (tiers, feed, map) and payout mechanics.

---

## 🚨 High Priority Backlog (Next Session)

### 1. Lead Capture on Landing Page
**Issue:** The "Request Pilot Access" button on `beshelfassured.com` currently links directly to the sign-in page, losing potential leads.
**Action:** Restore the lead capture modal to collect Name, Company, Number of Stores, and Problem they are trying to solve. Send data to a Supabase `leads` table and/or email notification.

### 2. Google Sign-In Integration
**Issue:** Marc requested Google Sign-In as an auth option.
**Action:** Configure Supabase OAuth for Google and add the button to the `auth/signin.html` page.

### 3. Store Data Gap (Houston HEB Locations)
**Issue:** Missing store data for HEB locations in the Houston area.
**Action:** Identify missing stores and import them into the `stores` table.

### 4. OCA Duplicate Products Cleanup
**Issue:** Duplicate products exist in the database from OCA imports.
**Action:** Run the prepared SQL cleanup script to merge/remove duplicates.

### 5. Custom Domain for the App
**Issue:** The app currently lives at `courtneybhenderu-prog.github.io/shelfassured-demo`.
**Action:** Set up a custom subdomain (e.g., `app.beshelfassured.com`) pointing to the demo repo.

---

## 📅 Future / Deferred Items

### Admin Dashboard Mobile UX
- **Status:** Deferred.
- **Notes:** The current admin dashboard (`admin/dashboard.html`) is too cramped and busy for mobile use in-store. Needs a dedicated mobile UX overhaul (larger tap targets, simplified layout, fewer items visible at once) when time permits.

### Shelfer Experience Sprint
- **Status:** Spec drafted, ready for development.
- **Features:** 
  - Live activity feed ("X just made $Y")
  - Map view for available jobs
  - Gamified tier system (Shelf Starter → Verified Shelfer → Top Shelf)
  - Stripe Connect payout integration
  - Twilio SMS notifications for new jobs

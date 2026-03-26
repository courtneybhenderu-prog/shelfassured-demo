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

---

## 📌 Strategic Notes & Action Items (Marc & Courtney Meeting - March 25)

### Priority 1: Shelfer UX (Build Next)
1. **"Find It Next To" Field (High Priority):**
   - **Action:** Add a "What are 2 competitive brands in your set?" field to job creation.
   - **Display:** Surface this on the Shelfer job screen as a wayfinding cue (e.g., "Find it next to Slim Jim and Chomps").
   - **Value:** Dual purpose — helps Shelfers locate products faster and captures competitive intelligence.
2. **Category List Cleanup:**
   - **Action:** Remove junk entries ("Disco", "Department Key", "Bulk Grocery") from the database.
   - **Rule:** Categories remain in the system but are never required and never block submission.
   - **Next Step (Marc):** Validate remaining list against actual HEB aisle signs.
3. **Shared Shelfer Test Account:**
   - **Action:** Use one shared Shelfer login for all in-store testing to consolidate field data and build a realistic demo profile.

### Priority 2: CRM vs. Operational App (The "Mana Dashboard" Question)
- **Decision:** Do NOT split the app into two separate systems (CRM vs. Operational). The overhead is not worth it at this scale.
- **Action:** Add a lightweight "Prospect Pipeline" tab to the existing Admin dashboard.
- **Fields Needed:** Brand name, contact, outreach status (identified / contacted / demo scheduled / client), notes, last contacted date.

### Priority 3: Strategic Guardrails (What NOT to Build)
- ShelfAssured is an information gatherer and giver, NOT a solver.
- **Do NOT build:** Integrations with distributor dashboards, Walmart connectors, or AI agents that take actions on behalf of brands.
- **Goal:** Highlight the out-of-stock issue, but do not assume liability for fixing the underlying DSD/inventory problem.

### Priority 4: Demo Data Seeding
- **Issue:** The brand dashboard and admin views are currently empty, making demos less impactful.
- **Action:** Before pitching, seed the database with realistic demo data (a fake brand client, sample jobs, completed submissions, photos) so the platform looks alive and feels like a live, active product.

### 6. `beshelfassured.com/shelfer` — Shelfer Recruiting Page
**Issue:** The current landing page mixes brand messaging and Shelfer recruiting on one page. Shelfers need their own dedicated page with a completely different message.
**Action:** Build `beshelfassured.com/shelfer` as a standalone page targeting people who want to become Shelfers.
**Key elements:**
- Earnings calculator ("Visit 3 stores a week, earn up to $X/month")
- "What a job looks like" 3-step walkthrough (Accept → Audit → Get Paid)
- Tier system preview (Shelf Starter → Verified Shelfer → Top Shelf)
- "Apply to be a Shelfer" form → submits to a `shelfer_applications` table
- FAQ section for Shelfers
- Separate from brand messaging entirely

### 7. ShelfAssured LLC Formation
**Status:** In progress — wheels are in motion.
**Notes:** Currently operating as a DBA under Top of the Marc, LLC. Co-founder agreement also in progress. No action needed from the app side until entity is formalized.

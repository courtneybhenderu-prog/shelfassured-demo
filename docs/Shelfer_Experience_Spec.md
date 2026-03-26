# ShelfAssured: Shelfer Experience Product Spec

**Status:** Draft / Planned Sprint
**Target:** Shelfer mobile web app (`courtneybhenderu-prog.github.io/shelfassured-demo/dashboard/shelfer.html`)

This document outlines the planned enhancements for the Shelfer experience, based on competitive analysis and founder notes. The goal is to drive retention, create urgency, and build trust without over-complicating the frictionless "$3 while you shop" value proposition.

---

## 1. Core Navigation & Structure

The Shelfer experience will move to a clean, 4-tab bottom navigation structure, removing any brand-facing complexity.

| Tab | Purpose | Status |
|---|---|---|
| **Jobs** | Default view. List of available and active jobs, grouped by store. | Current |
| **Map** | Visual exploration of available jobs in the area. | **New** |
| **Feed** | Social proof activity stream ("X just made $Y"). | **New** |
| **Profile** | User details, tier status, and earnings/wallet. | Current (needs update) |

*(Note: The "Brands" tab has been removed from the Shelfer view as of March 2026).*

---

## 2. Gamification & Retention

To encourage consistent performance and dependability, a gamified tier system will be introduced. 

### The Shelf Tier System
Shelfers advance based on job volume and accuracy. Tiers are visible on their profile.

1. **Shelf Starter** (Entry) — Plays on "self-starter". New users getting going.
2. **Verified Shelfer** (Mid) — Established, trusted, consistent performers.
3. **Top Shelf** (Elite) — The highest tier. Unlocks the 30-minute early access window for new jobs before they hit the general pool.

### The Feed (Social Proof)
A live activity feed showing real-time earnings from other Shelfers. 
- *Example:* "Stephen W. just made $6.00 at H-E-B Memorial Dr — 1h ago"
- *Purpose:* Creates FOMO and validates that the platform actually pays out.

---

## 3. Job Execution Mechanics

The actual job execution remains lightweight (no ID verification, no background checks), but adds smart guardrails:

- **Auto-Expiration:** If a Shelfer accepts a job but does not complete it within 60 minutes (30 minutes for rush jobs), the job automatically returns to the available pool. No manual cancellation required.
- **Store Navigation:** A "Get Directions" button that opens the store address directly in Google Maps.
- **Flagging System:** A way for Shelfers to flag structural issues (e.g., "Store is closed", "Aisle inaccessible") distinct from the standard "Not Found" product status.

---

## 4. Onboarding & Marketing

The entry point for new Shelfers will be a dedicated landing page (`beshelfassured.com/shelfer`).

**Key Page Elements:**
- Earnings Calculator ("Visit 3 stores a week, earn up to $X/month")
- "What a job looks like" 3-step visual walkthrough
- FAQ specifically for Shelfers
- Sign Up / Apply button

---

## 5. Trust, Safety, & Payouts

- **Payout Infrastructure:** Weekly batch payouts via Stripe Connect every Friday.
- **Instant Payouts:** Shelfers can opt for instant payouts by absorbing the 1% Stripe processing fee.
- **SMS Notifications:** Job alerts via Twilio SMS (e.g., "New $3 job available at your local H-E-B"). SMS is preferred over push notifications for gig worker responsiveness.
- **Google Sign-In:** OAuth integration to lower the barrier to entry for new Shelfers.
- **Rating System:** Lightweight thumbs-up/down from Shelfers on job clarity; admin-only ratings on Shelfer quality (no public star ratings).

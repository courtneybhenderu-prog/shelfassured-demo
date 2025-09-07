# ShelfAssured — UX Plan & Wireframe Blueprint (v2)
**Version: 2025-09-07 • Status: MVP aligned (+ Future Roadmap)**

## Purpose
This document updates the original UX plan to reflect the current prototype and clarifies what is in the MVP vs. planned for future iterations. It covers the three primary journeys—**Gig Worker (on-demand rep network)**, Brand Client, and Administrator—with concrete screens, copy, and decision points.

---

## 1) Gig Worker Journey — From Job to Payout
Tone: friendly, direct, and confidence-building.

**Step 1: Dashboard (Home)**  
- Greeting, Jobs Near You, Total Income, Current Jobs, bottom taskbar (Dashboard / Jobs / Brands / Profile).  
- Tap a job → Job Details.  

**Step 2: Manual Location Confirmation (Modal)**  
- Pop-up explains need for location → button: “Confirm Location”.  
- If in range: proceed. If not: message to try again at the store.  

**Step 3: Job Details (Instructions + Price Confirmation) — UPDATED**  
- Elements: back button, product title, store name, payout (e.g., $3.00), instructions list.  
- **MVP:** “Confirm Shelf Price” field (typed from the shelf tag, e.g., 2.99).  
- Primary CTA standardized to “Start Job” (was “Claim This Gig”).  

**Step 4: Photo Capture**  
- Minimal camera UI / upload input.  
- **MVP (demo aid):** Upload ↔ Use Auto Demo toggle to load Pete’s Coffee sample photos (internal demo only).  

**Step 5: Analysis (Simulated)**  
- Loading state + friendly checklist (lighting, focus, product visible).  
- **MVP:** manual/human review post-submission.  
- **Future:** AI scoring + Shelf Presence Score.  

**Step 6: Post-Job Outcomes**  
- Success: “Job Complete! A human will review your submission…” + optional follow-ups.  
- Rejected: shows reason (e.g., blurry photo), Retry + Help triggers Admin support.  

**Profile & Motivation (Badges) — UPDATED**  
- **Planned for MVP demo (Top Shopper, Fast Responder),** but may roll into future iterations for full gamification (badge tiers, streaks).  

---

## 2) Brand Client Journey — From Creation to Insights

**Client Dashboard (MVP) — UPDATED**  
- Tiles & feed of recent audits.  
- **MVP:** Latest Reported Shelf Price + location.  
- **MVP:** Client Snapshot (printable 1-pager with brand, store, price, date, photos).  

**Client Dashboard (Future)**  
- Shelf Presence Score (AI/rules-based) + Narrative Insights.  
- Pricing across regions chart; OOS alerts; deeper planogram/facings metrics.  
- Optional Jobs Map (MVP = static/live toggle; Future = expanded filters).  

**Create Job — UPDATED**  
- **MVP:** Simple job creation form (#20) with brand datalist and payout.  
- **Future:** Guided form + job templates (Standard, Launch, Rush), auto-pricing, self-serve client submission.  

---

## 3) Administrator Journey — Control Center

**MVP (Now)**  
- Add Client (#21).  
- Create Job (#20).  
- Basic metrics: jobs created/completed.  
- Respond to Help (support path).  

**Future Iterations**  
- Approvals (jobs, users).  
- Client/product management.  
- Advanced analytics dashboard.  
- Chat-like support console.  

---

## MVP vs. Future — Scope Table

| Area / Feature          | MVP (Now) | Future Iteration |  
|--------------------------|-----------|------------------|  
| Worker — Job Details    | Start Job + typed shelf price | Dynamic payout logic; richer templates |  
| Worker — Camera         | Upload + Auto Demo toggle | On-device capture, CV hints |  
| Worker — Analysis       | Manual review | AI Shelf Presence Score, auto checks |  
| Worker — Post-Job       | Success + Retry/Help | Upsells, coupons, training |  
| Worker — Profile        | **Planned badges** | Full gamification (tiers, streaks) |  
| Client — Dashboard      | Latest Price + Snapshot | Insights, scoring, OOS alerts |  
| Client — Jobs Map       | Static ↔ live toggle | Filters, export |  
| Client — Create Jo

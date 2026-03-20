# ShelfAssured Post-Field-Test To-Do List
*March 20, 2026*

This document synthesizes the findings from the College Station field test, including app issues encountered, workflow observations, and feature requests captured in voice memos and videos.

## 1. Core Workflow Improvements

### 1.1 The "Anchor SKU" / Set Check Workflow
*Priority: High*
*Context:* Voice memos 128 and 129 highlight that the current "scan every SKU" default is not the ideal workflow for checking a set.
* **The Problem:** The app currently defaults to treating every SKU in a job as an individual assignment that needs a barcode scan.
* **The Solution:** Implement the "Anchor SKU" concept. Brands should be able to create a job for a "set" of SKUs (e.g., "Check these 4 SKUs out of my 9 total"). The Shelfer scans one Anchor SKU to verify they are at the right location, and then uses a checklist or photo capture to verify the presence of the rest of the set.
* **To-Do:**
    * Update Job Creation UI to support "Set Check" jobs vs. "Individual SKU" jobs.
    * Update Job Execution UI to show a checklist of expected SKUs for the set, with a single Anchor SKU scan.
    * Add a "Notes" field to the job execution form for Shelfers to communicate nuances (e.g., "Missing SKU X, but found SKU Y").

### 1.2 Faster "Scan & Go" Shadow Brand Creation
*Priority: High*
*Context:* Voice memo 130 emphasizes the need for a faster way to capture intelligence in the field without getting bogged down in data entry.
* **The Problem:** The current process of taking pictures and getting a product in as a shadow brand is too slow. The user wants to "scan and go and worry about the details later."
* **The Solution:** Create a streamlined "Quick Capture" mode.
* **To-Do:**
    * Build a "Quick Capture" UI that allows rapid scanning of a barcode, snapping a photo, and moving on.
    * Defer detailed data entry (category, price, exact name) to a later "Processing" or "Triage" queue in the Admin dashboard.
    * Ensure this rapid capture still grabs GPS coordinates automatically.

## 2. UI / UX Fixes & Refinements

### 2.1 Mobile Formatting & Scanner Issues
*Priority: High*
*Context:* Video IMG_8841 shows struggles with mobile formatting and the scanner not triggering properly for adding products.
* **The Problem:** "This mobile formatting is not working... It's not letting me scan all of them."
* **To-Do:**
    * Audit the `barcode-capture.html` and `job-details.html` pages specifically for mobile viewport issues (padding, button placement, keyboard overlap).
    * Investigate why the scanner sometimes fails to initialize or allows scanning of multiple items in sequence.
    * Fix the "Brand field should be higher" issue mentioned in the video.

### 2.2 GPS Reliability
*Priority: Medium (Addressed in-field, needs monitoring)*
*Context:* Voice memo 132 notes that "GPS worked on the job form... GPS did not work on the job creation form."
* **The Status:** A fix was deployed during the field test to implement high/low accuracy fallback and better error messages.
* **To-Do:**
    * Monitor GPS success rates in future tests.
    * Ensure the "Near Me" functionality on the job creation form is robust across different connection strengths.

## 3. Data Model & Logic Adjustments

### 3.1 Handling UPC Mismatches & Overrides
*Priority: Medium (Addressed in-field, needs refinement)*
*Context:* Encountered an issue where the Rambler box UPC in-store did not match the UPC in the system.
* **The Status:** An override button was added during the test.
* **To-Do:**
    * Review how overridden UPCs are handled in the database. Do they update the core SKU record, or just the assignment?
    * Ensure the product edit/save functionality in the brand dashboard reliably updates UPCs when manual correction is needed.

### 3.2 Shadow Brand vs. Client Brand Data Segregation
*Priority: Medium*
*Context:* Project knowledge reminds us that paying clients should not see unverified shadow brand data.
* **To-Do:**
    * Verify that the brand dashboard strictly filters data based on job completion status and client vs. shadow status.
    * Ensure the "bucket of photos" collected during quick capture does not bleed into client-facing views until verified.

## 4. Next Steps for Development

1.  **Review this list with Marc:** Confirm the "Anchor SKU" workflow aligns with his vision for the brand client experience.
2.  **Prioritize the "Quick Capture" mode:** This seems critical for the usability of the app as an intelligence-gathering tool.
3.  **Conduct a dedicated Mobile UI Audit:** Spend time testing the app specifically on various mobile screen sizes to fix the formatting issues identified in the videos.

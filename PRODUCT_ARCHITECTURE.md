# ShelfAssured: Product Architecture Document

**Version:** 1.1 (Revised)
**Date:** March 5, 2026
**Author:** Manus AI (as Tech Lead)

## 1. Introduction & Vision

This document serves as the master blueprint for the technical and product architecture of ShelfAssured. It consolidates all strategic context, defines the core components of the system, and outlines a clear development roadmap. All future work should align with this document.

**The Vision:** ShelfAssured is a retail visibility platform for emerging CPG brands. It provides trustworthy, verifiable evidence of how their products appear on retail shelves, enabling them to compete with larger, more established companies.

**The Strategy:** Begin with a founder-operated model to build a proprietary database of product and shelf data. This "Scan and Go" approach allows the founders to act as the primary users, capturing valuable data while simultaneously refining the core platform. Once the data foundation is solid, the platform will expand to onboard pilot brands and, eventually, a distributed network of "Shelfer" gig workers.

### 1.1. Core Principles

- **Human-Led, Technology-Assisted:** Prioritize reliable human workflows over complex, costly automation. AI should assist reporting, not data capture.
- **Trust Over Speed:** Data integrity and security are paramount. Brands must trust that their data is confidential and accurate.
- **Build for Founder Use First:** The initial priority is to build a high-speed, reliable tool for the founders to use in the field.
- **Single Source of Truth:** All data resides in Supabase. The application views are windows into this data, governed by strict role-based permissions.

### 1.2. Current Product Priority

To maintain focus, the development priorities are as follows:

1.  **Build the Catalog:** Build the product and brand catalog through the "Scan and Go" barcode capture workflow.
2.  **Stabilize Admin Workflow:** Ensure the admin review and submission workflow is stable and reliable.
3.  **Refine Brand Dashboard:** Provide a clean brand dashboard showing only approved, final results.
4.  **Introduce Shelfers:** Introduce gig worker workflows only after internal operations are proven.

---

## 2. User Roles & Permissions

The system is designed around three distinct user roles. Their permissions must be strictly enforced at the database level via Row Level Security (RLS).

| Role | Description | Key Permissions |
|---|---|---|
| **Admin** | Founders (Courtney & Marc). Have full system oversight. | **Can See:** All data across all brands, users, and jobs. <br> **Can Do:** Create/edit brands, products, stores, and jobs; review/approve submissions; manage users. |
| **Brand Client** | A representative from an onboarded CPG brand. | **Can See:** Only data related to their own `brand_id`. This includes their brand profile, their products, and the **final, approved results** of jobs they have commissioned. <br> **Can Do:** Edit their contact information, view completed job reports. |
| **Shelfer** | A gig worker who performs in-store audits. | **Can See:** Only jobs that are available or assigned to them. They see job details (store, product, instructions) but not brand-level strategic information. <br> **Can Do:** Accept available jobs, submit audit data (photos, notes), view their own earnings. |

---

## 3. Core Data Model & Architecture

This section reflects the refined data model, incorporating feedback to maintain the strengths of the existing schema while preparing for future growth.

### 3.1. Key Table Definitions

- **`brands`**: Represents a CPG brand.
  - `id` (PK)
  - `name`
  - `is_shadow` (boolean, `true` by default): Indicates if the brand is a "Shadow Brand" created by an Admin or a fully onboarded client.
  - `onboarding_date` (timestamp): Null for shadow brands, set when a brand is officially onboarded.
  - `created_source` (text): Tracks how the brand was created (e.g., `scan_capture`, `manual_admin`, `import`, `brand_onboarding`).

- **`products` & `skus` (Migration Strategy)**: The `products` table is the primary table for new data capture, using UPC as the key identifier. The `skus` table will be phased out over time through a controlled migration. For now, the "Scan and Go" tool writes to `products` and upserts to `skus` to ensure data consistency during the transition.

- **`stores`**: A unique retail location. The system must enforce store uniqueness based on a combination of `banner_id`, `address`, `city`, `state`, and `zip` to avoid duplicates.

- **`jobs`**: The core audit task.

- **`job_store_skus`**: The join table defining the specific work to be done. This structure is intentionally preserved for its granularity.
  - `job_id` (FK)
  - `store_id` (FK)
  - `sku_id` (FK)

- **`job_submissions`**: The data collected by a user. The existing validation fields are preserved for a robust audit trail.
  - `id` (PK)
  - `job_id` (FK)
  - `store_id` (FK)
  - `user_id` (FK)
  - `is_validated` (boolean)
  - `validated_by` (FK to `users.id`)
  - `validated_at` (timestamp)
  - `review_outcome` (text)

### 3.2. Technical & Storage Architecture

- **Frontend:** Vanilla JavaScript, HTML, CSS. No major framework migration at this time.
- **Backend:** Supabase (PostgreSQL, Auth, Storage).
- **Deployment:** GitHub Pages with GitHub Actions for CI/CD.
- **Barcode Scanning:** `html5-qrcode` library for fast, reliable, in-browser scanning.
- **Photo Storage:** All photos are stored in Supabase Storage following a strict naming convention to keep evidence organized:
  - **Path:** `job_submissions/{submission_id}/{photo_label}.jpg`
  - **Example:** `job_submissions/abc-123/shelf-context.jpg`

### 3.3. Data Isolation & Row Level Security (RLS)

Tenant data isolation is a non-negotiable security requirement. It will be enforced via Supabase RLS policies based on the following core rules:

- **Brand Client Access:** A user with the `brand_client` role can only query rows where the `brand_id` column matches their own `brand_id`.
- **Forbidden Data:** Brand clients must **never** be able to see data from other brands, any data related to shadow brands, or internal admin-only fields (e.g., `internal_notes`).

---

## 4. Key Workflows & Feature Roadmap

Development will proceed in focused sessions, prioritizing stability and the core founder workflow first.

### 4.1. The "Scan and Go" Product Capture Workflow (Complete)

This is the primary tool for the founders to build the database. It is now live.

1.  **Page:** `admin/barcode-capture.html`
2.  **Action:** Admin opens the page on their mobile device.
3.  **Scanner:** The `html5-qrcode` library activates the rear camera.
4.  **Scan:** Admin scans a product UPC.
5.  **Lookup:** The app queries the `products` and `skus` tables.
    - **If Found:** Autofill product name and brand.
    - **If Not Found:** Keep UPC field filled, allow Admin to type product name and create a brand. The new brand is automatically flagged as a **Shadow Brand** with `created_source: 'scan_capture'`.
6.  **Capture:** Admin takes photos and captures store location via GPS.
7.  **Save:** Data is saved to the `products` table and upserted to the `skus` table. The form clears, but the **store location is retained** for the next scan.

### 4.2. The Development Roadmap (Revised Session Plan)

This plan reflects the work completed and the refined priorities based on architectural review.

| Session | Title | Key Activities |
|---|---|---|
| **1** | **Security Lockdown** | **(Complete)** Removed hardcoded credentials, rotated JWT key, built CI/CD pipeline, fixed `config.js` injection. |
| **2** | **Barcode Scanner Refactor** | **(Complete)** Implemented the "Scan and Go" workflow with `html5-qrcode`, shadow brand logic, and GPS capture. |
| **3** | **Database Security (RLS)** | Write and apply Supabase RLS policies for all tables based on the roles and rules defined in this document. Ensure no cross-tenant data access is possible. |
| **4** | **Database Schema Migration** | Write and apply the Supabase migration script to add `is_shadow` and `created_source` to the `brands` table. Begin the formal process of phasing out the `skus` table. |
| **5** | **Critical Bug Fixes** | Address the highest-priority bugs from the GitHub Issues list, including #12 (blank pending jobs page) and the store system issues (#9, #11, #22, #25). |
| **6** | **Brand Onboarding & Dashboard** | Build the UI for converting a "Shadow Brand" to a full client. Refine the Brand Client dashboard to show only completed, approved job data. |
| **7** | **Shelfer Workflow MVP** | Stabilize the core Shelfer journey: view available jobs, accept a job, submit audit data. |

---

## 5. Conclusion

This document provides the architectural clarity needed to move forward. With the core "Scan and Go" data capture tool now operational, the next critical step is to secure the database with comprehensive RLS policies (Session 3). By following this roadmap, we can systematically transform the ShelfAssured MVP into a stable, secure, and scalable platform, ready for its first pilot clients.

# ShelfAssured Database Design Overview

**Last Updated:** Based on current codebase analysis  
**Purpose:** High-level mapping of database structure, relationships, and access patterns

---

## Core Tables

### `users`
**Purpose:** User accounts and authentication  
**Key Columns:**
- `id` (UUID, PK) - References `auth.users(id)`
- `email` (VARCHAR, UNIQUE)
- `full_name`, `phone`
- `role` (VARCHAR) - Values: `'admin'`, `'shelfer'`, `'brand_client'` (or `'contractor'`, `'client'` in older schemas)
- `is_active` (BOOLEAN)
- `approval_status` (VARCHAR) - `'pending'`, `'approved'`, `'rejected'`, `'suspended'`
- `created_at`, `updated_at`

**Relationships:**
- Referenced by: `brands.created_by`, `jobs.client_id`, `jobs.contractor_id`, `jobs.created_by`, `job_submissions.contractor_id`, `payments.contractor_id`, `notifications.user_id`, `help_requests.user_id`

---

### `brands`
**Purpose:** Brand/client companies that create jobs  
**Key Columns:**
- `id` (UUID, PK)
- `name` (VARCHAR, NOT NULL)
- `description`, `logo_url`
- `contact_email`, `contact_phone`
- `website`, `primary_email`, `address`, `phone` (from onboarding schema)
- `broker_name`, `broker_agreement`, `nda_status` (admin intelligence fields)
- `data_source`, `data_confidence`, `visibility` (JSONB)
- `is_active` (BOOLEAN)
- `created_by` (UUID, FK → `users.id`)
- `created_at`, `updated_at`

**Relationships:**
- One-to-many: `jobs.brand_id`, `skus.brand_id`, `products.brand_id`
- Many-to-many: `brand_products`, `brand_stores`

---

### `stores`
**Purpose:** Retail store locations where jobs are performed  
**Key Columns:**
- `id` (UUID, PK)
- `name` (TEXT) - Legacy display name
- `STORE` (TEXT, UPPERCASE) - **PRIMARY display name** (e.g., `"HEB - ALVIN"` or `"BIG 8 FOODS"`)
- `address`, `city`, `state`, `zip_code`
- `latitude`, `longitude` (DECIMAL)
- `phone` (VARCHAR)
- `metro`, `METRO` (TEXT) - Metro area name (legacy uppercase)
- `metro_norm` (TEXT) - Normalized metro for search
- `store_chain` (TEXT) - **Legacy field, do not use for filtering**
- `banner` (TEXT) - **Legacy field, do not use for filtering**
- `banner_id` (UUID, FK → `retailer_banners.id`) - **Use this for banner filtering**
- `retailer_id` (UUID, FK → `retailers.id`)
- `status` (TEXT) - `'verified'`, `'unverified'`
- `zip5` (TEXT, GENERATED) - First 5 digits of zip_code
- `state_zip` (TEXT, GENERATED) - `state || '-' || zip5`
- `is_active` (BOOLEAN)
- `created_by` (UUID, FK → `users.id`)
- `created_at`, `updated_at`

**Important Notes:**
- **Display name priority:** `STORE || name || 'Unknown Store'`
- **Chain filtering:** Use `STORE` column with pattern matching (e.g., `STORE ILIKE 'HEB - %'`), NOT `store_chain` or `banner`
- **Unique constraint:** `(banner_id, street_norm, city_norm, state, zip5)` prevents duplicates
- **Data distribution:** ~2,334 stores; 2,209 follow `"BANNER - CITY"` pattern, 125 are standalone banners

**Relationships:**
- Many-to-many: `job_stores`, `job_store_skus`, `brand_stores`
- One-to-many: `job_submissions.store_id`

---

### `skus` / `products`
**Purpose:** Product/SKU catalog (two tables exist, may be consolidated)  
**Key Columns (`skus`):**
- `id` (UUID, PK)
- `upc` (VARCHAR, UNIQUE, NOT NULL)
- `name` (VARCHAR, NOT NULL)
- `brand_id` (UUID, FK → `brands.id`)
- `category` (VARCHAR)
- `size`, `description`
- `image_url` (VARCHAR)
- `is_active` (BOOLEAN)
- `created_by` (UUID, FK → `users.id`)
- `created_at`, `updated_at`

**Key Columns (`products` - from onboarding schema):**
- `id` (UUID, PK)
- `brand_id` (UUID, FK → `brands.id`, NOT NULL)
- `name` (TEXT, NOT NULL)
- `identifier` (TEXT, NOT NULL) - UPC or temp code
- `variant`, `size`
- `suggested_retail_price` (NUMERIC)
- `image_url`, `category`
- `data_source`, `data_confidence`
- `created_at`
- **Unique constraints:** `(brand_id, name)`, `(brand_id, identifier)`

**Relationships:**
- Many-to-many: `job_skus`, `job_store_skus`, `brand_products`
- One-to-many: `job_submissions.sku_id`

---

### `jobs`
**Purpose:** Main job/work order entity  
**Key Columns:**
- `id` (UUID, PK)
- `title` (VARCHAR, NOT NULL)
- `description` (TEXT)
- `brand_id` (UUID, FK → `brands.id`)
- `client_id` (UUID, FK → `users.id`) - Brand client who created job
- `contractor_id` (UUID, FK → `users.id`) - Shelfer assigned to job
- `assigned_user_id` (UUID, FK → `users.id`) - Alternative to contractor_id
- `all_stores` (BOOLEAN) - If true, job applies to all active stores
- `payout_per_store` (DECIMAL, DEFAULT 5.00)
- `total_payout` (DECIMAL) - Generated or calculated
- `category` (VARCHAR) - Product category (72 categories)
- `job_type` (VARCHAR) - `'photo_audit'`, `'inventory_check'`, `'price_verification'`, `'shelf_analysis'`
- `instructions` (TEXT)
- `requirements` (JSONB)
- `status` (VARCHAR) - `'pending'`, `'assigned'`, `'in_progress'`, `'pending_review'`, `'completed'`, `'cancelled'`, `'rejected'`
- `priority` (VARCHAR) - `'low'`, `'normal'`, `'high'`, `'urgent'`
- `due_date` (TIMESTAMP WITH TIME ZONE)
- `started_at`, `completed_at` (TIMESTAMP WITH TIME ZONE)
- `created_by` (UUID, FK → `users.id`)
- `created_at`, `updated_at`

**Relationships:**
- Many-to-many: `job_stores`, `job_skus`, `job_store_skus`
- One-to-many: `job_submissions.job_id`, `payments.job_id`

**Job Discovery:**
- Shelfers discover jobs via `status IN ('pending', 'assigned')` and `contractor_id = auth.uid()`
- Brands view jobs via `brand_id` and `client_id = auth.uid()`
- Admins see all jobs

---

### `job_store_skus`
**Purpose:** 3-way junction table linking jobs × stores × SKUs (replaces separate `job_stores` + `job_skus`)  
**Key Columns:**
- `id` (UUID, PK)
- `job_id` (UUID, FK → `jobs.id`, ON DELETE CASCADE)
- `store_id` (UUID, FK → `stores.id`)
- `sku_id` (UUID, FK → `skus.id`)
- `status` (TEXT, DEFAULT 'pending')
- `created_at` (TIMESTAMP)
- **Unique constraint:** `(job_id, store_id, sku_id)`

**Relationships:**
- Links `jobs` → `stores` → `skus` in one table
- Used for job creation: one job can have multiple store-SKU combinations

---

### `job_stores` (Legacy)
**Purpose:** Many-to-many relationship between jobs and stores (may be superseded by `job_store_skus`)  
**Key Columns:**
- `id` (UUID, PK)
- `job_id` (UUID, FK → `jobs.id`, ON DELETE CASCADE)
- `store_id` (UUID, FK → `stores.id`)
- `created_at`
- **Unique constraint:** `(job_id, store_id)`

---

### `job_skus` (Legacy)
**Purpose:** Many-to-many relationship between jobs and SKUs (may be superseded by `job_store_skus`)  
**Key Columns:**
- `id` (UUID, PK)
- `job_id` (UUID, FK → `jobs.id`, ON DELETE CASCADE)
- `sku_id` (UUID, FK → `skus.id`)
- `created_at`
- **Unique constraint:** `(job_id, sku_id)`

---

### `job_submissions`
**Purpose:** Submissions from shelfers (photos, data) for job completion  
**Key Columns:**
- `id` (UUID, PK)
- `job_id` (UUID, FK → `jobs.id`, ON DELETE CASCADE)
- `store_id` (UUID, FK → `stores.id`)
- `sku_id` (UUID, FK → `skus.id`)
- `contractor_id` (UUID, FK → `users.id`) - Shelfer who submitted
- `submission_type` (VARCHAR) - `'photo'`, `'inventory_data'`, `'price_data'`, `'shelf_data'`
- `data` (JSONB) - Submission data/metadata
- `files` (JSONB) - Array of file URLs/metadata (stored in `job_submissions` storage bucket)
- `is_validated` (BOOLEAN, DEFAULT false)
- `validated_by` (UUID, FK → `users.id`)
- `validated_at` (TIMESTAMP WITH TIME ZONE)
- `validation_notes` (TEXT)
- `review_outcome` (TEXT) - `'approved'`, `'rejected'`, `'superseded'`, or NULL
- `submitted_at` (TIMESTAMP WITH TIME ZONE) - Alias for `created_at`
- `created_at`, `updated_at`

**Relationships:**
- Links to `jobs`, `stores`, `skus`, `users` (contractor)
- Storage: Photos stored in Supabase Storage bucket `job_submissions`

**Workflow:**
- Submission created → `is_validated = false`, `review_outcome = NULL`
- Admin approves → `is_validated = true`, `review_outcome = 'approved'`, job status → `'completed'`, payment created
- Admin rejects → `is_validated = false`, `review_outcome = 'rejected'`, job status → `'pending'`
- Multiple submissions → first approval marks others as `'superseded'`

---

### `payments`
**Purpose:** Payment records for completed job submissions  
**Key Columns:**
- `id` (UUID, PK)
- `job_id` (UUID, FK → `jobs.id`)
- `contractor_id` (UUID, FK → `users.id`) - Shelfer receiving payment
- `amount` (DECIMAL, NOT NULL) - From `jobs.payout_per_store`
- `currency` (VARCHAR, DEFAULT 'USD')
- `status` (VARCHAR) - `'pending'`, `'processing'`, `'completed'`, `'failed'`, `'cancelled'`
- `payment_method` (VARCHAR)
- `transaction_id` (VARCHAR)
- `processed_at` (TIMESTAMP WITH TIME ZONE)
- `created_at`, `updated_at`

**Relationships:**
- Created automatically when submission is approved via `approve_submission()` RPC
- One payment per job (guarded against duplicates)

---

### `notifications`
**Purpose:** In-app notifications for users  
**Key Columns:**
- `id` (UUID, PK)
- `user_id` (UUID, FK → `users.id`) - Recipient
- `type` (TEXT) - `'submission_approved'`, `'submission_rejected'`, etc.
- `title` (VARCHAR) - **OLD schema field**
- `message` (TEXT) - **OLD schema field**
- `data` (JSONB) - **OLD schema field**
- `payload` (JSONB) - **NEW schema field** (replaces title/message/data)
- `is_read` (BOOLEAN, DEFAULT false) - **OLD schema field**
- `read_at` (TIMESTAMP WITH TIME ZONE) - **NEW schema field** (replaces is_read)
- `created_at` (TIMESTAMP WITH TIME ZONE)

**Schema Note:**
- **Current state:** Uses OLD schema (`title`, `message`, `data`, `is_read`)
- **RPC functions:** `approve_submission()` and `reject_submission()` insert using OLD schema
- **Future:** May migrate to NEW schema (`type`, `payload`, `read_at`)

**Relationships:**
- Created by RPC functions when submissions are approved/rejected
- One notification per submission action

---

### `help_requests`
**Purpose:** User support messages and help requests  
**Key Columns:**
- `id` (UUID, PK)
- `user_id` (UUID, FK → `auth.users(id)`, ON DELETE CASCADE)
- `subject` (VARCHAR, NOT NULL)
- `message` (TEXT, NOT NULL)
- `priority` (VARCHAR, DEFAULT 'medium') - `'low'`, `'medium'`, `'high'`, `'urgent'`
- `status` (VARCHAR, DEFAULT 'open') - `'open'`, `'in_progress'`, `'resolved'`, `'closed'`
- `admin_response` (TEXT)
- `resolution_notes` (TEXT)
- `responded_at` (TIMESTAMP WITH TIME ZONE)
- `responded_by` (UUID, FK → `auth.users(id)`)
- `resolved_at` (TIMESTAMP WITH TIME ZONE)
- `resolved_by` (UUID, FK → `auth.users(id)`)
- `is_read` (BOOLEAN, DEFAULT false)
- `read_at` (TIMESTAMP WITH TIME ZONE)
- `created_at`, `updated_at`

**Relationships:**
- Users create their own requests
- Admins respond and resolve

---

## Junction Tables

### `brand_products`
**Purpose:** Many-to-many relationship between brands and products  
**Key Columns:**
- `id` (UUID, PK)
- `brand_id` (UUID, FK → `brands.id`, ON DELETE CASCADE)
- `product_id` (UUID, FK → `products.id`, ON DELETE CASCADE)
- `product_label` (TEXT) - Optional brand-specific display name
- `created_at`
- **Unique constraint:** `(brand_id, product_id)`

**Relationships:**
- Links brands to their product catalogs
- Used in brand onboarding and job creation

---

### `brand_stores`
**Purpose:** Many-to-many relationship between brands and stores  
**Key Columns:**
- `id` (UUID, PK)
- `brand_id` (UUID, FK → `brands.id`, ON DELETE CASCADE)
- `store_id` (UUID, FK → `stores.id`, ON DELETE CASCADE)
- `source` (TEXT, DEFAULT 'manual') - `'manual'`, `'csv'`, `'distributor'`, `'job'`
- `created_at`
- **Unique constraint:** `(brand_id, store_id)`

**Relationships:**
- Links brands to stores where their products are sold
- Used for job creation validation (warns if store not in `brand_stores`)

---

## Retailer/Banner System

### `retailers`
**Purpose:** Parent retailer companies (e.g., "Kroger", "Albertsons")  
**Key Columns:**
- `id` (UUID, PK)
- `name` (TEXT, UNIQUE, NOT NULL)

**Relationships:**
- One-to-many: `retailer_banners.retailer_id`, `stores.retailer_id`

---

### `retailer_banners`
**Purpose:** Banner/chain names within retailers (e.g., "Tom Thumb" under "Kroger")  
**Key Columns:**
- `id` (UUID, PK)
- `retailer_id` (UUID, FK → `retailers.id`, NOT NULL)
- `name` (TEXT, NOT NULL) - Banner name (e.g., "Tom Thumb", "H-E-B")
- **Unique constraint:** `(retailer_id, name)`

**Relationships:**
- One-to-many: `stores.banner_id`, `retailer_banner_aliases.banner_id`

---

### `retailer_banner_aliases`
**Purpose:** Fuzzy matching aliases for banner names (e.g., "heb" → "H-E-B")  
**Key Columns:**
- `alias` (TEXT, PK) - Lowercase alias (e.g., `'heb'`, `'h-e-b'`)
- `banner_id` (UUID, FK → `retailer_banners.id`, NOT NULL)

**Relationships:**
- Used during store import/matching to normalize banner names

---

## User Roles

**Role Values:**
- `'admin'` - Full system access, can view/manage all data
- `'shelfer'` - Contractors who complete jobs (formerly `'contractor'`)
- `'brand_client'` - Brand clients who create jobs (formerly `'client'`)

**Role Storage:**
- Stored in `users.role` column
- Also referenced in `auth.users` metadata (JWT claims)

**Role-Based Access:**
- **Admins:** Full CRUD on all tables
- **Brand Clients:** Read own brand data, create jobs for own brand, view own jobs/submissions
- **Shelfers:** View assigned jobs, create submissions, view own payments/notifications

---

## Row Level Security (RLS) Policies

**Current State:** RLS is **mostly disabled** for stability during development. Application-layer enforcement is used instead.

### RLS Enabled Tables:
- `job_submissions` - Shelfers see own submissions, admins see all
- `help_requests` - Users see own requests, admins see all
- `notifications` - Users see own notifications
- `brand_products` - Admins see all, brand users see own brand's products
- `brand_stores` - Admins see all, brand users see own brand's stores

### RLS Disabled Tables:
- `users` - **Disabled** (was causing recursion issues)
- `brands` - **Disabled** (application-layer enforcement)
- `stores` - **Disabled** (application-layer enforcement with search-first pattern for brands)
- `jobs` - **Partially enabled** (varies by deployment)
- `job_store_skus` - **Disabled** (stabilization phase)
- `skus` / `products` - **Disabled** (application-layer enforcement)
- `payments` - **Disabled** (application-layer enforcement)

### Application-Layer Enforcement:
- **Store Visibility:**
  - Admins: Full access to all stores, can load without search
  - Brands: Search-first pattern enforced, cannot see full store lists
  - Shelfers: No store browser, only see stores via jobs
- **Job Visibility:**
  - Shelfers: See jobs where `contractor_id = auth.uid()` and `status IN ('pending', 'assigned')`
  - Brands: See jobs where `brand_id` matches their brand and `client_id = auth.uid()`
  - Admins: See all jobs

---

## Job Discovery Flow

**Tables Powering Job Discovery:**
1. **`jobs`** - Main job entity with `status`, `brand_id`, `contractor_id`, `client_id`
2. **`job_store_skus`** - Links jobs to specific store-SKU combinations
3. **`stores`** - Store location data for job display
4. **`skus`** / `products`** - Product information for job display
5. **`brands`** - Brand information for job display

**Discovery Queries:**
- **Shelfer:** `SELECT * FROM jobs WHERE contractor_id = auth.uid() AND status IN ('pending', 'assigned', 'in_progress')`
- **Brand:** `SELECT * FROM jobs WHERE brand_id = :brand_id AND client_id = auth.uid()`
- **Admin:** `SELECT * FROM jobs` (all jobs)

**Status Flow:**
- `pending` → Job created, not yet assigned
- `assigned` → Job assigned to shelfer
- `in_progress` → Shelfer started working
- `pending_review` → Submission created, awaiting admin review
- `completed` → Submission approved, job done
- `rejected` → Submission rejected, job returns to `pending`
- `cancelled` → Job cancelled

---

## Store/Location Data

**Primary Table:** `stores`

**Location Fields:**
- `address` (TEXT) - Street address
- `city` (TEXT) - City name
- `state` (TEXT) - State abbreviation
- `zip_code` (TEXT) - Full ZIP code
- `zip5` (TEXT, GENERATED) - First 5 digits of ZIP
- `state_zip` (TEXT, GENERATED) - `state || '-' || zip5` (e.g., `'TX-77001'`)
- `latitude`, `longitude` (DECIMAL) - GPS coordinates
- `metro`, `METRO` (TEXT) - Metro area name
- `metro_norm` (TEXT) - Normalized metro for search

**Banner/Chain Fields:**
- `STORE` (TEXT, UPPERCASE) - **PRIMARY display name** (e.g., `"HEB - ALVIN"`)
- `banner_id` (UUID) - **Use this for filtering** (FK → `retailer_banners.id`)
- `retailer_id` (UUID) - Parent retailer (FK → `retailers.id`)
- `store_chain` (TEXT) - **Legacy, do not use**
- `banner` (TEXT) - **Legacy, do not use**

**Store Display:**
- **Display name:** `STORE || name || 'Unknown Store'`
- **Chain extraction:** Parse `STORE` column (pattern: `"BANNER - CITY"` or standalone `"BANNER"`)
- **Filtering:** Use `STORE ILIKE 'BANNER - %'` or `banner_id = :banner_id`

**Data Distribution:**
- ~2,334 total stores
- 2,209 stores follow `"BANNER - CITY"` pattern
- 125 stores are standalone banners (no `" - "` in `STORE`)
- 72 unique chains/banners

---

## Key Relationships Summary

```
users
  ├── brands (created_by)
  ├── jobs (client_id, contractor_id, created_by)
  ├── job_submissions (contractor_id)
  ├── payments (contractor_id)
  ├── notifications (user_id)
  └── help_requests (user_id)

brands
  ├── jobs (brand_id)
  ├── skus (brand_id)
  ├── products (brand_id)
  ├── brand_products (brand_id)
  └── brand_stores (brand_id)

jobs
  ├── job_store_skus (job_id)
  ├── job_stores (job_id) [legacy]
  ├── job_skus (job_id) [legacy]
  ├── job_submissions (job_id)
  └── payments (job_id)

stores
  ├── job_store_skus (store_id)
  ├── job_stores (store_id) [legacy]
  ├── job_submissions (store_id)
  ├── brand_stores (store_id)
  └── retailer_banners (banner_id)

skus / products
  ├── job_store_skus (sku_id)
  ├── job_skus (sku_id) [legacy]
  ├── job_submissions (sku_id)
  └── brand_products (product_id)

retailers
  └── retailer_banners (retailer_id)

retailer_banners
  ├── stores (banner_id)
  └── retailer_banner_aliases (banner_id)
```

---

## Storage Buckets

**`job_submissions`** - Stores submission photos/files
- **RLS:** Shelfers can upload, admins can read
- **Path pattern:** `{submission_id}/{filename}`

**`brand_logos`** - Stores brand logo images
- **RLS:** Admins can upload, all authenticated users can read
- **Path pattern:** `{brand_id}/{filename}`

---

## RPC Functions

### `approve_submission(p_submission_id, p_admin_id, p_notes)`
- Marks submission as approved
- Creates payment record
- Updates job status to `'completed'`
- Marks other submissions as `'superseded'`
- Creates notification for shelfer

### `reject_submission(p_submission_id, p_admin_id, p_notes)`
- Marks submission as rejected
- Updates job status to `'pending'`
- Creates notification for shelfer with rejection reason

---

## Notes

1. **Schema Evolution:** Some tables have legacy columns (`store_chain`, `banner`) that should not be used. Always use `STORE` column and `banner_id` for filtering.

2. **Dual Product Tables:** Both `skus` and `products` exist. `products` is from onboarding schema, `skus` is from main schema. May need consolidation.

3. **RLS Strategy:** RLS is disabled for most tables during development. Application-layer enforcement is used instead, especially for store visibility.

4. **Job Creation:** Jobs are created with one record per store-SKU combination in `job_store_skus` table.

5. **Submission Workflow:** Submissions move jobs from `pending` → `pending_review` → `completed` (approved) or back to `pending` (rejected).

6. **Notifications Schema:** Currently uses OLD schema (`title`, `message`, `data`, `is_read`). RPC functions insert using this schema. Future migration to NEW schema (`type`, `payload`, `read_at`) is possible.


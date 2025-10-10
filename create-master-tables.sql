-- STEP 3: Create master data tables and junction tables
-- Run this in Supabase SQL editor

-- Create brands table
CREATE TABLE IF NOT EXISTS public.brands (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create stores table
CREATE TABLE IF NOT EXISTS public.stores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    address text,
    city text NOT NULL,
    state text NOT NULL,
    zip_code text,
    phone text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create skus table
CREATE TABLE IF NOT EXISTS public.skus (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    brand_id uuid REFERENCES public.brands(id),
    category text,
    barcode text UNIQUE,
    size text,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create job_skus junction table
CREATE TABLE IF NOT EXISTS public.job_skus (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id) ON DELETE CASCADE,
    quantity_expected integer DEFAULT 1,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(job_id, sku_id)
);

-- Create job_stores junction table
CREATE TABLE IF NOT EXISTS public.job_stores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    store_id uuid REFERENCES public.stores(id) ON DELETE CASCADE,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(job_id, store_id)
);

-- Verify tables were created
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('brands', 'stores', 'skus', 'job_skus', 'job_stores') ORDER BY table_name;

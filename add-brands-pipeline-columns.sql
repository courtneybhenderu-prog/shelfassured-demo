-- Add pipeline-related columns to brands table for Prospect Pipeline tab
-- Run in Supabase SQL Editor

ALTER TABLE public.brands
  ADD COLUMN IF NOT EXISTS contact_name    TEXT,
  ADD COLUMN IF NOT EXISTS last_contacted  DATE,
  ADD COLUMN IF NOT EXISTS outreach_notes  TEXT;

-- pipeline_stage should already exist; add it if not
ALTER TABLE public.brands
  ADD COLUMN IF NOT EXISTS pipeline_stage  TEXT DEFAULT 'prospect'
  CHECK (pipeline_stage IN ('scanned','prospect','contacted','pitched','demo_scheduled','converted','active_client'));

-- is_shadow should already exist; add it if not
ALTER TABLE public.brands
  ADD COLUMN IF NOT EXISTS is_shadow BOOLEAN DEFAULT true;

-- internal_notes should already exist; add it if not
ALTER TABLE public.brands
  ADD COLUMN IF NOT EXISTS internal_notes TEXT;

COMMENT ON COLUMN public.brands.contact_name   IS 'Primary contact person at this brand';
COMMENT ON COLUMN public.brands.last_contacted IS 'Date we last reached out to this prospect';
COMMENT ON COLUMN public.brands.outreach_notes IS 'Notes on outreach history and next steps';
COMMENT ON COLUMN public.brands.pipeline_stage IS 'CRM pipeline stage for this brand';

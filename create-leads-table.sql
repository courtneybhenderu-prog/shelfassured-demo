-- Create leads table for general pilot access form submissions
-- Separate from pilot_leads (which is for $10 demo bookings)
-- Run in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS public.leads (
    id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL,
    company     TEXT NOT NULL,
    num_stores  TEXT,                          -- e.g. "1-5", "6-20", "100+"
    problem     TEXT,
    source      TEXT DEFAULT 'pilot_access_form',
    status      TEXT DEFAULT 'new'
                CHECK (status IN ('new', 'contacted', 'qualified', 'converted', 'closed')),
    notes       TEXT,                          -- internal admin notes
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_leads_email      ON public.leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_status     ON public.leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON public.leads(created_at);

-- Enable RLS
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

-- Anyone can insert (landing page form is unauthenticated)
CREATE POLICY "Anyone can insert leads"
ON public.leads FOR INSERT WITH CHECK (true);

-- Only admins can read / update
CREATE POLICY "Admins can view all leads"
ON public.leads FOR SELECT
USING (public.is_admin());

CREATE POLICY "Admins can update leads"
ON public.leads FOR UPDATE
USING (public.is_admin());

-- Permissions
GRANT ALL ON public.leads TO authenticated;
GRANT ALL ON public.leads TO service_role;
GRANT INSERT ON public.leads TO anon;

-- updated_at trigger (reuse existing function if it exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'update_leads_updated_at'
  ) THEN
    CREATE TRIGGER update_leads_updated_at
    BEFORE UPDATE ON public.leads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

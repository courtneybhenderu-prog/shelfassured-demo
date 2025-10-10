-- Create pilot_leads table for landing page form submissions
-- Run this in your Supabase SQL editor

CREATE TABLE IF NOT EXISTS public.pilot_leads (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    company TEXT NOT NULL,
    role TEXT NOT NULL,
    phone TEXT,
    problem TEXT NOT NULL,
    store_count TEXT,
    biggest_challenge TEXT,
    message TEXT,
    status TEXT DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'qualified', 'converted', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.pilot_leads ENABLE ROW LEVEL SECURITY;

-- Create policies for pilot_leads
CREATE POLICY "Anyone can insert pilot leads"
ON public.pilot_leads
FOR INSERT
WITH CHECK (true);

CREATE POLICY "Admins can view all pilot leads"
ON public.pilot_leads
FOR SELECT
USING (public.is_admin());

CREATE POLICY "Admins can update pilot leads"
ON public.pilot_leads
FOR UPDATE
USING (public.is_admin());

-- Grant permissions
GRANT ALL ON public.pilot_leads TO authenticated;
GRANT ALL ON public.pilot_leads TO service_role;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pilot_leads_email ON public.pilot_leads(email);
CREATE INDEX IF NOT EXISTS idx_pilot_leads_status ON public.pilot_leads(status);
CREATE INDEX IF NOT EXISTS idx_pilot_leads_created_at ON public.pilot_leads(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_pilot_leads_updated_at 
    BEFORE UPDATE ON public.pilot_leads 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add missing internal_notes column
ALTER TABLE brands ADD COLUMN IF NOT EXISTS internal_notes text;



-- Add report_sent_at column to job_submissions
-- Run this in the Supabase SQL editor

ALTER TABLE job_submissions
ADD COLUMN IF NOT EXISTS report_sent_at TIMESTAMPTZ DEFAULT NULL;

COMMENT ON COLUMN job_submissions.report_sent_at IS 'Timestamp when the PDF report was sent to the brand. NULL means not yet sent.';

-- ========================================
-- Review Submissions MVP - Database Setup (SPLIT VERSION)
-- Run each section separately if you get errors
-- ========================================

-- ========================================
-- PART 1: Create notifications table
-- ========================================
CREATE TABLE IF NOT EXISTS notifications (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL,
  type          text NOT NULL,
  payload       jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at    timestamptz NOT NULL DEFAULT now(),
  read_at       timestamptz
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications (user_id, created_at DESC);

-- ========================================
-- PART 2: Add review_outcome column
-- ========================================
ALTER TABLE job_submissions
ADD COLUMN IF NOT EXISTS review_outcome text
CHECK (review_outcome IN ('approved','rejected','superseded') OR review_outcome IS NULL);

-- ========================================
-- PART 3: APPROVE submission RPC
-- Run this separately
-- ========================================
CREATE OR REPLACE FUNCTION approve_submission(p_submission_id uuid, p_admin_id uuid, p_notes text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_job_id uuid;
  v_contractor_id uuid;
  v_amount numeric;
  v_store_id uuid;
  v_sku_id uuid;
BEGIN
  PERFORM 1 FROM job_submissions WHERE id = p_submission_id FOR UPDATE;

  SELECT
    js.job_id,
    js.contractor_id,
    COALESCE(js.store_id, j.store_id) AS store_id,
    COALESCE(js.sku_id, j.sku_id)     AS sku_id,
    j.payout_per_store
  INTO
    v_job_id, v_contractor_id, v_store_id, v_sku_id, v_amount
  FROM job_submissions js
  JOIN jobs j ON j.id = js.job_id
  WHERE js.id = p_submission_id;

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Submission % not found or missing job', p_submission_id;
  END IF;

  UPDATE job_submissions
  SET is_validated      = true,
      validated_by      = p_admin_id,
      validated_at      = now(),
      validation_notes  = COALESCE(p_notes, validation_notes),
      review_outcome    = 'approved'
  WHERE id = p_submission_id;

  UPDATE job_submissions
  SET review_outcome = 'superseded'
  WHERE job_id = v_job_id
    AND id <> p_submission_id
    AND review_outcome IS DISTINCT FROM 'approved';

  UPDATE jobs
  SET status = 'completed'
  WHERE id = v_job_id;

  IF NOT EXISTS (
    SELECT 1 FROM payments
    WHERE job_id = v_job_id
      AND contractor_id = v_contractor_id
      AND status IN ('pending','processing','completed')
  ) THEN
    INSERT INTO payments (job_id, contractor_id, amount, status)
    VALUES (v_job_id, v_contractor_id, v_amount, 'pending');
  END IF;

  INSERT INTO notifications (user_id, type, payload)
  VALUES (
    v_contractor_id,
    'submission_approved',
    jsonb_build_object(
      'submission_id', p_submission_id,
      'job_id', v_job_id,
      'amount', v_amount,
      'store_id', v_store_id,
      'sku_id', v_sku_id
    )
  );
END;
$$;

-- ========================================
-- PART 4: REJECT submission RPC  
-- Run this separately
-- ========================================
CREATE OR REPLACE FUNCTION reject_submission(p_submission_id uuid, p_admin_id uuid, p_notes text)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_job_id uuid;
  v_contractor_id uuid;
  v_store_id uuid;
  v_sku_id uuid;
BEGIN
  IF p_notes IS NULL OR length(trim(p_notes)) = 0 THEN
    RAISE EXCEPTION 'Rejection notes are required';
  END IF;

  PERFORM 1 FROM job_submissions WHERE id = p_submission_id FOR UPDATE;

  SELECT
    js.job_id,
    js.contractor_id,
    COALESCE(js.store_id, j.store_id) AS store_id,
    COALESCE(js.sku_id, j.sku_id)     AS sku_id
  INTO
    v_job_id, v_contractor_id, v_store_id, v_sku_id
  FROM job_submissions js
  JOIN jobs j ON j.id = js.job_id
  WHERE js.id = p_submission_id;

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Submission % not found or missing job', p_submission_id;
  END IF;

  UPDATE job_submissions
  SET is_validated      = false,
      validated_by      = p_admin_id,
      validated_at      = now(),
      validation_notes  = p_notes,
      review_outcome    = 'rejected'
  WHERE id = p_submission_id;

  UPDATE jobs
  SET status = 'pending'
  WHERE id = v_job_id;

  INSERT INTO notifications (user_id, type, payload)
  VALUES (
    v_contractor_id,
    'submission_rejected',
    jsonb_build_object(
      'submission_id', p_submission_id,
      'job_id', v_job_id,
      'reason', p_notes,
      'store_id', v_store_id,
      'sku_id', v_sku_id
    )
  );
END;
$$;



-- ========================================
-- Fix: Update approve_submission RPC to remove j.store_id reference
-- ========================================
-- The jobs table doesn't have store_id or sku_id columns
-- These come from job_submissions or job_store_skus

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
  -- Lock the submission row to prevent races
  PERFORM 1 FROM job_submissions WHERE id = p_submission_id FOR UPDATE;

  -- Pull job/submission context
  -- Note: store_id and sku_id come from job_submissions, not jobs table
  SELECT
    js.job_id,
    js.contractor_id,
    js.store_id,
    js.sku_id,
    j.payout_per_store
  INTO
    v_job_id, v_contractor_id, v_store_id, v_sku_id, v_amount
  FROM job_submissions js
  JOIN jobs j ON j.id = js.job_id
  WHERE js.id = p_submission_id;

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Submission % not found or missing job', p_submission_id;
  END IF;

  -- Mark this submission as approved
  UPDATE job_submissions
  SET is_validated      = true,
      validated_by      = p_admin_id,
      validated_at      = now(),
      validation_notes  = COALESCE(p_notes, validation_notes),
      review_outcome    = 'approved'
  WHERE id = p_submission_id;

  -- Mark other submissions for this job as superseded
  UPDATE job_submissions
  SET review_outcome = 'superseded'
  WHERE job_id = v_job_id
    AND id <> p_submission_id
    AND review_outcome IS DISTINCT FROM 'approved';

  -- Complete the job
  UPDATE jobs
  SET status = 'completed'
  WHERE id = v_job_id;

  -- Create payment if a similar active payment doesn't already exist
  -- Guard: avoid dupes if button double-clicked
  IF NOT EXISTS (
    SELECT 1 FROM payments
    WHERE job_id = v_job_id
      AND contractor_id = v_contractor_id
      AND status IN ('pending','processing','completed')
  ) THEN
    INSERT INTO payments (job_id, contractor_id, amount, status)
    VALUES (v_job_id, v_contractor_id, v_amount, 'pending');
  END IF;

  -- In-app notification (MVP)
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

-- Also fix reject_submission if it has the same issue
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

  -- Lock the submission
  PERFORM 1 FROM job_submissions WHERE id = p_submission_id FOR UPDATE;

  -- Pull job/submission context (store_id and sku_id from submission, not job)
  SELECT
    js.job_id,
    js.contractor_id,
    js.store_id,
    js.sku_id
  INTO
    v_job_id, v_contractor_id, v_store_id, v_sku_id
  FROM job_submissions js
  JOIN jobs j ON j.id = js.job_id
  WHERE js.id = p_submission_id;

  IF v_job_id IS NULL THEN
    RAISE EXCEPTION 'Submission % not found or missing job', p_submission_id;
  END IF;

  -- Mark this submission rejected (kept for audit)
  UPDATE job_submissions
  SET is_validated      = false,
      validated_by      = p_admin_id,
      validated_at      = now(),
      validation_notes  = p_notes,
      review_outcome    = 'rejected'
  WHERE id = p_submission_id;

  -- Reopen job for resubmission
  UPDATE jobs
  SET status = 'pending'
  WHERE id = v_job_id;

  -- In-app notification (MVP)
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

-- Verify the functions were updated
SELECT 
    '✅ approve_submission updated' as status
WHERE EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'approve_submission'
);

SELECT 
    '✅ reject_submission updated' as status
WHERE EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'reject_submission'
);



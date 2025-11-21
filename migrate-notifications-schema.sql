-- ========================================
-- Notifications Schema Migration
-- Run this ONLY if old schema exists
-- ========================================
-- Purpose: Migrate from old schema (title, message, is_read) 
--          to new schema (type, payload, read_at)
-- Date: 2025-01-13

-- STEP 1: Check if old schema exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' AND column_name = 'title'
    ) THEN
        RAISE NOTICE '⚠️ Old schema detected. Migration needed.';
        
        -- STEP 2: Create backup table with old data
        CREATE TABLE IF NOT EXISTS notifications_old_backup AS
        SELECT * FROM notifications;
        
        RAISE NOTICE '✅ Backup created: notifications_old_backup';
        
        -- STEP 3: Drop old table
        DROP TABLE IF EXISTS notifications CASCADE;
        
        RAISE NOTICE '✅ Old table dropped';
        
        -- STEP 4: Create new schema table
        CREATE TABLE notifications (
            id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id       uuid NOT NULL,
            type          text NOT NULL,
            payload       jsonb NOT NULL DEFAULT '{}'::jsonb,
            created_at    timestamptz NOT NULL DEFAULT now(),
            read_at       timestamptz
        );
        
        -- STEP 5: Create index
        CREATE INDEX IF NOT EXISTS idx_notifications_user_created
            ON notifications (user_id, created_at DESC);
        
        -- STEP 6: Migrate data from backup (if needed)
        -- Convert old notifications to new format
        INSERT INTO notifications (id, user_id, type, payload, created_at, read_at)
        SELECT 
            id,
            user_id,
            CASE 
                WHEN title ILIKE '%approved%' OR message ILIKE '%approved%' THEN 'submission_approved'
                WHEN title ILIKE '%rejected%' OR message ILIKE '%rejected%' THEN 'submission_rejected'
                ELSE 'notification'
            END as type,
            jsonb_build_object(
                'title', title,
                'message', message,
                'migrated_from_old_schema', true
            ) as payload,
            created_at,
            CASE WHEN is_read THEN created_at ELSE NULL END as read_at
        FROM notifications_old_backup;
        
        RAISE NOTICE '✅ Data migrated to new schema';
        RAISE NOTICE '⚠️ Old backup table kept: notifications_old_backup (can delete after verification)';
        
    ELSE
        RAISE NOTICE '✅ New schema already exists. No migration needed.';
    END IF;
END $$;

-- Verify new schema
SELECT 
    'SCHEMA VERIFICATION' as check_type,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;


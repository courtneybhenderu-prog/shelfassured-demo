-- Step 1: PostgREST Schema Reload
-- Prevents any stale "relation" ghosts
NOTIFY pgrst, 'reload schema';


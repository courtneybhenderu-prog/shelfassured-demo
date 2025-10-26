-- Step 3: Console Smoke Test Instructions
-- Run this JavaScript in your browser console (on admin page, signed in)

/*
CONSOLE SMOKE TEST - Copy and paste this into browser console:

// Test 1: Check authentication
const { data: sess } = await supabase.auth.getSession();
console.log('Auth check:', !!sess.session, sess.session?.user?.id);

// Test 2: Try creating a job via Supabase client
const { data, error } = await supabase
  .from('jobs')
  .insert([{ 
    title: 'Console Smoke Test', 
    description: 'RLS check via console' 
  }])
  .select();

console.log('Job creation result:', { data, error });

// Test 3: If successful, clean up the test job
if (data && data[0]) {
  const { error: deleteError } = await supabase
    .from('jobs')
    .delete()
    .eq('id', data[0].id);
  console.log('Cleanup result:', { deleteError });
}
*/

-- Expected Results:
-- Auth check: true, <UUID>
-- Job creation: { data: [{ id: <UUID>, title: 'Console Smoke Test', ... }], error: null }
-- Cleanup: { deleteError: null }


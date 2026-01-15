-- 1. Replace 'user@example.com' with the user's email you want to update
-- 2. Run this query in the Supabase SQL Editor

UPDATE public.profiles
SET role = 'admin'  -- Options: 'admin', 'staff', 'client'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'user@example.com'
);

-- Verify the change
SELECT * FROM public.profiles 
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'user@example.com'
);

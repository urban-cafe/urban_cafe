-- Secure the profiles table to prevent users from escalating their own privileges
-- (e.g., a client changing their role to 'admin')

-- 1. Drop the existing generic update policy
drop policy if exists "Users can update own profile." on public.profiles;

-- 2. Create a new policy that restricts role changes
-- This policy allows users to update their own profile, but the 'role' column 
-- must remain unchanged in the new version of the row.
create policy "Users can update own profile details"
on public.profiles
for update
using (auth.uid() = id)
with check (
  -- Ensure the ID matches (standard RLS)
  auth.uid() = id 
  -- AND Ensure the role hasn't changed (prevents privilege escalation)
  and role = (select role from public.profiles where id = auth.uid())
);

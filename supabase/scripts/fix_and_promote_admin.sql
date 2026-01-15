-- 1. Ensure the profile exists (in case the user signed up before the trigger was active)
insert into public.profiles (id, role)
select id, 'client'
from auth.users
where email = 'urbancafe@gmail.com'
on conflict (id) do nothing;

-- 2. Promote to Admin
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'urbancafe@gmail.com');

-- 3. Verify the result (Join with auth.users to see the email)
select u.email, p.role, p.id
from public.profiles p
join auth.users u on p.id = u.id
where u.email = 'urbancafe@gmail.com';

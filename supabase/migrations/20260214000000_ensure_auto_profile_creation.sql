-- Ensure the handle_new_user function and trigger exist
-- This migration is idempotent and safe to run multiple times

-- Drop existing trigger and function if they exist
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Create function to handle new user signup
-- This automatically creates a profile with 'client' role for any new user
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role, created_at, updated_at)
  values (new.id, 'client', now(), now())
  on conflict (id) do nothing; -- Prevent duplicate key errors
  return new;
end;
$$;

-- Create trigger to automatically create profile on user signup
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Grant necessary permissions
grant usage on schema public to postgres, anon, authenticated, service_role;
grant all on public.profiles to postgres, service_role;
grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;

comment on function public.handle_new_user() is 'Automatically creates a client profile when a new user signs up via any method (email, OAuth, etc.)';

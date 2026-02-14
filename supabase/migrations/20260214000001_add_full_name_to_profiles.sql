-- Add full_name column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS full_name TEXT;

-- Update the handle_new_user function to extract full_name from auth metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name, created_at, updated_at)
  VALUES (
    new.id,
    'client',
    COALESCE(new.raw_user_meta_data->>'full_name', new.email),
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing profiles with names from auth.users metadata
UPDATE profiles p
SET full_name = COALESCE(
  (SELECT u.raw_user_meta_data->>'full_name' FROM auth.users u WHERE u.id = p.id),
  (SELECT u.email FROM auth.users u WHERE u.id = p.id)
)
WHERE full_name IS NULL;

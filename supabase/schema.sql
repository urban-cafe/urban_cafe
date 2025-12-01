-- UrbanCafe schema for Supabase
create extension if not exists pgcrypto;

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(10,2) not null,
  category text,
  image_path text,
  image_url text,
  is_available boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_menu_items_category on public.menu_items(category);
create index if not exists idx_menu_items_created_at on public.menu_items(created_at desc);

-- Categories table for hierarchical menu grouping
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  parent_id uuid references public.categories(id) on delete cascade,
  created_at timestamptz default now()
);

-- RLS policies for categories
alter table public.categories enable row level security;
create policy "anon read categories" on public.categories for select using (true);
create policy "auth write categories" on public.categories for all using (auth.role() = 'authenticated');

-- Optional seeds for categories
insert into public.categories (name) values ('COLD DRINKS') on conflict do nothing;
insert into public.categories (name) values ('HOT DRINKS') on conflict do nothing;
insert into public.categories (name) values ('FOOD') on conflict do nothing;

-- Seed subcategories for COLD DRINKS
with parent as (
  select id from public.categories where name = 'COLD DRINKS' limit 1
)
insert into public.categories (name, parent_id)
select name, (select id from parent) from (values
  ('Tea'),
  ('Soda'),
  ('Matcha'),
  ('Milkshake Cheesy'),
  ('Tiramisu Special Drinks'),
  ('Frappe'),
  ('Refresh Fusion'),
  ('Coffee'),
  ('Seasonal Fruits')
) as v(name)
on conflict do nothing;

-- Seed subcategories for HOT DRINKS
with parent as (
  select id from public.categories where name = 'HOT DRINKS' limit 1
)
insert into public.categories (name, parent_id)
values ('COFFEE', (select id from parent))
on conflict do nothing;

-- Seeds
insert into public.menu_items (name, description, price, category, image_url)
values
('Espresso', 'Rich and bold espresso shot', 2.99, 'Coffee', 'https://picsum.photos/seed/espresso/800/600'),
('Cappuccino', 'Espresso with steamed milk and foam', 3.99, 'Coffee', 'https://picsum.photos/seed/cappuccino/800/600'),
('Avocado Toast', 'Sourdough with smashed avocado', 6.49, 'Food', 'https://picsum.photos/seed/avocado/800/600');

-- Storage bucket (create in Supabase dashboard): menu-images
-- Recommended Storage policy (authenticated admins only)
-- Example: allow authenticated users to manage files
-- Policies (SQL):
--
-- create policy "Allow authenticated upload" on storage.objects
-- for insert to public
-- using (auth.role() = 'authenticated')
-- with check (bucket_id = 'menu-images');
--
-- create policy "Allow authenticated read" on storage.objects
-- for select to public
-- using (bucket_id = 'menu-images');
--
-- Optionally tighten with user_id ownership linking.

-- RLS policies for menu_items (optional admin-only writes)
-- enable row level security
alter table public.menu_items enable row level security;
-- read for anon
create policy "anon read menu" on public.menu_items for select using (true);
-- write for authenticated
create policy "auth write menu" on public.menu_items for all using (auth.role() = 'authenticated');

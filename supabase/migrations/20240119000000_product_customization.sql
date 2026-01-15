-- 1. Create Variants Table (e.g., Size: Small, Medium, Large)
CREATE TABLE public.menu_item_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL, -- e.g., "Small", "Medium"
    price_adjustment NUMERIC DEFAULT 0 NOT NULL, -- e.g., +0, +1.0
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Add-ons Table (e.g., Extra Shot, Soy Milk)
CREATE TABLE public.menu_item_addons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL, -- e.g., "Extra Shot"
    price NUMERIC DEFAULT 0 NOT NULL, -- e.g., 0.5
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Enable RLS
ALTER TABLE public.menu_item_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_addons ENABLE ROW LEVEL SECURITY;

-- 4. Policies (Public Read, Admin Write)
-- Variants
CREATE POLICY "Public variants are viewable by everyone" ON public.menu_item_variants FOR SELECT USING (true);
CREATE POLICY "Admins can insert variants" ON public.menu_item_variants FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "Admins can update variants" ON public.menu_item_variants FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "Admins can delete variants" ON public.menu_item_variants FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Addons
CREATE POLICY "Public addons are viewable by everyone" ON public.menu_item_addons FOR SELECT USING (true);
CREATE POLICY "Admins can insert addons" ON public.menu_item_addons FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "Admins can update addons" ON public.menu_item_addons FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
CREATE POLICY "Admins can delete addons" ON public.menu_item_addons FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE menu_item_variants;
ALTER PUBLICATION supabase_realtime ADD TABLE menu_item_addons;

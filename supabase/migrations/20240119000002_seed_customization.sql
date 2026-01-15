DO $$
DECLARE
    cappuccino_id UUID;
    latte_id UUID;
    item_record RECORD;
BEGIN
    -- 1. Find Cappuccino and add options
    SELECT id INTO cappuccino_id FROM public.menu_items WHERE name ILIKE '%Cappuccino%' LIMIT 1;
    
    IF cappuccino_id IS NOT NULL THEN
        -- Clear existing to avoid duplicates if re-run (optional, but safe for seeding)
        DELETE FROM public.menu_item_variants WHERE menu_item_id = cappuccino_id;
        DELETE FROM public.menu_item_addons WHERE menu_item_id = cappuccino_id;

        -- Add Variants
        INSERT INTO public.menu_item_variants (menu_item_id, name, price_adjustment, is_default)
        VALUES 
            (cappuccino_id, 'Small', 0, true),
            (cappuccino_id, 'Medium', 0.50, false),
            (cappuccino_id, 'Large', 1.00, false);
        
        -- Add Addons
        INSERT INTO public.menu_item_addons (menu_item_id, name, price)
        VALUES 
            (cappuccino_id, 'Extra Shot', 0.50),
            (cappuccino_id, 'Soy Milk', 0.50),
            (cappuccino_id, 'Oat Milk', 0.75),
            (cappuccino_id, 'Vanilla Syrup', 0.30);
    END IF;

    -- 2. Find Latte and add options
    SELECT id INTO latte_id FROM public.menu_items WHERE name ILIKE '%Latte%' LIMIT 1;
    
    IF latte_id IS NOT NULL THEN
        DELETE FROM public.menu_item_variants WHERE menu_item_id = latte_id;
        DELETE FROM public.menu_item_addons WHERE menu_item_id = latte_id;

        INSERT INTO public.menu_item_variants (menu_item_id, name, price_adjustment, is_default)
        VALUES 
            (latte_id, 'Small', 0, true),
            (latte_id, 'Medium', 0.50, false),
            (latte_id, 'Large', 1.00, false);
            
        INSERT INTO public.menu_item_addons (menu_item_id, name, price)
        VALUES 
            (latte_id, 'Extra Shot', 0.50),
            (latte_id, 'Almond Milk', 0.60),
            (latte_id, 'Caramel Syrup', 0.30),
            (latte_id, 'Hazelnut Syrup', 0.30);
    END IF;

    -- 3. Generic: Add sizes to all 'Coffee' category items if they don't have variants yet
    -- First get the Coffee category ID
    FOR item_record IN 
        SELECT m.id 
        FROM public.menu_items m
        JOIN public.categories c ON m.category_id = c.id
        WHERE c.name ILIKE '%Coffee%' 
        AND m.id NOT IN (SELECT menu_item_id FROM public.menu_item_variants) -- Skip if already has variants
    LOOP
        INSERT INTO public.menu_item_variants (menu_item_id, name, price_adjustment, is_default)
        VALUES 
            (item_record.id, 'Regular', 0, true),
            (item_record.id, 'Large', 0.80, false);
            
        INSERT INTO public.menu_item_addons (menu_item_id, name, price)
        VALUES 
            (item_record.id, 'Extra Shot', 0.50),
            (item_record.id, 'Whipped Cream', 0.50);
    END LOOP;
    
END $$;

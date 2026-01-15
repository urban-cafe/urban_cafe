-- Create a function to calculate analytics
-- This is more efficient than fetching all rows to the client
CREATE OR REPLACE FUNCTION public.get_admin_analytics()
RETURNS JSONB AS $$
DECLARE
    total_sales_today NUMERIC;
    total_orders_today INTEGER;
    top_items JSONB;
    hourly_sales JSONB;
    start_of_day TIMESTAMPTZ := date_trunc('day', now());
BEGIN
    -- 1. Total Sales Today
    SELECT COALESCE(SUM(total_amount), 0)
    INTO total_sales_today
    FROM public.orders
    WHERE created_at >= start_of_day AND status != 'cancelled';

    -- 2. Total Orders Today
    SELECT COUNT(*)
    INTO total_orders_today
    FROM public.orders
    WHERE created_at >= start_of_day AND status != 'cancelled';

    -- 3. Top Selling Items (All Time or Last 30 Days - let's do Last 30 Days)
    SELECT jsonb_agg(t)
    INTO top_items
    FROM (
        SELECT m.name, SUM(oi.quantity) as total_sold
        FROM public.order_items oi
        JOIN public.menu_items m ON oi.menu_item_id = m.id
        JOIN public.orders o ON oi.order_id = o.id
        WHERE o.created_at >= (now() - INTERVAL '30 days')
        AND o.status != 'cancelled'
        GROUP BY m.name
        ORDER BY total_sold DESC
        LIMIT 5
    ) t;

    -- 4. Hourly Sales (Today) for Peak Hours Chart
    SELECT jsonb_agg(t)
    INTO hourly_sales
    FROM (
        SELECT EXTRACT(HOUR FROM created_at) as hour, COUNT(*) as count
        FROM public.orders
        WHERE created_at >= start_of_day
        AND status != 'cancelled'
        GROUP BY 1
        ORDER BY 1
    ) t;

    RETURN jsonb_build_object(
        'total_sales_today', total_sales_today,
        'total_orders_today', total_orders_today,
        'top_items', COALESCE(top_items, '[]'::jsonb),
        'hourly_sales', COALESCE(hourly_sales, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

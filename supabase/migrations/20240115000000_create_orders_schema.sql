-- 1. Create Orders Table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')) DEFAULT 'pending',
    type TEXT NOT NULL CHECK (type IN ('dineIn', 'takeaway')) DEFAULT 'dineIn',
    staff_notes TEXT, -- For internal kitchen/staff notes
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create Order Items Table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id UUID REFERENCES menu_items(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_at_order NUMERIC NOT NULL CHECK (price_at_order >= 0), -- Snapshot of price
    notes TEXT, -- Special instructions (e.g., "No ice")
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Inventory Tracking (Add stock to menu_items)
ALTER TABLE menu_items 
ADD COLUMN stock_quantity INTEGER DEFAULT NULL; -- NULL means unlimited

-- 4. Payments Table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL CHECK (amount >= 0),
    method TEXT NOT NULL CHECK (method IN ('cash', 'card', 'online')),
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
    transaction_id TEXT, -- External gateway ID
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Order Logs / Audit Trail
CREATE TABLE order_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    old_status TEXT,
    new_status TEXT,
    action TEXT NOT NULL, -- e.g., "status_update", "payment_processed"
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. RLS Policies

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_logs ENABLE ROW LEVEL SECURITY;

-- Orders Policies
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Staff and Admin can view all orders" ON orders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('staff', 'admin')
        )
    );

CREATE POLICY "Staff and Admin can update orders" ON orders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('staff', 'admin')
        )
    );

-- Order Items Policies
CREATE POLICY "Users can view their own order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create order items" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Staff and Admin can view all order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('staff', 'admin')
        )
    );

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;

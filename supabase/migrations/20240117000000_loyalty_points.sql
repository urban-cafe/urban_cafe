-- 1. Add loyalty_points to profiles
ALTER TABLE public.profiles 
ADD COLUMN loyalty_points INTEGER DEFAULT 0 NOT NULL CHECK (loyalty_points >= 0);

-- 2. Add points_redeemed to orders (to track usage)
ALTER TABLE public.orders
ADD COLUMN points_redeemed INTEGER DEFAULT 0 CHECK (points_redeemed >= 0);

-- 3. Create Loyalty Transactions Table
CREATE TABLE public.loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    points INTEGER NOT NULL, -- Positive for earn, Negative for redeem
    type TEXT NOT NULL CHECK (type IN ('earned', 'redeemed', 'adjustment', 'refund')),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own loyalty transactions" ON public.loyalty_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Staff/Admin can view all loyalty transactions" ON public.loyalty_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('staff', 'admin')
        )
    );

-- 4. Trigger to Award Points on Order Completion
-- Rule: Earn 1 point for every $1 spent (floor value)
CREATE OR REPLACE FUNCTION public.award_points_on_completion()
RETURNS TRIGGER AS $$
DECLARE
    earned_points INTEGER;
BEGIN
    -- Only trigger when status changes to 'completed'
    IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
        -- Calculate points (1 point per $1)
        -- Use total_amount (which is final price paid)
        earned_points := FLOOR(NEW.total_amount);

        IF earned_points > 0 THEN
            -- Update User Profile
            UPDATE public.profiles
            SET loyalty_points = loyalty_points + earned_points
            WHERE id = NEW.user_id;

            -- Log Transaction
            INSERT INTO public.loyalty_transactions (user_id, points, type, order_id, description)
            VALUES (NEW.user_id, earned_points, 'earned', NEW.id, 'Points earned from Order #' || SUBSTRING(NEW.id::text, 1, 8));
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_completed
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE PROCEDURE public.award_points_on_completion();

-- 5. Trigger to Deduct Points on Order Creation (Redemption)
-- Rule: Deduct points immediately when order is placed
CREATE OR REPLACE FUNCTION public.deduct_points_on_order()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.points_redeemed > 0 THEN
        -- Check if user has enough points
        IF (SELECT loyalty_points FROM public.profiles WHERE id = NEW.user_id) < NEW.points_redeemed THEN
            RAISE EXCEPTION 'Insufficient loyalty points';
        END IF;

        -- Deduct Points
        UPDATE public.profiles
        SET loyalty_points = loyalty_points - NEW.points_redeemed
        WHERE id = NEW.user_id;

        -- Log Transaction
        INSERT INTO public.loyalty_transactions (user_id, points, type, order_id, description)
        VALUES (NEW.user_id, -NEW.points_redeemed, 'redeemed', NEW.id, 'Points redeemed for Order #' || SUBSTRING(NEW.id::text, 1, 8));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_created_redemption
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE PROCEDURE public.deduct_points_on_order();

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE loyalty_transactions;

-- Migration to add staff_id tracking and pagination support to loyalty_transactions

-- Add staff_id column to track which staff processed the transaction
ALTER TABLE public.loyalty_transactions
ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Add index for faster date-based queries and pagination
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_created_at 
ON public.loyalty_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user_created 
ON public.loyalty_transactions(user_id, created_at DESC);

-- Update the RPC to record which staff processed the transaction
CREATE OR REPLACE FUNCTION public.process_point_transaction(
    p_token TEXT,
    p_points INTEGER,
    p_is_award BOOLEAN
)
RETURNS jsonb AS $$
DECLARE
    v_user_id UUID;
    v_staff_id UUID;
    v_customer_name TEXT;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_transaction_type TEXT;
BEGIN
    -- Get the current authenticated staff user
    v_staff_id := auth.uid();

    IF p_points <= 0 THEN
        RETURN jsonb_build_object('success', false, 'message', 'Points must be greater than 0');
    END IF;

    -- 1. Validate Token
    SELECT user_id INTO v_user_id
    FROM public.point_tokens
    WHERE token = p_token
      AND expires_at > now()
    FOR UPDATE; -- Lock the row

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid or expired QR code');
    END IF;

    -- 2. Get User Profile
    SELECT full_name, loyalty_points INTO v_customer_name, v_current_points
    FROM public.profiles
    WHERE id = v_user_id
    FOR UPDATE;

    IF v_customer_name IS NULL THEN
        v_customer_name := 'Customer';
    END IF;

    -- 3. Process Transaction
    IF p_is_award THEN
        v_new_points := v_current_points + p_points;
        v_transaction_type := 'earned';
    ELSE
        IF v_current_points < p_points THEN
            RETURN jsonb_build_object('success', false, 'message', 'Customer does not have enough points');
        END IF;
        v_new_points := v_current_points - p_points;
        v_transaction_type := 'redeemed';
    END IF;

    -- 4. Update Profile
    UPDATE public.profiles
    SET loyalty_points = v_new_points
    WHERE id = v_user_id;

    -- 5. Log Transaction (with staff_id)
    INSERT INTO public.loyalty_transactions (user_id, staff_id, points, type, description)
    VALUES (
        v_user_id,
        v_staff_id,
        CASE WHEN p_is_award THEN p_points ELSE -p_points END, 
        v_transaction_type, 
        CASE WHEN p_is_award THEN 'Points manually awarded by staff' ELSE 'Points manually redeemed by staff' END
    );

    -- 6. Return Result
    RETURN jsonb_build_object(
        'success', true,
        'clientName', v_customer_name,
        'pointsProcessed', p_points,
        'newBalance', v_new_points,
        'isAward', p_is_award
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Migration to suppport manual Point Award and Redeem

-- Drop old RPC if exists
DROP FUNCTION IF EXISTS public.redeem_point_token(text, double precision);

-- Create new RPC for manual point transaction
CREATE OR REPLACE FUNCTION public.process_point_transaction(
    p_token TEXT,
    p_points INTEGER,
    p_is_award BOOLEAN
)
RETURNS jsonb AS $$
DECLARE
    v_user_id UUID;
    v_customer_name TEXT;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_transaction_type TEXT;
BEGIN
    IF p_points <= 0 THEN
        RETURN jsonb_build_object('success', false, 'message', 'Points must be greater than 0');
    END IF;

    -- 1. Validate Token
    SELECT user_id INTO v_user_id
    FROM public.point_tokens
    WHERE token = p_token
      AND expires_at > now()
      AND redeemed = false
    FOR UPDATE; -- Lock the row

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid, expired, or already used QR code');
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

    -- 5. Mark Token as Redeemed
    UPDATE public.point_tokens
    SET redeemed = true
    WHERE token = p_token;

    -- 6. Log Transaction
    INSERT INTO public.loyalty_transactions (user_id, points, type, description)
    VALUES (
        v_user_id, 
        CASE WHEN p_is_award THEN p_points ELSE -p_points END, 
        v_transaction_type, 
        CASE WHEN p_is_award THEN 'Points manually awarded by staff' ELSE 'Points manually redeemed by staff' END
    );

    -- 7. Return Result
    RETURN jsonb_build_object(
        'success', true,
        'clientName', v_customer_name,
        'pointsProcessed', p_points,
        'newBalance', v_new_points,
        'isAward', p_is_award
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

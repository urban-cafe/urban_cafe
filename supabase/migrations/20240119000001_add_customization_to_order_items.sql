-- Add customization column to order_items
ALTER TABLE public.order_items
ADD COLUMN customization JSONB DEFAULT '{}'::jsonb;

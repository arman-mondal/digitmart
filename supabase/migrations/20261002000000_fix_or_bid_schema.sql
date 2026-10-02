-- Migration: Fix or Bid Production Schema, RLS, & Server-Side Engine
-- File: supabase/migrations/20261002000000_fix_or_bid_schema.sql

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- Drop existing tables to establish clean production structure
DROP VIEW IF EXISTS public.public_auctions CASCADE;
DROP TABLE IF EXISTS public.watchlist CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.ratings CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.chats CASCADE;
DROP TABLE IF EXISTS public.bids CASCADE;
DROP TABLE IF EXISTS public.auctions CASCADE;
DROP TABLE IF EXISTS public.product_images CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 1. PROFILES TABLE
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    profile_image TEXT,
    verification_status BOOLEAN NOT NULL DEFAULT false,
    rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00 CHECK (rating >= 0 AND rating <= 5.00),
    completed_transactions INT NOT NULL DEFAULT 0 CHECK (completed_transactions >= 0),
    bid_reliability INT NOT NULL DEFAULT 100 CHECK (bid_reliability >= 0 AND bid_reliability <= 100),
    location_name TEXT NOT NULL DEFAULT 'Kolkata, West Bengal',
    latitude NUMERIC(10, 6) DEFAULT 22.5726,
    longitude NUMERIC(10, 6) DEFAULT 88.4639,
    is_admin BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. CATEGORIES TABLE
CREATE TABLE public.categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    sort_order INT NOT NULL DEFAULT 0
);

-- Seed Default Categories
INSERT INTO public.categories (id, name, icon, slug, sort_order) VALUES
('phones', 'Phones & Mobile', 'phone_iphone', 'phones', 1),
('laptops', 'Laptops & Computers', 'laptop_mac', 'laptops', 2),
('gaming', 'Gaming & Consoles', 'sports_esports', 'gaming', 3),
('cameras', 'Cameras & Photography', 'camera_alt', 'cameras', 4),
('audio', 'Audio & Headphones', 'headphones', 'audio', 5),
('watches', 'Smartwatches & Accessories', 'watch', 'watches', 6);

-- 3. PRODUCTS TABLE
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (length(trim(title)) >= 3),
    description TEXT NOT NULL CHECK (length(trim(description)) >= 10),
    category_id TEXT NOT NULL REFERENCES public.categories(id),
    condition TEXT NOT NULL CHECK (condition IN ('New', 'Like New', 'Used - Good', 'Used - Fair')),
    location TEXT NOT NULL DEFAULT 'Kolkata, West Bengal',
    latitude NUMERIC(10, 6) NOT NULL DEFAULT 22.5726,
    longitude NUMERIC(10, 6) NOT NULL DEFAULT 88.4639,
    selling_mode TEXT NOT NULL CHECK (selling_mode IN ('FIX', 'BID', 'FIX_AND_BID')),
    fixed_price NUMERIC(12, 2) CHECK (fixed_price IS NULL OR fixed_price > 0),
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SOLD', 'CANCELLED', 'EXPIRED')),
    views INT NOT NULL DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_products_status ON public.products(status);
CREATE INDEX idx_products_category ON public.products(category_id);
CREATE INDEX idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX idx_products_seller ON public.products(seller_id);
CREATE INDEX idx_products_title_trgm ON public.products USING gin (title gin_trgm_ops);

-- 4. PRODUCT IMAGES TABLE
CREATE TABLE public.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_product_images_product ON public.product_images(product_id);

-- 5. AUCTIONS TABLE
CREATE TABLE public.auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL UNIQUE REFERENCES public.products(id) ON DELETE CASCADE,
    starting_price NUMERIC(12, 2) NOT NULL CHECK (starting_price > 0),
    current_price NUMERIC(12, 2) NOT NULL CHECK (current_price >= starting_price),
    minimum_increment NUMERIC(12, 2) NOT NULL DEFAULT 500.00 CHECK (minimum_increment > 0),
    reserve_price NUMERIC(12, 2) CHECK (reserve_price IS NULL OR reserve_price >= starting_price),
    buy_now_price NUMERIC(12, 2) CHECK (buy_now_price IS NULL OR buy_now_price > starting_price),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ NOT NULL,
    extended_until TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('DRAFT', 'SCHEDULED', 'ACTIVE', 'ENDING', 'ENDED', 'RESERVE_NOT_MET', 'WINNER_SELECTED', 'COMPLETED', 'CANCELLED')),
    winner_id UUID REFERENCES public.profiles(id),
    total_bids INT NOT NULL DEFAULT 0 CHECK (total_bids >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_auctions_status ON public.auctions(status);
CREATE INDEX idx_auctions_end_time ON public.auctions(end_time);

-- 6. BIDS TABLE
CREATE TABLE public.bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
    bidder_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    maximum_amount NUMERIC(12, 2) NOT NULL CHECK (maximum_amount >= amount),
    is_auto_bid BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL DEFAULT 'VALID' CHECK (status IN ('VALID', 'OUTBID', 'WINNING', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bids_auction ON public.bids(auction_id, created_at DESC);
CREATE INDEX idx_bids_bidder ON public.bids(bidder_id);
CREATE INDEX idx_bids_amount ON public.bids(auction_id, amount DESC);

-- 7. CHATS TABLE
CREATE TABLE public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_buyer_seller_product UNIQUE(product_id, buyer_id)
);

CREATE INDEX idx_chats_users ON public.chats(buyer_id, seller_id);

-- 8. MESSAGES TABLE
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'system', 'action_meeting', 'action_shipping', 'action_completed')),
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_chat ON public.messages(chat_id, created_at ASC);

-- 9. RATINGS TABLE
CREATE TABLE public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID,
    reviewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reviewed_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. REPORTS TABLE
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.profiles(id),
    product_id UUID REFERENCES public.products(id),
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_status ON public.reports(status);

-- 11. NOTIFICATIONS TABLE
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id, read_at);

-- 12. WATCHLIST TABLE
CREATE TABLE public.watchlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- -------------------------------------------------------
-- PUBLIC AUCTIONS VIEW (Hides reserve_price from public)
-- -------------------------------------------------------
CREATE OR REPLACE VIEW public.public_auctions AS
SELECT 
    a.id,
    a.product_id,
    a.starting_price,
    a.current_price,
    a.minimum_increment,
    a.buy_now_price,
    a.start_time,
    a.end_time,
    a.extended_until,
    a.status,
    a.winner_id,
    a.total_bids,
    a.created_at,
    a.updated_at,
    CASE WHEN a.reserve_price IS NOT NULL AND a.current_price >= a.reserve_price THEN true ELSE false END AS reserve_met
FROM public.auctions a;

-- -------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
-- -------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.watchlist ENABLE ROW LEVEL SECURITY;

-- 1. Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile name/phone/location" 
ON public.profiles FOR UPDATE USING (auth.uid() = id) 
WITH CHECK (
    auth.uid() = id
    -- Prevent users from tampering with server-calculated columns
    AND rating = (SELECT rating FROM public.profiles WHERE id = auth.uid())
    AND bid_reliability = (SELECT bid_reliability FROM public.profiles WHERE id = auth.uid())
    AND verification_status = (SELECT verification_status FROM public.profiles WHERE id = auth.uid())
    AND is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
);

-- 2. Categories Policies
CREATE POLICY "Categories viewable by everyone" ON public.categories FOR SELECT USING (true);

-- 3. Products Policies
CREATE POLICY "Active products viewable by everyone" 
ON public.products FOR SELECT USING (deleted_at IS NULL);

CREATE POLICY "Sellers can create products" 
ON public.products FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY "Sellers can update their own products" 
ON public.products FOR UPDATE USING (auth.uid() = seller_id);

CREATE POLICY "Sellers can delete their own products" 
ON public.products FOR DELETE USING (auth.uid() = seller_id);

-- 4. Product Images Policies
CREATE POLICY "Product images viewable by everyone" ON public.product_images FOR SELECT USING (true);
CREATE POLICY "Sellers can add product images" ON public.product_images FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.products WHERE id = product_id AND seller_id = auth.uid())
);

-- 5. Auctions Policies
CREATE POLICY "Auctions viewable by everyone" ON public.auctions FOR SELECT USING (true);

-- Revoke direct insert/update/delete on auctions and bids from client roles
REVOKE INSERT, UPDATE, DELETE ON public.auctions FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.bids FROM anon, authenticated;

-- Allow bids to be read by everyone (maximum_amount is kept private via view/RPC if needed)
CREATE POLICY "Bids viewable by authenticated users" ON public.bids FOR SELECT TO authenticated USING (true);

-- 6. Chats & Messages Policies
CREATE POLICY "Participants can view their chats" 
ON public.chats FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Users can create chat if participant" 
ON public.chats FOR INSERT WITH CHECK (auth.uid() = buyer_id OR auth.uid() = seller_id);

CREATE POLICY "Participants can view chat messages" 
ON public.messages FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.chats WHERE id = chat_id AND (buyer_id = auth.uid() OR seller_id = auth.uid()))
);

CREATE POLICY "Participants can send chat messages" 
ON public.messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (SELECT 1 FROM public.chats WHERE id = chat_id AND (buyer_id = auth.uid() OR seller_id = auth.uid()))
);

-- 7. Watchlist Policies
CREATE POLICY "Users view own watchlist" ON public.watchlist FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users add to own watchlist" ON public.watchlist FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users remove from own watchlist" ON public.watchlist FOR DELETE USING (auth.uid() = user_id);

-- 8. Notifications Policies
CREATE POLICY "Users view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- 9. Reports & Moderation Policies
CREATE POLICY "Users insert reports" ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Admins read and manage reports" ON public.reports FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
);

-- -------------------------------------------------------
-- PHASE 1: SERVER-SIDE ATOMIC AUCTION ENGINE FUNCTIONS
-- -------------------------------------------------------

-- 1. ATOMIC PLACE_BID RPC (SECURITY DEFINER with row locks & proxy bidding)
CREATE OR REPLACE FUNCTION public.place_bid(
    p_auction_id UUID,
    p_amount NUMERIC,
    p_max_amount NUMERIC DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_bidder_id UUID;
    v_auction RECORD;
    v_product RECORD;
    v_eff_end_time TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();
    v_min_required NUMERIC;
    v_actual_max NUMERIC;
    v_top_bid RECORD;
    v_new_price NUMERIC;
    v_winning_bidder_id UUID;
    v_extended_until TIMESTAMPTZ := NULL;
    v_extension_interval INTERVAL := INTERVAL '2 minutes';
    v_max_allowed_end TIMESTAMPTZ;
BEGIN
    -- Validate auth
    v_bidder_id := auth.uid();
    IF v_bidder_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Authentication required to place bid.');
    END IF;

    -- Lock the auction row FOR UPDATE to prevent race conditions
    SELECT * INTO v_auction FROM public.auctions WHERE id = p_auction_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Auction not found.');
    END IF;

    -- Fetch product details
    SELECT * INTO v_product FROM public.products WHERE id = v_auction.product_id;
    
    -- Block seller from bidding on own product
    IF v_product.seller_id = v_bidder_id THEN
        RETURN jsonb_build_object('success', false, 'message', 'Sellers cannot bid on their own listings.');
    END IF;

    -- Calculate effective end time
    v_eff_end_time := COALESCE(v_auction.extended_until, v_auction.end_time);

    -- Check active status and time
    IF v_auction.status NOT IN ('ACTIVE', 'ENDING') OR v_now >= v_eff_end_time THEN
        RETURN jsonb_build_object('success', false, 'message', 'This auction has ended or is not active.');
    END IF;

    -- Validate minimum increment
    v_min_required := v_auction.current_price + v_auction.minimum_increment;
    IF p_amount < v_min_required THEN
        RETURN jsonb_build_object('success', false, 'message', 'Bid must be at least ₹' || v_min_required::text);
    END IF;

    v_actual_max := GREATEST(p_amount, COALESCE(p_max_amount, p_amount));

    -- Anti-snipe fair extension check (if bid within 2 mins of end, add +2 mins up to max 2 hours beyond original end)
    v_max_allowed_end := v_auction.end_time + INTERVAL '2 hours';
    IF (v_eff_end_time - v_now) < v_extension_interval THEN
        v_extended_until := LEAST(v_eff_end_time + v_extension_interval, v_max_allowed_end);
    ELSE
        v_extended_until := v_auction.extended_until;
    END IF;

    -- Find current top winning bid (if any)
    SELECT * INTO v_top_bid FROM public.bids 
    WHERE auction_id = p_auction_id AND status = 'WINNING' 
    ORDER BY maximum_amount DESC, created_at ASC LIMIT 1;

    IF v_top_bid.id IS NOT NULL THEN
        IF v_top_bid.bidder_id = v_bidder_id THEN
            -- User is already top bidder, update their max bid
            UPDATE public.bids SET maximum_amount = GREATEST(maximum_amount, v_actual_max) WHERE id = v_top_bid.id;
            RETURN jsonb_build_object('success', true, 'message', 'Your max auto-bid threshold updated!');
        END IF;

        -- Proxy bidding calculation against existing top bid
        IF v_actual_max > v_top_bid.maximum_amount THEN
            -- New bidder outbids current top bidder
            v_new_price := LEAST(v_actual_max, v_top_bid.maximum_amount + v_auction.minimum_increment);
            v_winning_bidder_id := v_bidder_id;

            -- Mark previous top bid OUTBID
            UPDATE public.bids SET status = 'OUTBID' WHERE auction_id = p_auction_id AND status = 'WINNING';

            -- Insert new winning bid
            INSERT INTO public.bids (auction_id, bidder_id, amount, maximum_amount, is_auto_bid, status)
            VALUES (p_auction_id, v_bidder_id, v_new_price, v_actual_max, (v_actual_max > v_new_price), 'WINNING');

            -- Notify previous top bidder
            INSERT INTO public.notifications (user_id, type, title, message)
            VALUES (v_top_bid.bidder_id, 'OUTBID', 'You have been outbid!', 'A higher bid was placed on ' || v_product.title);

        ELSE
            -- Existing top bidder retains lead via auto-bid
            v_new_price := LEAST(v_top_bid.maximum_amount, v_actual_max + v_auction.minimum_increment);
            v_winning_bidder_id := v_top_bid.bidder_id;

            -- Insert outbid record for new bidder
            INSERT INTO public.bids (auction_id, bidder_id, amount, maximum_amount, is_auto_bid, status)
            VALUES (p_auction_id, v_bidder_id, p_amount, v_actual_max, false, 'OUTBID');

            -- Update current winning bid price
            UPDATE public.bids SET amount = v_new_price WHERE id = v_top_bid.id;

            -- Notify new bidder they were immediately outbid by auto-bid
            INSERT INTO public.notifications (user_id, type, title, message)
            VALUES (v_bidder_id, 'OUTBID', 'Immediate Auto-Bid Response', 'Your bid was automatically exceeded by the top bidder max limit.');
        END IF;
    ELSE
        -- First bid on auction
        v_new_price := p_amount;
        v_winning_bidder_id := v_bidder_id;

        INSERT INTO public.bids (auction_id, bidder_id, amount, maximum_amount, is_auto_bid, status)
        VALUES (p_auction_id, v_bidder_id, v_new_price, v_actual_max, (v_actual_max > v_new_price), 'WINNING');
    END IF;

    -- Update auction current price, winner_id, total_bids, and extended_until
    UPDATE public.auctions SET
        current_price = v_new_price,
        winner_id = v_winning_bidder_id,
        total_bids = total_bids + 1,
        extended_until = v_extended_until,
        status = CASE WHEN v_extended_until IS NOT NULL THEN 'ENDING' ELSE 'ACTIVE' END,
        updated_at = v_now
    WHERE id = p_auction_id;

    -- Notify seller of new bid
    INSERT INTO public.notifications (user_id, type, title, message)
    VALUES (v_product.seller_id, 'NEW_BID', 'New Bid Received', 'New bid of ₹' || v_new_price::text || ' placed on ' || v_product.title);

    RETURN jsonb_build_object(
        'success', true, 
        'message', CASE WHEN v_winning_bidder_id = v_bidder_id THEN 'Top bid placed successfully!' ELSE 'Bid placed, but existing top auto-bid retains lead.' END,
        'current_price', v_new_price,
        'winner_id', v_winning_bidder_id,
        'extended', (v_extended_until IS NOT NULL)
    );
END;
$$;

-- 2. ATOMIC BUY_NOW RPC
CREATE OR REPLACE FUNCTION public.buy_now(p_auction_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_buyer_id UUID;
    v_auction RECORD;
    v_product RECORD;
    v_chat_id UUID;
BEGIN
    v_buyer_id := auth.uid();
    IF v_buyer_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Authentication required.');
    END IF;

    SELECT * INTO v_auction FROM public.auctions WHERE id = p_auction_id FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Auction not found.');
    END IF;

    SELECT * INTO v_product FROM public.products WHERE id = v_auction.product_id;

    IF v_product.seller_id = v_buyer_id THEN
        RETURN jsonb_build_object('success', false, 'message', 'Sellers cannot buy their own item.');
    END IF;

    IF v_auction.buy_now_price IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Buy Now is not available for this item.');
    END IF;

    IF v_auction.status NOT IN ('ACTIVE', 'ENDING') THEN
        RETURN jsonb_build_object('success', false, 'message', 'This item is no longer available.');
    END IF;

    -- Mark auction closed
    UPDATE public.auctions SET
        current_price = buy_now_price,
        winner_id = v_buyer_id,
        status = 'WINNER_SELECTED',
        updated_at = NOW()
    WHERE id = p_auction_id;

    -- Mark product SOLD
    UPDATE public.products SET
        status = 'SOLD',
        updated_at = NOW()
    WHERE id = v_auction.product_id;

    -- Create or fetch direct Chat record
    INSERT INTO public.chats (product_id, buyer_id, seller_id, last_message, last_message_at)
    VALUES (v_auction.product_id, v_buyer_id, v_product.seller_id, '🎉 Item purchased via Buy Now! Connect to finalize meetup.', NOW())
    ON CONFLICT (product_id, buyer_id) DO UPDATE SET last_message_at = NOW()
    RETURNING id INTO v_chat_id;

    -- Post initial chat system message
    INSERT INTO public.messages (chat_id, sender_id, message, message_type)
    VALUES (v_chat_id, v_buyer_id, '🎉 I bought this item via Buy Now for ₹' || v_auction.buy_now_price::text || '! Let''s arrange a local meetup.', 'system');

    -- Send Notifications
    INSERT INTO public.notifications (user_id, type, title, message)
    VALUES (v_buyer_id, 'AUCTION_WON', 'Purchase Confirmed!', 'You bought ' || v_product.title || ' via Buy Now.');

    INSERT INTO public.notifications (user_id, type, title, message)
    VALUES (v_product.seller_id, 'ITEM_SOLD', 'Item Sold!', v_product.title || ' was bought via Buy Now.');

    RETURN jsonb_build_object('success', true, 'message', 'Buy Now successful! Chat started with seller.', 'chat_id', v_chat_id);
END;
$$;

-- 3. SCHEDULED AUCTION CLOSING FUNCTION (To be executed via pg_cron or Supabase Edge Function)
CREATE OR REPLACE FUNCTION public.close_expired_auctions()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_auction RECORD;
    v_count INT := 0;
BEGIN
    FOR v_auction IN
        SELECT a.*, p.title, p.seller_id
        FROM public.auctions a
        JOIN public.products p ON a.product_id = p.id
        WHERE a.status IN ('ACTIVE', 'ENDING')
          AND NOW() >= COALESCE(a.extended_until, a.end_time)
    LOOP
        v_count := v_count + 1;
        
        IF v_auction.winner_id IS NOT NULL AND (v_auction.reserve_price IS NULL OR v_auction.current_price >= v_auction.reserve_price) THEN
            -- Reserve met or no reserve -> Winner Selected
            UPDATE public.auctions SET status = 'WINNER_SELECTED', updated_at = NOW() WHERE id = v_auction.id;
            UPDATE public.products SET status = 'SOLD', updated_at = NOW() WHERE id = v_auction.product_id;

            -- Notify Winner & Seller
            INSERT INTO public.notifications (user_id, type, title, message)
            VALUES (v_auction.winner_id, 'AUCTION_WON', 'Auction Won!', 'Congratulations! You won the auction for ' || v_auction.title);

            INSERT INTO public.notifications (user_id, type, title, message)
            VALUES (v_auction.seller_id, 'AUCTION_COMPLETED', 'Auction Ended', 'Your auction for ' || v_auction.title || ' ended with a top bid of ₹' || v_auction.current_price::text);

        ELSIF v_auction.winner_id IS NOT NULL AND v_auction.reserve_price IS NOT NULL AND v_auction.current_price < v_auction.reserve_price THEN
            -- Reserve NOT met
            UPDATE public.auctions SET status = 'RESERVE_NOT_MET', updated_at = NOW() WHERE id = v_auction.id;

            INSERT INTO public.notifications (user_id, type, title, message)
            VALUES (v_auction.seller_id, 'RESERVE_NOT_MET', 'Reserve Price Not Met', 'Auction for ' || v_auction.title || ' ended at ₹' || v_auction.current_price::text || ' (Reserve: ₹' || v_auction.reserve_price::text || ').');
        ELSE
            -- No bids -> Expired
            UPDATE public.auctions SET status = 'ENDED', updated_at = NOW() WHERE id = v_auction.id;
            UPDATE public.products SET status = 'EXPIRED', updated_at = NOW() WHERE id = v_auction.product_id;
        END IF;
    END LOOP;

    RETURN v_count;
END;
$$;

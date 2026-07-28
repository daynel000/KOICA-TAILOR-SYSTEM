-- ═══════════════════════════════════════════════════════════════
--  TailorSystem — Separated Customers & Tailors + Chat System
--  Run this in: Supabase Dashboard → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════

-- ─── TABLE 1: customers ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.customers (
    id            UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name     TEXT         NOT NULL,
    phone_number  TEXT         NOT NULL,
    city_location TEXT         DEFAULT '',
    avatar_url    TEXT         DEFAULT '',
    account_tier  TEXT         DEFAULT 'Standard',
    created_at    TIMESTAMPTZ  DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- ─── TABLE 2: tailors ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tailors (
    id                  UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name           TEXT         NOT NULL,
    phone_number        TEXT         NOT NULL,
    shop_name           TEXT         NOT NULL,
    bio                 TEXT         DEFAULT '',
    address             TEXT         DEFAULT '',
    skills              JSONB        DEFAULT '[]',
    availability        JSONB        DEFAULT '{}',
    pricing             JSONB        DEFAULT '{}',
    portfolio_photos    JSONB        DEFAULT '[]',
    store_picture       TEXT         DEFAULT '',
    rating              FLOAT        DEFAULT 0.0,
    total_reviews       INT          DEFAULT 0,
    total_clients       INT          DEFAULT 0,
    years_experience    INT          DEFAULT 0,
    is_verified         BOOLEAN      DEFAULT FALSE,
    location_lat        FLOAT,
    location_lng        FLOAT,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─── TABLE 3: chat_threads (The Relationship) ─────────────────
-- Connects a Customer and a Tailor together for messaging
CREATE TABLE IF NOT EXISTS public.chat_threads (
    id            SERIAL       PRIMARY KEY,
    customer_id   UUID         NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    tailor_id     UUID         NOT NULL REFERENCES public.tailors(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ  DEFAULT NOW(),
    -- Ensure there's only one unique thread between a specific customer and tailor
    UNIQUE(customer_id, tailor_id)
);

-- ─── TABLE 4: messages (The Chats) ────────────────────────────
-- Stores the actual messages inside a chat thread
CREATE TABLE IF NOT EXISTS public.messages (
    id            SERIAL       PRIMARY KEY,
    thread_id     INT          NOT NULL REFERENCES public.chat_threads(id) ON DELETE CASCADE,
    sender_type   TEXT         NOT NULL CHECK (sender_type IN ('customer', 'tailor')),
    message_text  TEXT         NOT NULL,
    is_read       BOOLEAN      DEFAULT FALSE,
    created_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- ─── TABLE 5: body_scans (AI Measurements) ────────────────────
CREATE TABLE IF NOT EXISTS public.body_scans (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID         NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    body_length         FLOAT, -- gitas on sa lawas
    shoulder_width      FLOAT, -- gilapdon sa Abaga
    chest_width         FLOAT, -- gilapdon sa dughan
    chest_circumference FLOAT, -- palibot sa dughan
    arm_length          FLOAT, -- gitas on sa bukton
    bicep_circumference FLOAT, -- palibot sa bukton (biceps)
    waist_circumference FLOAT, -- palibot sa hawak
    hips_circumference  FLOAT, -- palibot sa Hips
    recommended_size    TEXT,
    confidence_percent  INT,
    scanned_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─── TABLE 6: orders (Customer Requests) ──────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id   UUID         NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    tailor_id     UUID         NOT NULL REFERENCES public.tailors(id) ON DELETE CASCADE,
    garment_type  TEXT         NOT NULL,
    status        TEXT         DEFAULT 'pending',
    created_at    TIMESTAMPTZ  DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  DEFAULT NOW()
);


-- ═══════════════════════════════════════════════════════════════
-- Enable Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE public.customers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tailors      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_scans   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders       ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- Grants for Service Role (Backend Access)
-- ═══════════════════════════════════════════════════════════════
GRANT ALL ON TABLE public.customers TO service_role;
GRANT ALL ON TABLE public.tailors TO service_role;
GRANT ALL ON TABLE public.chat_threads TO service_role;
GRANT ALL ON TABLE public.messages TO service_role;
GRANT ALL ON TABLE public.orders TO service_role;
GRANT ALL ON TABLE public.body_scans TO service_role;

-- ═══════════════════════════════════════════════════════════════
-- Auto-create customer or tailor row when a user registers
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    is_tailor BOOLEAN;
BEGIN
    is_tailor := COALESCE((NEW.raw_user_meta_data->>'is_tailor')::BOOLEAN, FALSE);

    IF is_tailor THEN
        INSERT INTO public.tailors (id, full_name, phone_number, shop_name, address)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
            COALESCE(NEW.raw_user_meta_data->>'shop_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'city_location', '')
        );
    ELSE
        INSERT INTO public.customers (id, full_name, phone_number, city_location)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'phone_number', ''),
            COALESCE(NEW.raw_user_meta_data->>'city_location', '')
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

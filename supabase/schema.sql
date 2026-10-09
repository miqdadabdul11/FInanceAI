-- ========================================================
-- AI Personal Finance System - Database Schema
-- Supabase PostgreSQL with Row Level Security (RLS)
-- ========================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL PROFILES (Terkoneksi dengan auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    whatsapp_number TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- 3. TABEL ACCOUNTS (Akun Keuangan: Cash, BCA, Jago, dll)
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- 4. TABEL CATEGORIES (Kategori Pemasukan / Pengeluaran)
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('INCOME', 'EXPENSE')),
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- 5. TABEL TRANSACTIONS (Transaksi Utama)
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'INCOME',
        'EXPENSE',
        'TRANSFER',
        'DEBT',
        'DEBT_PAYMENT',
        'RECEIVABLE',
        'RECEIVABLE_PAYMENT'
    )),
    amount BIGINT NOT NULL CHECK (amount > 0),
    account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
    to_account_id UUID REFERENCES public.accounts(id) ON DELETE RESTRICT,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    description TEXT,
    source TEXT NOT NULL DEFAULT 'WEB' CHECK (source IN ('WEB', 'WHATSAPP')),
    wa_message_id TEXT UNIQUE,
    raw_text TEXT,
    ai_confidence NUMERIC(4, 3),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL,

    -- CONSTRAINT TRANSFER:
    -- Transfer WAJIB memiliki to_account_id dan to_account_id != account_id.
    -- Non-transfer TIDAK BOLEH memiliki to_account_id.
    CONSTRAINT check_transfer_validity CHECK (
        (type = 'TRANSFER' AND to_account_id IS NOT NULL AND to_account_id <> account_id)
        OR
        (type <> 'TRANSFER' AND to_account_id IS NULL)
    )
);

-- 6. VIEW ACCOUNT BALANCES (Saldo dihitung dari transaksi, bukan disimpan ganda)
CREATE OR REPLACE VIEW public.account_balances AS
WITH transaction_flows AS (
    -- Aliran uang masuk / keluar berdasarkan akun utama
    SELECT
        account_id,
        user_id,
        CASE
            WHEN type = 'INCOME' THEN amount
            WHEN type = 'EXPENSE' THEN -amount
            WHEN type = 'TRANSFER' THEN -amount
            WHEN type = 'DEBT' THEN amount            -- Pinjam uang (uang masuk ke kas)
            WHEN type = 'DEBT_PAYMENT' THEN -amount   -- Bayar hutang (uang keluar dari kas)
            WHEN type = 'RECEIVABLE' THEN -amount     -- Pinjamkan uang ke orang (uang keluar)
            WHEN type = 'RECEIVABLE_PAYMENT' THEN amount -- Orang bayar hutang ke kita (uang masuk)
            ELSE 0
        END AS net_flow
    FROM public.transactions
    WHERE deleted_at IS NULL

    UNION ALL

    -- Aliran uang masuk khusus transfer tujuan (to_account_id)
    SELECT
        to_account_id AS account_id,
        user_id,
        amount AS net_flow
    FROM public.transactions
    WHERE type = 'TRANSFER' AND deleted_at IS NULL
)
SELECT
    a.id AS account_id,
    a.user_id,
    a.name AS account_name,
    a.is_default,
    COALESCE(SUM(tf.net_flow), 0)::BIGINT AS balance
FROM public.accounts a
LEFT JOIN transaction_flows tf ON a.id = tf.account_id
GROUP BY a.id, a.user_id, a.name, a.is_default;

-- 7. TABEL BUDGETS (Anggaran Bulanan)
CREATE TABLE IF NOT EXISTS public.budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    monthly_limit BIGINT NOT NULL CHECK (monthly_limit > 0),
    month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
    year INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL,
    UNIQUE(user_id, category_id, month, year)
);

-- 8. TABEL DEBTS (Pencatatan Hutang & Piutang)
CREATE TABLE IF NOT EXISTS public.debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    person_name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('DEBT', 'RECEIVABLE')),
    amount BIGINT NOT NULL CHECK (amount > 0),
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'UNPAID' CHECK (status IN ('UNPAID', 'PARTIALLY_PAID', 'PAID')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- 9. TABEL AI INSIGHTS
CREATE TABLE IF NOT EXISTS public.ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    insight_text TEXT NOT NULL,
    type TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- 10. TABEL WHATSAPP MESSAGES (Idempotensi: Pesan duplikat tidak diproses 2x)
CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wa_message_id TEXT NOT NULL UNIQUE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    phone_number TEXT NOT NULL,
    raw_payload JSONB,
    processed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- 11. TABEL PENDING ACTIONS (Menyimpan konfirmasi jika confidence AI menengah)
CREATE TABLE IF NOT EXISTS public.pending_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('Asia/Jakarta', NOW()) NOT NULL
);

-- ========================================================
-- 12. ROW LEVEL SECURITY (RLS) & POLICIES
-- ========================================================

-- Aktifkan RLS di setiap tabel
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pending_actions ENABLE ROW LEVEL SECURITY;

-- Policy Profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Policy Accounts
CREATE POLICY "Users can manage own accounts" ON public.accounts
    FOR ALL USING (auth.uid() = user_id);

-- Policy Categories
CREATE POLICY "Users can manage own categories" ON public.categories
    FOR ALL USING (auth.uid() = user_id);

-- Policy Transactions
CREATE POLICY "Users can manage own transactions" ON public.transactions
    FOR ALL USING (auth.uid() = user_id);

-- Policy Budgets
CREATE POLICY "Users can manage own budgets" ON public.budgets
    FOR ALL USING (auth.uid() = user_id);

-- Policy Debts
CREATE POLICY "Users can manage own debts" ON public.debts
    FOR ALL USING (auth.uid() = user_id);

-- Policy AI Insights
CREATE POLICY "Users can manage own ai insights" ON public.ai_insights
    FOR ALL USING (auth.uid() = user_id);

-- Policy WhatsApp Messages
CREATE POLICY "Users can manage own wa messages" ON public.whatsapp_messages
    FOR ALL USING (auth.uid() = user_id);

-- Policy Pending Actions
CREATE POLICY "Users can manage own pending actions" ON public.pending_actions
    FOR ALL USING (auth.uid() = user_id);

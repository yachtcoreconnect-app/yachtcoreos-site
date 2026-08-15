-- Stripe fulfillment foundation for the $19 Stew-Captain Form.
-- This migration is committed to the test branch only. Do not apply to production
-- until the human owner approves the schema and the end-to-end Stripe test plan.

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  stripe_checkout_session_id text not null unique,
  stripe_payment_intent_id text unique,
  stripe_customer_id text,
  customer_email text,
  product_key text not null,
  stripe_product_id text,
  stripe_price_id text not null,
  amount_total integer not null check (amount_total >= 0),
  currency text not null,
  payment_status text not null check (payment_status in ('paid', 'unpaid', 'no_payment_required')),
  fulfillment_status text not null default 'pending' check (fulfillment_status in ('pending', 'fulfilled', 'failed', 'refunded', 'revoked')),
  stripe_event_id text,
  fulfilled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists purchases_customer_email_idx on public.purchases (lower(customer_email));
create index if not exists purchases_product_key_idx on public.purchases (product_key);

create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null unique references public.purchases(id) on delete restrict,
  product_key text not null,
  customer_email text,
  status text not null default 'active' check (status in ('active', 'revoked', 'refunded')),
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists entitlements_customer_email_idx on public.entitlements (lower(customer_email));
create index if not exists entitlements_product_key_idx on public.entitlements (product_key);

alter table public.purchases enable row level security;
alter table public.entitlements enable row level security;

-- No public client policies are created intentionally.
-- The webhook must write with the server-side service role key only.
-- Customer-facing access checks should go through a server-side endpoint rather
-- than exposing these tables directly to the browser.

comment on table public.purchases is 'Server-side Stripe purchase records used for idempotent fulfillment.';
comment on table public.entitlements is 'Server-side product access grants derived from verified paid Stripe purchases.';

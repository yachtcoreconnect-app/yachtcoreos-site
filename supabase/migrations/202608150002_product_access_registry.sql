-- Test-branch canonical product registry. No production deployment without approval.
create table if not exists public.products (
  product_key text primary key,
  name text not null,
  price_cents integer not null check (price_cents >= 0),
  currency text not null default 'usd',
  stripe_product_id text unique,
  stripe_price_id text not null unique,
  delivery_type text not null check (delivery_type in ('hosted_tool', 'download')),
  active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;
revoke all on public.products from anon, authenticated;

insert into public.products (
  product_key, name, price_cents, currency, stripe_product_id,
  stripe_price_id, delivery_type, active
) values (
  'yacht-crew-calculator-pack',
  'Yacht Crew Work & Cost Calculator Pack',
  1200,
  'usd',
  'prod_V4uxbooPWjhOM0',
  'price_1U4l7yCAmnuwvjycPKsABDVZ',
  'download',
  true
)
on conflict (product_key) do update set
  name = excluded.name,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  stripe_product_id = excluded.stripe_product_id,
  stripe_price_id = excluded.stripe_price_id,
  delivery_type = excluded.delivery_type,
  active = excluded.active,
  updated_at = now();

create unique index if not exists purchases_stripe_event_id_unique
  on public.purchases (stripe_event_id)
  where stripe_event_id is not null;

comment on table public.products is
  'Server-owned registry of approved Stripe products. Not directly readable by browsers.';

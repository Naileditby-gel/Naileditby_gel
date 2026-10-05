-- Naileditby_gel: ₱100 GCash booking deposit migration
-- Run this AFTER the original supabase-schema.sql.
alter table public.bookings
  add column if not exists deposit_amount numeric(10,2) not null default 100,
  add column if not exists payment_method text not null default 'GCash',
  add column if not exists payment_reference text,
  add column if not exists deposit_status text not null default 'pending' check (deposit_status in ('pending','paid','rejected')),
  add column if not exists deposit_verified_at timestamptz;

create index if not exists bookings_deposit_status_idx on public.bookings(deposit_status);

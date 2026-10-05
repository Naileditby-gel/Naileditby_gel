-- Naileditby_gel: booking status + private customer status page migration
-- Run this ONCE in Supabase SQL Editor after your existing booking/deposit SQL.
create extension if not exists pgcrypto;

alter table public.bookings
  add column if not exists access_token uuid not null default gen_random_uuid(),
  add column if not exists status_reason text,
  add column if not exists customer_message text,
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists bookings_access_token_unique on public.bookings(access_token);

-- Keep updated_at current whenever Gel changes a booking.
create or replace function public.set_booking_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop trigger if exists bookings_set_updated_at on public.bookings;
create trigger bookings_set_updated_at
before update on public.bookings
for each row execute function public.set_booking_updated_at();

-- Customers can retrieve ONLY their own booking when they possess its private token.
create or replace function public.get_booking_status(p_token uuid)
returns table (
  id uuid, name text, appointment_date date, appointment_time time,
  service text, nail_length text, status text, deposit_status text,
  status_reason text, customer_message text, created_at timestamptz, updated_at timestamptz
)
language sql security definer set search_path = public
as $$
  select id,name,appointment_date,appointment_time,service,nail_length,status,deposit_status,
         status_reason,customer_message,created_at,updated_at
  from public.bookings
  where access_token = p_token
  limit 1;
$$;

revoke all on function public.get_booking_status(uuid) from public;
grant execute on function public.get_booking_status(uuid) to anon, authenticated;

-- Customers should not be able to read private/rejected/cancelled bookings directly.
-- Existing confirmed-booking public SELECT policy remains for the calendar.

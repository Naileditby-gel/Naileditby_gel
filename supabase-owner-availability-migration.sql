-- Naileditby_gel: owner availability + schedule protection
-- Run this ONCE in Supabase SQL Editor after the existing booking/status migrations.

create table if not exists public.owner_blocks (
  id uuid primary key default gen_random_uuid(),
  block_date date not null,
  start_time time,
  end_time time,
  reason text,
  created_at timestamptz not null default now(),
  constraint owner_blocks_time_pair check ((start_time is null and end_time is null) or (start_time is not null and end_time is not null and end_time > start_time))
);

alter table public.owner_blocks enable row level security;

drop policy if exists "authenticated can read owner blocks" on public.owner_blocks;
create policy "authenticated can read owner blocks"
on public.owner_blocks for select to authenticated
using (true);

drop policy if exists "authenticated can insert owner blocks" on public.owner_blocks;
create policy "authenticated can insert owner blocks"
on public.owner_blocks for insert to authenticated
with check (true);

drop policy if exists "authenticated can update owner blocks" on public.owner_blocks;
create policy "authenticated can update owner blocks"
on public.owner_blocks for update to authenticated
using (true) with check (true);

drop policy if exists "authenticated can delete owner blocks" on public.owner_blocks;
create policy "authenticated can delete owner blocks"
on public.owner_blocks for delete to authenticated
using (true);

create index if not exists owner_blocks_date_idx on public.owner_blocks(block_date, start_time, end_time);

-- Public customers can ask which standard booking slots are unavailable.
-- This exposes only time slots, never the owner's private reason or block records.
create or replace function public.get_public_booking_availability(p_date date)
returns table (appointment_time time)
language sql
security definer
set search_path = public
as $$
  with slots(appointment_time) as (
    values ('08:00'::time),('10:00'::time),('12:00'::time),('14:00'::time),('16:00'::time)
  )
  select s.appointment_time
  from slots s
  where exists (
    select 1 from public.bookings b
    where b.appointment_date = p_date
      and b.status = 'confirmed'
      and b.appointment_time = s.appointment_time
  )
  or exists (
    select 1 from public.owner_blocks ob
    where ob.block_date = p_date
      and (
        (ob.start_time is null and ob.end_time is null)
        or (s.appointment_time >= ob.start_time and s.appointment_time < ob.end_time)
      )
  )
  order by s.appointment_time;
$$;

revoke all on function public.get_public_booking_availability(date) from public;
grant execute on function public.get_public_booking_availability(date) to anon, authenticated;

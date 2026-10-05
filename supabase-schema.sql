-- Naileditby_gel automatic review approval system
-- Run this once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  rating integer not null check (rating between 1 and 5),
  review text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

-- Customers can submit only pending reviews.
drop policy if exists "public can submit pending reviews" on public.reviews;
create policy "public can submit pending reviews"
on public.reviews for insert to anon, authenticated
with check (status = 'pending');

-- Everyone can see approved reviews only.
drop policy if exists "public can read approved reviews" on public.reviews;
create policy "public can read approved reviews"
on public.reviews for select to anon, authenticated
using (status = 'approved');

-- The private dashboard needs authenticated access to manage all reviews.
-- IMPORTANT: In Supabase Authentication settings, disable public email sign-ups
-- after creating Gel's admin account. This prevents strangers from creating
-- accounts that could manage reviews.
drop policy if exists "authenticated can read all reviews" on public.reviews;
create policy "authenticated can read all reviews"
on public.reviews for select to authenticated
using (true);

drop policy if exists "authenticated can update reviews" on public.reviews;
create policy "authenticated can update reviews"
on public.reviews for update to authenticated
using (true)
with check (status in ('pending','approved','rejected'));

create index if not exists reviews_status_created_idx on public.reviews(status, created_at desc);


-- Online booking calendar
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  appointment_date date not null,
  appointment_time time not null,
  service text not null,
  nail_length text,
  notes text,
  status text not null default 'pending' check (status in ('pending','confirmed','rejected','cancelled')),
  created_at timestamptz not null default now()
);

alter table public.bookings enable row level security;

drop policy if exists "public can submit pending bookings" on public.bookings;
create policy "public can submit pending bookings"
on public.bookings for insert to anon, authenticated
with check (status = 'pending');

drop policy if exists "public can read confirmed bookings" on public.bookings;
create policy "public can read confirmed bookings"
on public.bookings for select to anon, authenticated
using (status = 'confirmed');

drop policy if exists "authenticated can read all bookings" on public.bookings;
create policy "authenticated can read all bookings"
on public.bookings for select to authenticated
using (true);

drop policy if exists "authenticated can update bookings" on public.bookings;
create policy "authenticated can update bookings"
on public.bookings for update to authenticated
using (true)
with check (status in ('pending','confirmed','rejected','cancelled'));

create index if not exists bookings_date_status_idx on public.bookings(appointment_date, status);
create unique index if not exists bookings_confirmed_slot_unique
on public.bookings(appointment_date, appointment_time)
where status = 'confirmed';

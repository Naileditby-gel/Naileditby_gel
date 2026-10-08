-- Naileditby_gel: booking completion + client inspo photos
-- Run ONCE in Supabase SQL Editor. Safe to re-run.

-- Allow the dashboard to move confirmed bookings into Completed.
alter table public.bookings drop constraint if exists bookings_status_check;
alter table public.bookings add constraint bookings_status_check check (status in ('pending','confirmed','rejected','cancelled','completed'));

-- Update the authenticated-owner RLS policy so Completed is allowed.
drop policy if exists "authenticated can update bookings" on public.bookings;
create policy "authenticated can update bookings"
on public.bookings for update to authenticated
using (true)
with check (status in ('pending','confirmed','rejected','cancelled','completed'));

-- Store uploaded client inspo photo paths as JSON metadata on each booking.
alter table public.bookings add column if not exists inspo_files jsonb not null default '[]'::jsonb;

-- Private Supabase Storage bucket for booking inspo photos.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('booking-inspo','booking-inspo',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

-- Clients may upload only image files into this booking-inspo bucket.
-- The bucket is private, so the photos are not publicly browsable.
drop policy if exists "public can upload booking inspo" on storage.objects;
create policy "public can upload booking inspo"
on storage.objects for insert to anon, authenticated
with check (bucket_id = 'booking-inspo' and lower(coalesce(metadata->>'mimetype','')) in ('image/jpeg','image/png','image/webp'));

-- Only authenticated owner accounts can read the private inspo photos.
drop policy if exists "authenticated can read booking inspo" on storage.objects;
create policy "authenticated can read booking inspo"
on storage.objects for select to authenticated
using (bucket_id = 'booking-inspo');

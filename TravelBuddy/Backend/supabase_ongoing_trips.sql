-- TravelBuddy Ongoing Trips (Supabase)
-- Run this in Supabase SQL Editor

create extension if not exists "pgcrypto";

create table if not exists public.ongoing_trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  source_type text not null,
  title text not null,
  subtitle text not null,
  status text not null default 'active',
  total_stops integer not null default 0,
  visited_stops integer not null default 0,
  progress double precision not null default 0,
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table if exists public.ongoing_trips
  add column if not exists completed_at timestamptz;

create index if not exists idx_ongoing_trips_user_id on public.ongoing_trips(user_id);
create index if not exists idx_ongoing_trips_status on public.ongoing_trips(status);
create index if not exists idx_ongoing_trips_updated_at on public.ongoing_trips(updated_at desc);

create table if not exists public.ongoing_trip_stops (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.ongoing_trips(id) on delete cascade,
  day_number integer not null default 1,
  sort_order integer not null default 0,
  title text not null,
  subtitle text not null,
  description text not null,
  latitude double precision not null,
  longitude double precision not null,
  image_name text,
  image_url text,
  planned_date text,
  is_visited boolean not null default false,
  visited_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

alter table if exists public.ongoing_trip_stops
  add column if not exists image_name text;

alter table if exists public.ongoing_trip_stops
  add column if not exists planned_date text;

create index if not exists idx_ongoing_trip_stops_trip_id on public.ongoing_trip_stops(trip_id);
create index if not exists idx_ongoing_trip_stops_visited on public.ongoing_trip_stops(is_visited);

alter table public.ongoing_trips enable row level security;
alter table public.ongoing_trip_stops enable row level security;

drop policy if exists "Public can read ongoing trips" on public.ongoing_trips;

drop policy if exists "Authenticated can read own ongoing trips" on public.ongoing_trips;
create policy "Authenticated can read own ongoing trips"
on public.ongoing_trips
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Public can read ongoing trip stops" on public.ongoing_trip_stops;

drop policy if exists "Authenticated can read own ongoing trip stops" on public.ongoing_trip_stops;
create policy "Authenticated can read own ongoing trip stops"
on public.ongoing_trip_stops
for select
to authenticated
using (exists (select 1 from public.ongoing_trips t where t.id = trip_id and t.user_id = auth.uid()));

drop policy if exists "Authenticated can manage ongoing trips" on public.ongoing_trips;
create policy "Authenticated can manage ongoing trips"
on public.ongoing_trips
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Authenticated can manage ongoing trip stops" on public.ongoing_trip_stops;
create policy "Authenticated can manage ongoing trip stops"
on public.ongoing_trip_stops
for all
to authenticated
using (exists (select 1 from public.ongoing_trips t where t.id = trip_id and t.user_id = auth.uid()))
with check (exists (select 1 from public.ongoing_trips t where t.id = trip_id and t.user_id = auth.uid()));

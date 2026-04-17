-- TravelBuddy Reviews + Wishlist schema
-- Run in Supabase SQL Editor after supabase_schema.sql and supabase_manual_planner.sql

create extension if not exists "pgcrypto";

create table if not exists public.place_reviews (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.manual_planner_places(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reviewer_name text not null,
  rating numeric(2,1) not null check (rating >= 1 and rating <= 5),
  comment text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_place_reviews_place_id_created_at
  on public.place_reviews(place_id, created_at desc);

create table if not exists public.user_wishlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id uuid not null,
  place_source text not null default 'manual_planner_places',
  place_name text,
  place_district text,
  place_image_url text,
  created_at timestamptz not null default timezone('utc', now()),
  constraint user_wishlist_unique unique(user_id, place_id, place_source)
);

alter table public.user_wishlist
  add column if not exists place_source text;

alter table public.user_wishlist
  add column if not exists place_name text;

alter table public.user_wishlist
  add column if not exists place_district text;

alter table public.user_wishlist
  add column if not exists place_image_url text;

update public.user_wishlist
set place_source = 'manual_planner_places'
where place_source is null;

alter table public.user_wishlist
  alter column place_source set default 'manual_planner_places';

alter table public.user_wishlist
  alter column place_source set not null;

alter table public.user_wishlist
  drop constraint if exists user_wishlist_unique;

alter table public.user_wishlist
  add constraint user_wishlist_unique unique(user_id, place_id, place_source);

alter table public.user_wishlist
  drop constraint if exists user_wishlist_place_id_fkey;

create index if not exists idx_user_wishlist_user_id_created_at
  on public.user_wishlist(user_id, created_at desc);

create index if not exists idx_user_wishlist_user_source_created_at
  on public.user_wishlist(user_id, place_source, created_at desc);

alter table public.place_reviews enable row level security;
alter table public.user_wishlist enable row level security;

drop policy if exists "Public can read place reviews" on public.place_reviews;
create policy "Public can read place reviews"
on public.place_reviews
for select
using (true);

drop policy if exists "Authenticated users can insert own reviews" on public.place_reviews;
create policy "Authenticated users can insert own reviews"
on public.place_reviews
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own reviews" on public.place_reviews;
create policy "Users can update own reviews"
on public.place_reviews
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own reviews" on public.place_reviews;
create policy "Users can delete own reviews"
on public.place_reviews
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can read own wishlist" on public.user_wishlist;
create policy "Users can read own wishlist"
on public.user_wishlist
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own wishlist" on public.user_wishlist;
create policy "Users can insert own wishlist"
on public.user_wishlist
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own wishlist" on public.user_wishlist;
create policy "Users can delete own wishlist"
on public.user_wishlist
for delete
to authenticated
using (auth.uid() = user_id);

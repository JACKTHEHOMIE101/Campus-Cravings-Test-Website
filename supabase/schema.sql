-- ============================================================
-- Campus Cravings — Supabase Schema
-- Run this in: Supabase Dashboard > SQL Editor
-- ============================================================

-- PROFILES TABLE
-- Extends auth.users with role info
create table if not exists public.profiles (
    id          uuid primary key references auth.users(id) on delete cascade,
    email       text,
    role        text not null default 'student'
                    check (role in ('student', 'bar_owner', 'admin')),
    created_at  timestamptz default now()
);

-- RLS
alter table public.profiles enable row level security;

-- Drop existing policies before recreating (safe to re-run)
drop policy if exists "Users can view own profile"   on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Allow profile insert on signup" on public.profiles;
drop policy if exists "Admins can view all profiles" on public.profiles;

-- Users can read their own profile
create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- Allow insert during signup (service role or authenticated)
create policy "Allow profile insert on signup"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Admins can read all profiles
create policy "Admins can view all profiles"
    on public.profiles for select
    using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- ============================================================
-- AUTO-CREATE PROFILE ON SIGNUP (optional trigger)
-- Automatically inserts a profile row when a user signs up
-- so there's always a profile even if the client-side insert fails
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, email, role)
    values (new.id, new.email, 'student')
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- ============================================================
-- ONBOARDING RESPONSES TABLE
-- Stores each student's one-time poll answers for analytics
-- and personalized ranking weights.
-- ============================================================
create table if not exists public.onboarding_responses (
    id                       uuid primary key default gen_random_uuid(),
    user_id                  uuid references auth.users(id) on delete cascade not null unique,

    -- Section 1 — Core Personalization
    year_in_school           text check (year_in_school in ('freshman','sophomore','junior','senior','grad')),
    night_preference         text check (night_preference in ('wild','social','chill','food')),
    budget                   text check (budget in ('under_15','15_30','30_50','no_limit')),
    bar_priorities           text[],            -- up to 2 values from enum list

    -- Section 2 — Ranking Inputs
    bars_visited             text[],            -- multi-select bar slugs
    favorite_bar             text,
    least_favorite_bar       text,

    -- Section 3 — Freshman-Friendly Modeling
    social_comfort           text check (social_comfort in ('yes','sometimes','no')),
    social_preference        text check (social_preference in ('meet_new','tight_group','doesnt_matter')),

    -- Section 4 — Value & Spending
    drink_specials_influence text check (drink_specials_influence in ('always','sometimes','rarely','never')),

    -- Section 5 — Behavioral Data
    decision_method          text check (decision_method in ('group_vote','follow_friend','social_media','walk_in','deals')),
    crowd_preference         text check (crowd_preference in ('yes','not_too_packed','no')),

    created_at               timestamptz default now() not null
);

-- RLS
alter table public.onboarding_responses enable row level security;

drop policy if exists "Users can insert own onboarding"  on public.onboarding_responses;
drop policy if exists "Users can view own onboarding"    on public.onboarding_responses;
drop policy if exists "Admins can view all onboarding"   on public.onboarding_responses;

-- Users can insert their own response (once, enforced by UNIQUE on user_id)
create policy "Users can insert own onboarding"
    on public.onboarding_responses for insert
    with check (auth.uid() = user_id);

-- Users can read their own response
create policy "Users can view own onboarding"
    on public.onboarding_responses for select
    using (auth.uid() = user_id);

-- Admins can read all responses (for analytics)
create policy "Admins can view all onboarding"
    on public.onboarding_responses for select
    using (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role = 'admin'
        )
    );

-- Users can update their own response (required for upsert)
drop policy if exists "Users can update own onboarding" on public.onboarding_responses;
create policy "Users can update own onboarding"
    on public.onboarding_responses for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- ============================================================
-- ANALYTICS VIEWS (run these separately in SQL Editor)
-- Query these in Supabase Studio → Table Editor for raw data
-- ============================================================

-- Year distribution
create or replace view public.v_year_distribution as
select
    coalesce(year_in_school, 'skipped') as year,
    count(*)                             as responses,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from public.onboarding_responses
group by year_in_school
order by responses desc;

-- Night preference
create or replace view public.v_night_preference as
select
    coalesce(night_preference, 'skipped') as preference,
    count(*)                               as responses,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from public.onboarding_responses
group by night_preference
order by responses desc;

-- Budget distribution
create or replace view public.v_budget_distribution as
select
    coalesce(budget, 'skipped') as budget_range,
    count(*)                     as responses,
    round(count(*) * 100.0 / sum(count(*)) over (), 1) as pct
from public.onboarding_responses
group by budget
order by responses desc;

-- Bar priorities (unnested from array)
create or replace view public.v_bar_priorities as
select
    priority,
    count(*) as times_selected
from public.onboarding_responses, unnest(bar_priorities) as priority
group by priority
order by times_selected desc;

-- Bars visited (unnested from array)
create or replace view public.v_bars_visited as
select
    bar,
    count(*) as visit_count
from public.onboarding_responses, unnest(bars_visited) as bar
group by bar
order by visit_count desc;

-- Favorite bars
create or replace view public.v_favorite_bars as
select
    favorite_bar              as bar,
    count(*)                  as times_favorited,
    round(count(*) * 100.0 / (select count(*) from public.onboarding_responses where favorite_bar is not null), 1) as pct
from public.onboarding_responses
where favorite_bar is not null
group by favorite_bar
order by times_favorited desc;

-- Least favorite bars
create or replace view public.v_least_favorite_bars as
select
    least_favorite_bar        as bar,
    count(*)                  as times_disliked,
    round(count(*) * 100.0 / (select count(*) from public.onboarding_responses where least_favorite_bar is not null), 1) as pct
from public.onboarding_responses
where least_favorite_bar is not null
group by least_favorite_bar
order by times_disliked desc;

-- Full behavioral summary
create or replace view public.v_behavioral_summary as
select
    decision_method,
    crowd_preference,
    drink_specials_influence,
    social_comfort,
    social_preference,
    count(*) as user_count
from public.onboarding_responses
group by decision_method, crowd_preference, drink_specials_influence, social_comfort, social_preference
order by user_count desc;

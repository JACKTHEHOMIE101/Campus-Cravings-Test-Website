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

-- Module 2: customer monthly utility entries (water/electricity)
-- Run this once in the Supabase SQL editor (Dashboard -> SQL Editor -> New query).

create table if not exists public.customer_utility_entries (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  utility text not null check (utility in ('water', 'electricity')),
  period_month date not null,
  value numeric not null check (value >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, utility, period_month)
);

-- period_month must always be stored as the 1st of the month.
alter table public.customer_utility_entries
  add constraint customer_utility_entries_period_is_month_start
  check (period_month = date_trunc('month', period_month)::date);

create index if not exists customer_utility_entries_user_idx
  on public.customer_utility_entries (user_id, utility, period_month desc);

alter table public.customer_utility_entries enable row level security;

create policy "Users can read their own utility entries"
  on public.customer_utility_entries for select
  using (auth.uid() = user_id);

create policy "Users can insert their own utility entries"
  on public.customer_utility_entries for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own utility entries"
  on public.customer_utility_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own utility entries"
  on public.customer_utility_entries for delete
  using (auth.uid() = user_id);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger customer_utility_entries_set_updated_at
  before update on public.customer_utility_entries
  for each row execute function public.set_updated_at();

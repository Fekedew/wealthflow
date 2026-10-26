-- WealthFlow schema: per-user data protected by RLS, with realtime enabled.

create table public.transactions (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type text not null check (type in ('income', 'expense')),
  amount numeric(14,2) not null check (amount > 0),
  category text not null,
  note text not null default '',
  occurred_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create table public.budgets (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  category text not null,
  monthly_limit numeric(14,2) not null check (monthly_limit > 0),
  updated_at timestamptz not null default now(),
  unique (user_id, category)
);

create table public.goals (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  target numeric(14,2) not null check (target > 0),
  saved numeric(14,2) not null default 0 check (saved >= 0),
  deadline date,
  updated_at timestamptz not null default now()
);

create index transactions_user_date_idx on public.transactions (user_id, occurred_at desc);
create index budgets_user_idx on public.budgets (user_id);
create index goals_user_idx on public.goals (user_id);

alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.goals enable row level security;

create policy "own transactions" on public.transactions
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own budgets" on public.budgets
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own goals" on public.goals
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

alter publication supabase_realtime add table public.transactions, public.budgets, public.goals;

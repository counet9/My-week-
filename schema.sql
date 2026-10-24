-- Ma Semaine V4 — migration additive Supabase.
-- Ce script ne supprime aucune table ni aucune donnée existante.
-- Avant exécution, vérifie les types et policies actuels dans Supabase.

create extension if not exists pgcrypto;

-- Création uniquement si les tables n'existent pas déjà.
create table if not exists public.recurring_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day text not null,
  title text not null,
  category text not null default 'Autre',
  priority boolean not null default false,
  created_at timestamptz not null default now(),
  starts_on date
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  day text not null,
  title text not null,
  category text not null default 'Autre',
  priority boolean not null default false,
  completed boolean not null default false,
  recurring_id uuid references public.recurring_tasks(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Mise à niveau non destructive des tables existantes.
alter table public.recurring_tasks add column if not exists starts_on date;
alter table public.recurring_tasks add column if not exists category text default 'Autre';
alter table public.recurring_tasks add column if not exists priority boolean default false;
alter table public.recurring_tasks add column if not exists created_at timestamptz default now();

alter table public.tasks add column if not exists week_start date;
alter table public.tasks add column if not exists day text;
alter table public.tasks add column if not exists title text;
alter table public.tasks add column if not exists category text default 'Autre';
alter table public.tasks add column if not exists priority boolean default false;
alter table public.tasks add column if not exists completed boolean default false;
alter table public.tasks add column if not exists recurring_id uuid;
alter table public.tasks add column if not exists created_at timestamptz default now();

create index if not exists tasks_user_week_idx on public.tasks(user_id, week_start);
create index if not exists tasks_recurring_id_idx on public.tasks(recurring_id);
create index if not exists recurring_tasks_user_idx on public.recurring_tasks(user_id);

-- RLS obligatoire. Les policies restrictives servent de garde-fou si d'anciennes
-- policies permissives plus larges existent déjà. Elles ne remplacent pas un audit des policies.
alter table public.tasks enable row level security;
alter table public.recurring_tasks enable row level security;

drop policy if exists tasks_select_own on public.tasks;
drop policy if exists tasks_insert_own on public.tasks;
drop policy if exists tasks_update_own on public.tasks;
drop policy if exists tasks_delete_own on public.tasks;
drop policy if exists tasks_owner_guard on public.tasks;
create policy tasks_select_own on public.tasks for select to authenticated using (auth.uid() = user_id);
create policy tasks_insert_own on public.tasks for insert to authenticated with check (auth.uid() = user_id);
create policy tasks_update_own on public.tasks for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy tasks_delete_own on public.tasks for delete to authenticated using (auth.uid() = user_id);
create policy tasks_owner_guard on public.tasks as restrictive for all to public using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists recurring_tasks_select_own on public.recurring_tasks;
drop policy if exists recurring_tasks_insert_own on public.recurring_tasks;
drop policy if exists recurring_tasks_update_own on public.recurring_tasks;
drop policy if exists recurring_tasks_delete_own on public.recurring_tasks;
drop policy if exists recurring_tasks_owner_guard on public.recurring_tasks;
create policy recurring_tasks_select_own on public.recurring_tasks for select to authenticated using (auth.uid() = user_id);
create policy recurring_tasks_insert_own on public.recurring_tasks for insert to authenticated with check (auth.uid() = user_id);
create policy recurring_tasks_update_own on public.recurring_tasks for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy recurring_tasks_delete_own on public.recurring_tasks for delete to authenticated using (auth.uid() = user_id);
create policy recurring_tasks_owner_guard on public.recurring_tasks as restrictive for all to public using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Active le flux Realtime pour que l'autre appareil voie les mises à jour.
-- Ne fait rien si la publication ou la table ne sont pas présentes.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tasks') then
      execute 'alter publication supabase_realtime add table public.tasks';
    end if;
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'recurring_tasks') then
      execute 'alter publication supabase_realtime add table public.recurring_tasks';
    end if;
  end if;
end $$;

-- Contrôle des policies installées (et repérage d'éventuelles anciennes policies trop larges).
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename in ('tasks','recurring_tasks')
order by tablename, policyname;

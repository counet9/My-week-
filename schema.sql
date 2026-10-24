-- MA SEMAINE V4 STABLE — migration Supabase non destructive
-- À exécuter dans le SQL Editor du projet Supabase EXISTANT.
-- Ce script ne supprime ni tables, ni comptes, ni tâches.
-- Convention de la V4 : day = 0 (Lundi) ... 6 (Dimanche).

begin;

create extension if not exists pgcrypto;

-- Les CREATE TABLE servent uniquement à une première installation.
-- Si les tables existent déjà, elles ne sont pas recréées ni vidées.
create table if not exists public.recurring_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day smallint not null,
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
  day smallint not null,
  title text not null,
  category text not null default 'Autre',
  priority boolean not null default false,
  completed boolean not null default false,
  recurring_id uuid references public.recurring_tasks(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Ajout des colonnes qui peuvent manquer dans une base V3/V4 antérieure.
-- ADD COLUMN IF NOT EXISTS conserve les colonnes et valeurs déjà présentes.
alter table public.recurring_tasks add column if not exists day smallint;
alter table public.recurring_tasks add column if not exists title text;
alter table public.recurring_tasks add column if not exists starts_on date;
alter table public.recurring_tasks add column if not exists category text default 'Autre';
alter table public.recurring_tasks add column if not exists priority boolean default false;
alter table public.recurring_tasks add column if not exists created_at timestamptz default now();
alter table public.tasks add column if not exists day smallint;
alter table public.tasks add column if not exists title text;
alter table public.tasks add column if not exists week_start date;
alter table public.tasks add column if not exists category text default 'Autre';
alter table public.tasks add column if not exists priority boolean default false;
alter table public.tasks add column if not exists completed boolean default false;
alter table public.tasks add column if not exists recurring_id uuid;
alter table public.tasks add column if not exists created_at timestamptz default now();

-- Si les anciennes données utilisent clairement 1=Lundi ... 7=Dimanche
-- (au moins un 7 et aucun 0 dans les deux tables), normalise les deux tables
-- ensemble en 0=Lundi ... 6=Dimanche. Sinon les valeurs existantes sont conservées.
do $$
declare
  has_zero boolean;
  has_seven boolean;
  task_type text;
  recurring_type text;
begin
  select data_type into task_type from information_schema.columns
   where table_schema='public' and table_name='tasks' and column_name='day';
  select data_type into recurring_type from information_schema.columns
   where table_schema='public' and table_name='recurring_tasks' and column_name='day';

  if task_type in ('smallint','integer','bigint') and recurring_type in ('smallint','integer','bigint') then
    execute 'select exists(select 1 from public.tasks where day = 0) or exists(select 1 from public.recurring_tasks where day = 0)' into has_zero;
    execute 'select exists(select 1 from public.tasks where day = 7) or exists(select 1 from public.recurring_tasks where day = 7)' into has_seven;
    if coalesce(has_seven,false) and not coalesce(has_zero,false) then
      update public.tasks set day = day - 1 where day between 1 and 7;
      update public.recurring_tasks set day = day - 1 where day between 1 and 7;
    end if;
  end if;
end $$;


-- Convertit un ancien champ day text (par ex. 'Lundi') en numéro de jour.
-- Les colonnes déjà numériques sont conservées telles quelles.
do $$
declare
  tbl text;
  col_type text;
  invalid_values boolean;
begin
  foreach tbl in array array['tasks','recurring_tasks'] loop
    select data_type into col_type
      from information_schema.columns
     where table_schema = 'public' and table_name = tbl and column_name = 'day';

    if col_type is null then
      raise exception 'Colonne public.%.day introuvable. Vérifie la structure de la table avant de continuer.', tbl;
    elsif col_type in ('text','character varying','character') then
      execute format($check$
        select exists (
          select 1 from public.%I
           where day is not null
             and lower(trim(day::text)) not in (
               'lundi','monday','mon','mardi','tuesday','tue','mercredi','wednesday','wed',
               'jeudi','thursday','thu','vendredi','friday','fri','samedi','saturday','sat',
               'dimanche','sunday','sun','0','1','2','3','4','5','6','7'
             )
        )
      $check$, tbl) into invalid_values;
      if coalesce(invalid_values,false) then
        raise exception 'Valeurs inattendues dans public.%.day. Le script est interrompu sans convertir cette colonne ; inspecte les valeurs avant de réessayer.', tbl;
      end if;
      execute format($sql$
        alter table public.%I alter column day type smallint using (
          case lower(trim(day::text))
            when 'lundi' then 0 when 'monday' then 0 when 'mon' then 0
            when 'mardi' then 1 when 'tuesday' then 1 when 'tue' then 1
            when 'mercredi' then 2 when 'wednesday' then 2 when 'wed' then 2
            when 'jeudi' then 3 when 'thursday' then 3 when 'thu' then 3
            when 'vendredi' then 4 when 'friday' then 4 when 'fri' then 4
            when 'samedi' then 5 when 'saturday' then 5 when 'sat' then 5
            when 'dimanche' then 6 when 'sunday' then 6 when 'sun' then 6
            when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3
            when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7
            else null
          end
        )::smallint
      $sql$, tbl);
    elsif col_type in ('integer','bigint','smallint') then
      -- Rien à convertir : le frontend envoie désormais un nombre, jamais 'Lundi'.
      null;
    else
      raise exception 'Type inattendu pour public.%.day : %. Vérifie la colonne avant de continuer.', tbl, col_type;
    end if;
  end loop;
end $$;

-- Valeurs par défaut pour les nouvelles lignes, sans écraser les lignes existantes.
alter table public.recurring_tasks alter column category set default 'Autre';
alter table public.recurring_tasks alter column priority set default false;
alter table public.recurring_tasks alter column created_at set default now();
alter table public.tasks alter column category set default 'Autre';
alter table public.tasks alter column priority set default false;
alter table public.tasks alter column completed set default false;
alter table public.tasks alter column created_at set default now();

create index if not exists tasks_user_week_idx on public.tasks(user_id, week_start);
create index if not exists tasks_recurring_id_idx on public.tasks(recurring_id);
create index if not exists recurring_tasks_user_idx on public.recurring_tasks(user_id);

-- Sécurité : chaque utilisateur ne peut agir que sur ses propres lignes.
-- Les policies nommées ci-dessous sont recréées de façon idempotente.
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

-- Activer Realtime si la publication Supabase existe déjà.
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

notify pgrst, 'reload schema';

commit;

-- Contrôle final : affiche les policies actuellement présentes sur les deux tables.
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename in ('tasks','recurring_tasks')
order by tablename, policyname;

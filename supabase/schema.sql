create extension if not exists "pgcrypto";

create table if not exists profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists exercises (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  name_ko text not null,
  muscle_group integer not null,
  equipment integer not null,
  is_custom boolean not null default false,
  thumbnail_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_status integer not null default 0,
  check ((is_custom and user_id is not null) or (not is_custom and user_id is null))
);

create table if not exists routines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  is_template boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_status integer not null default 0
);

create table if not exists routine_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  routine_id uuid not null references routines(id) on delete cascade,
  exercise_id uuid not null references exercises(id),
  item_order integer not null,
  target_sets integer not null,
  target_reps integer not null,
  target_weight double precision not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_status integer not null default 0
);

create table if not exists workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  routine_id uuid references routines(id),
  party_id uuid,
  started_at timestamptz not null,
  ended_at timestamptz,
  memo text,
  total_volume double precision not null default 0,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_status integer not null default 0
);

create table if not exists workout_sets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references workout_sessions(id) on delete cascade,
  exercise_id uuid not null references exercises(id),
  set_index integer not null,
  weight double precision not null,
  reps integer not null,
  rpe double precision,
  is_warmup boolean not null default false,
  is_completed boolean not null default false,
  rest_seconds integer not null default 0,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  sync_status integer not null default 0
);

alter table profiles enable row level security;
alter table exercises enable row level security;
alter table routines enable row level security;
alter table routine_items enable row level security;
alter table workout_sessions enable row level security;
alter table workout_sets enable row level security;

create policy "profiles own rows" on profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "exercises read seed or own" on exercises for select using (not is_custom or auth.uid() = user_id);
create policy "exercises own custom write" on exercises for all using (auth.uid() = user_id and is_custom) with check (auth.uid() = user_id and is_custom);
create policy "routines own rows" on routines for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "routine items own rows" on routine_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sessions own rows" on workout_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sets own rows" on workout_sets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

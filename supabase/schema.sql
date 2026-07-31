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

-- 닉네임/사진은 공개 정보다. 이게 없으면 남의 이름이 전부 '회원'으로 보이고 사용자 검색도 빈다.
drop policy if exists "profiles authenticated read" on profiles;
create policy "profiles authenticated read" on profiles for select to authenticated using (true);
create policy "profiles own rows" on profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "exercises read seed or own" on exercises for select using (not is_custom or auth.uid() = user_id);
create policy "exercises own custom write" on exercises for all using (auth.uid() = user_id and is_custom) with check (auth.uid() = user_id and is_custom);
create policy "routines own rows" on routines for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "routine items own rows" on routine_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sessions own rows" on workout_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "sets own rows" on workout_sets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  caption text,
  media_url text not null,
  media_kind text not null check (media_kind in ('photo', 'video')),
  body_part text,
  location text,
  session_id uuid null,
  volume_kg numeric null,
  duration_min int null,
  pr_label text null,
  xp int null,
  created_at timestamptz not null default now()
);

create table if not exists post_likes (
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id)
);

alter table posts enable row level security;
alter table post_likes enable row level security;
alter table follows enable row level security;

create policy "posts authenticated read" on posts for select to authenticated using (true);
create policy "posts own insert" on posts for insert to authenticated with check (auth.uid() = user_id);
create policy "posts own update" on posts for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "posts own delete" on posts for delete to authenticated using (auth.uid() = user_id);
create policy "post likes authenticated read" on post_likes for select to authenticated using (true);
create policy "post likes own write" on post_likes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "follows authenticated read" on follows for select to authenticated using (true);
create policy "follows own write" on follows for all to authenticated using (auth.uid() = follower_id) with check (auth.uid() = follower_id);

-- Create the `post-media` Storage bucket in the Supabase dashboard with public read,
-- or insert it into storage.buckets and add owner-only upload/update/delete policies.

alter table profiles add column if not exists avatar_url text;
alter table profiles add column if not exists bio text;

-- Profile avatars use the existing public-read `post-media` bucket at
-- `<userId>/avatar/<uuid>.<ext>` and therefore use the existing owner write policy.
create table if not exists post_comments (id uuid primary key default gen_random_uuid(), post_id uuid not null references posts(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, body text not null, created_at timestamptz not null default now());
create table if not exists post_saves (post_id uuid not null references posts(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, created_at timestamptz not null default now(), primary key (post_id, user_id));
alter table post_comments enable row level security;
alter table post_saves enable row level security;
drop policy if exists "comments authenticated read" on post_comments;
drop policy if exists "comments own write" on post_comments;
drop policy if exists "saves own rows" on post_saves;
create policy "comments authenticated read" on post_comments for select to authenticated using (true);
create policy "comments own write" on post_comments for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "saves own rows" on post_saves for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create table if not exists parties (id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade, name text not null, description text, region text, focus text, max_members int not null default 8, is_public boolean not null default true, join_code text unique, created_at timestamptz not null default now());
create table if not exists party_members (party_id uuid not null references parties(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,role text not null default 'member',joined_at timestamptz not null default now(),primary key(party_id,user_id));
create table if not exists party_messages (id uuid primary key default gen_random_uuid(),party_id uuid not null references parties(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,body text not null,created_at timestamptz not null default now());
create or replace function public.is_party_member(p uuid) returns boolean language sql security definer stable set search_path = public as $$ select exists(select 1 from public.party_members where party_id=p and user_id=auth.uid()) $$;
alter table parties enable row level security; alter table party_members enable row level security; alter table party_messages enable row level security;
drop policy if exists "party read" on parties; drop policy if exists "party write" on parties; drop policy if exists "member read" on party_members; drop policy if exists "member write" on party_members; drop policy if exists "message read" on party_messages; drop policy if exists "message write" on party_messages;
create policy "party read" on parties for select to authenticated using (is_public or public.is_party_member(id)); create policy "party write" on parties for all to authenticated using (auth.uid()=owner_id) with check(auth.uid()=owner_id);
create policy "member read" on party_members for select to authenticated using (public.is_party_member(party_id)); create policy "member write" on party_members for insert to authenticated with check(auth.uid()=user_id); create policy "member leave" on party_members for delete to authenticated using(auth.uid()=user_id);
create policy "message read" on party_messages for select to authenticated using(public.is_party_member(party_id)); create policy "message write" on party_messages for insert to authenticated with check(public.is_party_member(party_id) and auth.uid()=user_id);

-- 알림
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  actor_id uuid references auth.users(id) on delete cascade,
  post_id uuid references posts(id) on delete cascade,
  party_id uuid,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
alter table notifications enable row level security;
drop policy if exists "notifications own read" on notifications;
create policy "notifications own read" on notifications for select to authenticated using (auth.uid() = user_id);
drop policy if exists "notifications own update" on notifications;
create policy "notifications own update" on notifications for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "notifications insert" on notifications;
create policy "notifications insert" on notifications for insert to authenticated with check (true);

create table if not exists post_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);
create table if not exists user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);
alter table post_reports enable row level security;
alter table user_blocks enable row level security;
drop policy if exists "post reports own select" on post_reports;
drop policy if exists "post reports own insert" on post_reports;
drop policy if exists "user blocks own rows" on user_blocks;
create policy "post reports own select" on post_reports for select to authenticated using (auth.uid() = reporter_id);
create policy "post reports own insert" on post_reports for insert to authenticated with check (auth.uid() = reporter_id);
create policy "user blocks own rows" on user_blocks for all to authenticated using (auth.uid() = blocker_id) with check (auth.uid() = blocker_id);

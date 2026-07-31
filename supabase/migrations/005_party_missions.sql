-- 005: 파티 주간 미션
-- 운동 기록 자체는 개인 소유라 파티원이 볼 수 없다. 파티에 공유할 활동만
-- 따로 남겨 미션 진행과 파티원 성장을 계산한다.

alter table parties add column if not exists weekly_goal int;
alter table parties drop constraint if exists parties_weekly_goal_range;
alter table parties add constraint parties_weekly_goal_range
  check (weekly_goal is null or weekly_goal between 1 and 100) not valid;

create table if not exists party_activities (
  id uuid primary key default gen_random_uuid(),
  party_id uuid not null references parties(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null,
  volume_kg numeric not null default 0,
  xp int not null default 0,
  performed_at timestamptz not null default now(),
  -- 같은 운동이 두 번 집계되지 않게 한다.
  unique (party_id, session_id)
);

create index if not exists party_activities_party_time
  on party_activities (party_id, performed_at desc);

alter table party_activities enable row level security;

drop policy if exists "party activity read" on party_activities;
create policy "party activity read" on party_activities for select to authenticated
  using (public.is_party_member(party_id));

drop policy if exists "party activity write" on party_activities;
create policy "party activity write" on party_activities for insert to authenticated
  with check (auth.uid() = user_id and public.is_party_member(party_id));

drop policy if exists "party activity delete" on party_activities;
create policy "party activity delete" on party_activities for delete to authenticated
  using (auth.uid() = user_id);

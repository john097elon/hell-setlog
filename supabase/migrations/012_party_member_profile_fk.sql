-- 파티 멤버와 프로필을 한 번에 읽을 수 있게 한다.
--
-- party_members.user_id는 auth.users만 참조했다. PostgREST는 외래키가 있어야
-- profiles(...)를 함께 가져오므로, 멤버 목록과 주간 미션 질의가 매번 실패했다.
alter table public.party_members
  drop constraint if exists party_members_user_id_profile_fkey;
alter table public.party_members
  add constraint party_members_user_id_profile_fkey
  foreign key (user_id) references public.profiles(user_id) on delete cascade;

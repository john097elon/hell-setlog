-- 003: 가입 즉시 프로필 생성, 팔로워 목록 조회 지원

-- ─────────────────────────────────────────────────────────────
-- 1. 프로필은 가입 시점에 만든다
--    지금까지는 본인이 앱을 열 때만 만들어져, 프로필이 없는 계정의 닉네임이
--    다른 사람 화면에서 전부 '회원'으로 보였다.
-- ─────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_nickname text;
begin
  v_nickname := btrim(coalesce(new.raw_user_meta_data ->> 'nickname', ''));
  if v_nickname = '' then
    v_nickname := split_part(coalesce(new.email, 'user'), '@', 1);
  end if;
  -- 길이 제약(1~20)에 맞춘다.
  v_nickname := left(v_nickname, 20);
  insert into public.profiles (user_id, nickname)
  values (new.id, v_nickname)
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists trg_new_user on auth.users;
create trigger trg_new_user after insert on auth.users
  for each row execute function public.handle_new_user();

-- 이미 가입했지만 프로필이 없는 계정을 채운다.
insert into public.profiles (user_id, nickname)
select u.id,
       left(
         coalesce(
           nullif(btrim(u.raw_user_meta_data ->> 'nickname'), ''),
           split_part(coalesce(u.email, 'user'), '@', 1)
         ),
         20
       )
from auth.users u
left join public.profiles p on p.user_id = u.id
where p.user_id is null;

-- ─────────────────────────────────────────────────────────────
-- 2. 팔로우 목록. 서로의 팔로워/팔로잉을 볼 수 있어야 한다.
-- ─────────────────────────────────────────────────────────────
drop policy if exists "follows authenticated read" on follows;
create policy "follows authenticated read" on follows for select to authenticated
  using (
    not public.is_blocked(auth.uid(), follower_id)
    and not public.is_blocked(auth.uid(), following_id)
  );

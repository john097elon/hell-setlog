-- 002: 알림 생성, 파티 가입 검증, 차단 반영, 입력 길이 제한
-- 재실행 가능하도록 모든 정책·트리거를 drop 후 생성한다.

-- ─────────────────────────────────────────────────────────────
-- 1. 알림: 클라이언트가 직접 만들 수 없고 실제 활동에서만 생긴다
-- ─────────────────────────────────────────────────────────────
drop policy if exists "notifications insert" on notifications;

create or replace function public.create_notification(
  p_user uuid,
  p_actor uuid,
  p_kind text,
  p_post uuid default null,
  p_party uuid default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  -- 내 활동으로 나에게 알림을 보내지 않는다.
  if p_user is null or p_actor is null or p_user = p_actor then
    return;
  end if;
  insert into notifications (user_id, actor_id, kind, post_id, party_id)
  values (p_user, p_actor, p_kind, p_post, p_party);
end $$;

create or replace function public.on_post_liked()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  select user_id into v_owner from posts where id = new.post_id;
  perform public.create_notification(v_owner, new.user_id, 'like', new.post_id);
  return new;
end $$;

create or replace function public.on_post_commented()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  select user_id into v_owner from posts where id = new.post_id;
  perform public.create_notification(v_owner, new.user_id, 'comment', new.post_id);
  return new;
end $$;

create or replace function public.on_followed()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.create_notification(new.following_id, new.follower_id, 'follow');
  return new;
end $$;

create or replace function public.on_party_joined()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  select owner_id into v_owner from parties where id = new.party_id;
  perform public.create_notification(
    v_owner, new.user_id, 'party_join', null, new.party_id
  );
  return new;
end $$;

drop trigger if exists trg_post_liked on post_likes;
create trigger trg_post_liked after insert on post_likes
  for each row execute function public.on_post_liked();

drop trigger if exists trg_post_commented on post_comments;
create trigger trg_post_commented after insert on post_comments
  for each row execute function public.on_post_commented();

drop trigger if exists trg_followed on follows;
create trigger trg_followed after insert on follows
  for each row execute function public.on_followed();

drop trigger if exists trg_party_joined on party_members;
create trigger trg_party_joined after insert on party_members
  for each row execute function public.on_party_joined();

-- ─────────────────────────────────────────────────────────────
-- 2. 파티 가입: 정원·비공개·역할을 서버에서 검증한다
-- ─────────────────────────────────────────────────────────────

-- 파티를 만들면 소유자를 멤버로 넣는다. 클라이언트가 직접 넣지 않는다.
create or replace function public.on_party_created()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into party_members (party_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict do nothing;
  return new;
end $$;

drop trigger if exists trg_party_created on parties;
create trigger trg_party_created after insert on parties
  for each row execute function public.on_party_created();

-- 정원·코드·중복을 잠근 상태에서 검사하고 역할은 항상 member로 고정한다.
create or replace function public.join_party(p_party uuid, p_code text default null)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_party parties%rowtype;
  v_count int;
  v_user uuid := auth.uid();
begin
  if v_user is null then return 'unauthorized'; end if;
  select * into v_party from parties where id = p_party for update;
  if not found then return 'not_found'; end if;
  if exists (
    select 1 from party_members where party_id = p_party and user_id = v_user
  ) then
    return 'ok';
  end if;
  if not v_party.is_public
     and (p_code is null or v_party.join_code is distinct from upper(p_code))
  then
    return 'code_required';
  end if;
  select count(*) into v_count from party_members where party_id = p_party;
  if v_count >= v_party.max_members then return 'full'; end if;
  insert into party_members (party_id, user_id, role)
  values (p_party, v_user, 'member');
  return 'ok';
end $$;

-- 초대코드로 가입. 코드를 아는 사람만 해당 파티에 닿을 수 있다.
create or replace function public.join_party_by_code(p_code text)
returns text language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  select id into v_id from parties where join_code = upper(p_code);
  if v_id is null then return 'not_found'; end if;
  return public.join_party(v_id, p_code);
end $$;

grant execute on function public.join_party(uuid, text) to authenticated;
grant execute on function public.join_party_by_code(text) to authenticated;

drop policy if exists "party read" on parties;
-- 소유자는 만든 직후에도 자기 파티를 읽을 수 있어야 한다.
create policy "party read" on parties for select to authenticated
  using (is_public or owner_id = auth.uid() or public.is_party_member(id));

drop policy if exists "member read" on party_members;
-- 공개 파티는 인원수를 보여줘야 하므로 멤버 목록 읽기를 허용한다.
create policy "member read" on party_members for select to authenticated
  using (
    public.is_party_member(party_id)
    or exists (select 1 from parties p where p.id = party_id and p.is_public)
  );

-- 직접 INSERT를 막는다. 가입은 join_party 함수로만 가능하다.
drop policy if exists "member write" on party_members;

-- ─────────────────────────────────────────────────────────────
-- 3. 차단: 서버에서 양방향으로 적용한다
-- ─────────────────────────────────────────────────────────────
create or replace function public.is_blocked(a uuid, b uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from user_blocks
    where (blocker_id = a and blocked_id = b)
       or (blocker_id = b and blocked_id = a)
  )
$$;

drop policy if exists "posts authenticated read" on posts;
create policy "posts authenticated read" on posts for select to authenticated
  using (not public.is_blocked(auth.uid(), user_id));

drop policy if exists "post likes own write" on post_likes;
create policy "post likes own write" on post_likes for all to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and not exists (
      select 1 from posts p
      where p.id = post_id and public.is_blocked(auth.uid(), p.user_id)
    )
  );

drop policy if exists "comments own write" on post_comments;
create policy "comments own write" on post_comments for all to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and not exists (
      select 1 from posts p
      where p.id = post_id and public.is_blocked(auth.uid(), p.user_id)
    )
  );

drop policy if exists "follows own write" on follows;
create policy "follows own write" on follows for all to authenticated
  using (auth.uid() = follower_id)
  with check (
    auth.uid() = follower_id
    and not public.is_blocked(auth.uid(), following_id)
  );

-- ─────────────────────────────────────────────────────────────
-- 4. 입력 길이 제한. 기존 행은 건드리지 않도록 not valid로 둔다.
-- ─────────────────────────────────────────────────────────────
alter table profiles drop constraint if exists profiles_nickname_len;
alter table profiles add constraint profiles_nickname_len
  check (char_length(btrim(nickname)) between 1 and 20) not valid;

alter table profiles drop constraint if exists profiles_bio_len;
alter table profiles add constraint profiles_bio_len
  check (bio is null or char_length(bio) <= 200) not valid;

alter table posts drop constraint if exists posts_caption_len;
alter table posts add constraint posts_caption_len
  check (char_length(caption) <= 500) not valid;

alter table post_comments drop constraint if exists comments_body_len;
alter table post_comments add constraint comments_body_len
  check (char_length(btrim(body)) between 1 and 300) not valid;

alter table party_messages drop constraint if exists messages_body_len;
alter table party_messages add constraint messages_body_len
  check (char_length(btrim(body)) between 1 and 500) not valid;

alter table parties drop constraint if exists parties_name_len;
alter table parties add constraint parties_name_len
  check (char_length(btrim(name)) between 1 and 30) not valid;

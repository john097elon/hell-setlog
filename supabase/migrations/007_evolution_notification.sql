-- 007: 파티원의 캐릭터가 진화하면 파티에 알린다.
-- 혼자 크는 게 아니라 같이 크는 걸 보여주는 장치다.

create or replace function public.on_character_evolved()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_member record;
begin
  -- 단계가 실제로 오른 경우만. 처음 값이 들어올 때는 알리지 않는다.
  if new.character_stage is null
     or old.character_stage is null
     or new.character_stage <= old.character_stage then
    return new;
  end if;
  for v_member in
    select distinct other.user_id
    from party_members mine
    join party_members other on other.party_id = mine.party_id
    where mine.user_id = new.user_id and other.user_id <> new.user_id
  loop
    insert into notifications (user_id, actor_id, kind, body)
    values (
      v_member.user_id,
      new.user_id,
      'evolution',
      coalesce(nullif(btrim(new.character_name), ''), '캐릭터')
    );
  end loop;
  return new;
end $$;

drop trigger if exists trg_character_evolved on profiles;
create trigger trg_character_evolved after update of character_stage on profiles
  for each row execute function public.on_character_evolved();

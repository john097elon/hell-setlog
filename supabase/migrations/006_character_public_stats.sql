-- 006: 파티원에게 보여줄 캐릭터 성장 수치
-- 성장은 개인 운동 기록에서 계산되는데 그 기록은 본인만 볼 수 있다.
-- 파티방에서 서로의 캐릭터를 보려면 결과 수치만 프로필에 남겨야 한다.
alter table profiles add column if not exists character_level int;
alter table profiles add column if not exists character_stage int;
alter table profiles add column if not exists character_xp int;
alter table profiles add column if not exists character_updated_at timestamptz;

alter table profiles drop constraint if exists profiles_character_stage_range;
alter table profiles add constraint profiles_character_stage_range
  check (character_stage is null or character_stage between 0 and 4) not valid;

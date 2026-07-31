-- 004: 사용자가 고른 캐릭터 종족·성향·이름
-- 기기를 바꿔도 캐릭터가 유지되도록 프로필에 함께 둔다.
alter table profiles add column if not exists character_species text;
alter table profiles add column if not exists character_trait text;
alter table profiles add column if not exists character_name text;

alter table profiles drop constraint if exists profiles_character_name_len;
alter table profiles add constraint profiles_character_name_len
  check (character_name is null or char_length(btrim(character_name)) between 1 and 12) not valid;

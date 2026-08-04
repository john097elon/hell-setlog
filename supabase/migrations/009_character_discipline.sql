-- 009: 파티원 캐릭터가 입은 복장을 정하는 주 종목
-- 성장 수치처럼 결과만 프로필에 남긴다. 개인 운동 기록은 본인만 볼 수 있다.
alter table profiles add column if not exists character_discipline text;

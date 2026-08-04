-- 010: 사용자가 직접 고른 주 종목
-- 비워 두면 최근 기록에서 자동으로 정한다.
alter table profiles add column if not exists character_preferred_discipline text;

-- 운동 기록이 서버에 하나도 올라가지 못하던 원인을 푼다.
--
-- 종목 목록은 앱에 내장되어 기기에서 시드된다. 서버 exercises 표에는 사용자가
-- 직접 만든 종목만 올라가므로, 기본 종목을 참조하는 세트와 루틴 항목은 외래키에
-- 걸려 전부 거부됐다. 종목 id는 시드에 고정된 uuid라 기기가 바뀌어도 같은 값을
-- 가리키며, 서버는 이 값을 조인에 쓰지 않는다.
alter table public.workout_sets
  drop constraint if exists workout_sets_exercise_id_fkey;

alter table public.routine_items
  drop constraint if exists routine_items_exercise_id_fkey;

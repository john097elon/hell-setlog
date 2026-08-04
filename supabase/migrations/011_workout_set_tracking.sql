-- 헬스 외 종목(러닝·수영·주짓수 등)의 기록을 서버에도 남긴다.
-- 이 컬럼이 없으면 기기를 바꿨을 때 거리·시간 기록이 사라진다.
alter table public.workout_sets
  add column if not exists distance_meters numeric null,
  add column if not exists duration_seconds integer null,
  add column if not exists intensity integer null;

alter table public.workout_sets
  drop constraint if exists workout_sets_distance_meters_check;
alter table public.workout_sets
  add constraint workout_sets_distance_meters_check
  check (distance_meters is null or (distance_meters >= 0 and distance_meters <= 1000000));

alter table public.workout_sets
  drop constraint if exists workout_sets_duration_seconds_check;
alter table public.workout_sets
  add constraint workout_sets_duration_seconds_check
  check (duration_seconds is null or (duration_seconds >= 0 and duration_seconds <= 86400));

alter table public.workout_sets
  drop constraint if exists workout_sets_intensity_check;
alter table public.workout_sets
  add constraint workout_sets_intensity_check
  check (intensity is null or intensity between 1 and 5);

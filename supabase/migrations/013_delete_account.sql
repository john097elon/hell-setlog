-- 회원 탈퇴. 앱에서 계정을 지울 수 있어야 스토어 심사를 통과한다.
--
-- 공개 스키마의 표는 모두 auth.users를 참조하며 on delete cascade가 걸려 있어,
-- 사용자 행 하나를 지우면 기록·게시물·파티 활동이 함께 사라진다.
--
-- 업로드한 파일은 여기서 건드리지 않는다. Supabase가 storage 표의 직접 삭제를
-- 막아 두었기 때문에, 파일은 앱이 Storage API로 먼저 지우고 이 함수를 부른다.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'unauthorized' using errcode = '28000';
  end if;

  delete from auth.users where id = v_user;
end $$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

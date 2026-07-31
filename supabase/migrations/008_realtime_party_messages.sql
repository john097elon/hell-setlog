-- 008: 파티 채팅 실시간 구독
-- supabase_realtime publication에 테이블이 없으면 클라이언트의 .stream()이
-- 초기 조회만 하고 이후 변경을 받지 못한다. 채팅이 조용히 안 되는 원인이다.
-- RLS는 그대로 적용되어 파티원만 자기 파티 메시지를 받는다.
alter publication supabase_realtime add table party_messages;

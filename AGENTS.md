# HealSetLog Codex 구현 규칙

@docs/PROJECT_CONTEXT.md

- `TASK-Pn-xx` 명세의 목표, 파일 목록, 인터페이스 계약, 완료 조건을 확인한 뒤 구현한다.
- 모호하거나 모순된 요구사항은 코드를 쓰기 전에 질문한다. 인터페이스 시그니처는 승인 없이 바꾸지 않는다.
- 구현 순서는 domain → data → presentation이다. 새 도메인 로직은 단위 테스트를 먼저 작성한다.
- `flutter analyze`와 `flutter test`가 통과하기 전에는 완료로 보고하지 않는다.
- P1~P2 완료 전에는 파티, 피드, 영상, 캐릭터 기능 코드를 추가하지 않는다.

# Hell Setlog — 핸드오프

**날짜**: 2026-06-24
**직전 작업자**: Hermes (Oracle)
**서버**: Oracle ARM 100.92.203.83

---

## 프로젝트 개요
SetLog(카메라 중심 2초 클립 공유) 스타일의 운동 기록 + 소셜 파티 앱.
운동 중 짧은 영상을 찍어 파티(최대 12명)에 실시간 공유. PWA 지원.

## 현재 상태

### ✅ 완료된 기능
- **인증**: JWT 회원가입/로그인 (+ 테스트 계정 `e2e@test.com` / `test1234`)
- **파티**: 생성, 초대코드 가입, 랜덤 매칭 (`/api/parties/random-match`), 랜덤 파티 둘러보기 (`/api/parties/random-browse`)
- **운동**: 시작/종료/타이머, 세트로그(사진+텍스트), 파티와 연동
- **캐릭터**: 바디 스탯(가슴/등/어깨/팔/코어/유산소 6부위), 레벨업
- **피드**: 파티별 통합 타임라인 (운동시작/종료/세트로그/리액션)
- **스트릭**: 연속 운동일 뱃지
- **PWA**: manifest + service worker + 아이콘
- **HTTPS**: Tailscale Funnel (`https://hermes-vnic.tail78f49b.ts.net/`)

### 🎲 최근 작업: 랜덤 매칭 강화
- `User.workout_tags` 필드 (운동 취향: 근력/유산소/홈트 등)
- `PATCH /api/users/me/tags` — 태그 업데이트
- `GET /api/parties/random-browse` — 열린 랜덤파티 둘러보기
- 랜덤 파티명 자동생성 (30개 풀: "바벨 브라더스", "불타는 헬창단" 등)
- 프론트: 파티 디스커버리 섹션, 운동 태그 칩 UI, 설정 토글

### ⏳ 다음 할 일
- **오운완 촬영 플로우**: 운동별 세트로그 → 그냥 1~2장 오운완 클립 (사용자 피드백 반영)
- **실시간 웹소켓**: 파티원 간 실시간 클립 공유 (현재는 폴링/수동 새로고침)
- **영상 업로드**: S3/로컬 저장소 결정. 현재 file_path만 스키마에 있음
- **파티룸 UI 개선**: 2x2 하이라이트 스플릿, 응원 퀵버튼, 채팅
- **모바일 푸시 알림**: 파티원 운동 시작/클립 공유 시

## 기술 스택

| 계층 | 기술 | 경로 |
|------|------|------|
| 백엔드 | FastAPI (Python), SQLAlchemy, SQLite | `backend/` |
| 프론트 | React 19 + Vite 8 + TailwindCSS v4 | `frontend/` |
| 배포 | Oracle ARM (Ubuntu aarch64) | IP 100.92.203.83 |
| HTTPS | Tailscale Funnel | `hermes-vnic.tail78f49b.ts.net` |
| API prefix | `/api` (Vite proxy) | 백엔드 라우트 모두 `/api/...` |

## 서버 실행

```bash
# 백엔드 (Oracle)
cd /home/ubuntu/hell-setlog/backend
source .venv/bin/activate
python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload

# 프론트 (Oracle)
cd /home/ubuntu/hell-setlog/frontend
npm run dev -- --host 0.0.0.0
# → http://100.92.203.83:5174/
```

## 주요 파일 구조

```
hell-setlog/
├── backend/
│   ├── main.py          # FastAPI 앱, CORS, 라우터 등록
│   ├── models.py        # SQLAlchemy 모델 (7개)
│   ├── schemas.py       # Pydantic 스키마
│   ├── database.py      # DB 초기화 + 마이그레이션
│   ├── auth.py          # JWT 인증
│   └── routers/
│       ├── parties.py   # 파티 CRUD, 랜덤매칭, 피드
│       ├── workouts.py  # 운동 시작/종료, 세트로그
│       ├── characters.py
│       ├── reactions.py
│       ├── stats.py
│       ├── streak.py
│       └── users.py     # workout_tags
└── frontend/
    ├── src/
    │   ├── App.tsx      # 라우터 (6페이지)
    │   ├── api.ts       # Axios 인스턴스
    │   ├── components/
    │   │   ├── Layout.tsx         # 하단 탭 (운동/파티/기록) + 설정
    │   │   ├── SetVideoRecorder.tsx
    │   │   ├── StreakBadge.tsx
    │   │   └── CharacterPreview.tsx
    │   └── pages/
    │       ├── WorkoutPage.tsx    # 운동 시작/진행/종료
    │       ├── PartyListPage.tsx  # 파티 목록 + 랜덤 디스커버리
    │       ├── PartyRoomPage.tsx  # 파티룸 (피드+멤버)
    │       ├── LoginPage.tsx
    │       ├── RegisterPage.tsx
    │       └── SettingsPage.tsx   # 캐릭터+운동태그
    └── public/
        ├── manifest.json
        └── sw.js
```

## 주의사항
- `api.ts` baseURL이 `/api`로 설정돼있음 (Vite proxy → localhost:8001)
- 모든 API 호출은 상대경로 `/api/...`
- SQLite라 동시성 주의. production은 PostgreSQL 권장

## 핸드오프 — 다음 작업자가 이어받는 법

```bash
# 1. 로컬에 클론 (oracle에 코드 있음)
git clone ... # 또는 scp로 가져오기

# 2. HANDOFF.md 읽고 맥락 파악
# 3. claude code로 이어서 작업
claude "HANDOFF.md 읽고 이어서 X 기능 구현해줘"
```

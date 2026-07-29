# 헬셋로그 (HealSetLog) 출시 전 체크리스트

---

## 1. 안드로이드 서명 키스토어 (KeyStore) 생성 및 설정

스토어 배포용 서명 키 생성 명령 예시 (Keytool 명령):

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- 생성된 `upload-keystore.jks` 파일은 버전 관리 시스템(`.gitignore`)에 반드시 포함시켜 Git에 올라가지 않도록 보안 처리합니다.
- `android/key.properties` 파일 설정 확인:
  ```properties
  storePassword=<KEYSTORE_PASSWORD>
  keyPassword=<KEY_PASSWORD>
  keyAlias=upload
  storeFile=upload-keystore.jks
  ```

---

## 2. applicationId 및 패키지명 확인

- `android/app/build.gradle` (또는 `build.gradle.kts`)의 `applicationId` 확인:
  - 설정값: `com.john097elon.heal_setlog`
- 스토어 출시 후 패키지명은 변경 불가능하므로 철자 및 일치 여부 확인 필수.

---

## 3. 앱 버전 및 빌드 번호 관리 (`pubspec.yaml`)

- `pubspec.yaml` 내 `version` 필드 형식: `VERSION_NAME+VERSION_CODE`
  - 예: `version: 1.0.0+1`
- Google Play Console에 새 AAB 업로드 시 매번 `VERSION_CODE` (플러스 뒤 숫자)를 1씩 증가시켜야 합니다.

---

## 4. Supabase Auth 설정 확인

1. **Confirm Email (이메일 확인) 재활성화**
   - 개발 환경에서 비활성화되어 있던 Email Confirmation 옵션을 Supabase Dashboard > Authentication > Providers > Email 설정에서 **ON**으로 전환.
2. **커스텀 SMTP (Custom SMTP) 연결**
   - 기본 Supabase 메일 발송 서버의 일일 제한 및 스팸 분류 방지를 위해 자체 SMTP 서버 또는 전용 서비스(Resend, SendGrid, Amazon SES 등) 연결.
   - Redirect URL에 서비스 주소 및 딥링크 설정 등록.

---

## 5. 법적 문서 및 웹 URL 게시

- Google Play Console 등록 시 공개 가능한 개인정보처리방침 URL 필요.
- `docs/legal/privacy-policy-ko.md` 및 `docs/legal/privacy-policy-en.md` 내용을 GitHub Pages 또는 개인 웹 페이지에 호스팅하고 URL 확보.

---

## 6. Play Console 내부 테스트 트랙 (Internal Testing Track) 구성

- Play Console 진입 후 **내부 테스트(Internal Testing)** 트랙 생성.
- 테스터 이메일 리스트 등록.
- `flutter build appbundle --release` 명령으로 생성된 `.aab` 파일 첫 업로드 및 내부 테스터 검증 진행.

---

## 7. 스토어 등록물 업로드 및 출시 순서

1. **스토어 정보 입력**: 앱 이름, 짧은 설명, 전체 설명, 스크린샷 4장 이상, 대표 그래픽 업로드.
2. **데이터 보안 (Data Safety) 입력**: `docs/release/play-store-listing.md` 답변 초안 참고하여 수집 항목 및 보안 규정 입력.
3. **콘텐츠 등급 설문 완료**: 설문지 작성 후 PEGI/GRAC 등급 수령.
4. **개인정보처리방침 URL 입력**: 5단계에서 확보한 URL 입력.
5. **AAB 빌드 업로드**: 테스트 트랙 통과 후 출시 프로덕션 트랙에 AAB 등록.
6. **심사 제출**: 최종 검토 후 심사 제출.

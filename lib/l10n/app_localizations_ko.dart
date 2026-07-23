// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get monsterMockName => '타이냥';

  @override
  String get monsterExperience => 'EXP';

  @override
  String get monsterBodyTypeUpper => '상체형';

  @override
  String get monsterBodyTypeLower => '하체형';

  @override
  String get monsterBodyTypeBalanced => '균형형';

  @override
  String get monsterStatArm => 'ARM';

  @override
  String get monsterStatLeg => 'LEG';

  @override
  String get monsterStatCore => 'CORE';

  @override
  String get monsterStatEndure => 'ENDURE';

  @override
  String get appName => '헬셋로그';

  @override
  String get login => '로그인';

  @override
  String get loginIntro => '지옥의 피트니스 파티에 오신 것을 환영합니다';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get loginButton => '로그인';

  @override
  String get noAccount => '계정이 없으신가요?';

  @override
  String get register => '회원가입';

  @override
  String get registerIntro => '파티에 참여할 준비가 되셨나요?';

  @override
  String get nickname => '닉네임';

  @override
  String get registerButton => '회원가입';

  @override
  String get hasAccount => '이미 계정이 있으신가요?';

  @override
  String get home => '홈';

  @override
  String get record => '기록';

  @override
  String get workout => '운동';

  @override
  String get stats => '통계';

  @override
  String get party => '파티';

  @override
  String get profile => '프로필';

  @override
  String get todayWorkout => '오늘의 운동';

  @override
  String get todayWorkoutDescription => '운동을 시작하고 세트로그를 기록하세요';

  @override
  String get startWorkout => '운동 시작하기';

  @override
  String get routines => '루틴';

  @override
  String get routinesDescription => '저장한 루틴을 바로 시작하세요';

  @override
  String get streak => '연속 운동';

  @override
  String get weekWorkout => '이번 주 운동';

  @override
  String get partyActivity => '파티 활동';

  @override
  String get viewParty => '내 파티 보기';

  @override
  String get memoOptional => '운동 메모 (선택)';

  @override
  String get memoHint => '오늘의 운동 목표나 메모를 적어보세요';

  @override
  String get workoutInProgress => '운동 진행 중';

  @override
  String get completedSets => '완료 세트';

  @override
  String get completeSet => '세트 완료';

  @override
  String get endWorkout => '운동 종료';

  @override
  String get workoutComplete => '운동 완료!';

  @override
  String get potentialAccumulated => '잠재력이 누적됐어요';

  @override
  String get totalTime => '총 운동 시간';

  @override
  String get setLogs => '세트로그';

  @override
  String get startNewWorkout => '새 운동 시작';

  @override
  String get goHome => '홈으로 돌아가기';

  @override
  String get statsTitle => '운동 통계';

  @override
  String get statsDescription => '기록이 쌓이면 볼륨과 1RM 변화를 보여드릴게요.';

  @override
  String get statsLater => '통계는 P2에서 연결됩니다';

  @override
  String get statsLaterDescription => '지금은 기존 디자인을 확인하는 목업 화면입니다.';

  @override
  String get statsThisWeek => '이번 주';

  @override
  String get statsWorkoutDays => '운동 일수';

  @override
  String statsWorkoutDaysValue(int count) {
    return '$count일';
  }

  @override
  String get statsTotalVolume => '총 볼륨';

  @override
  String statsVolumeValue(String volume) {
    return '$volume kg';
  }

  @override
  String get statsWeeklyVolume => '주간 볼륨';

  @override
  String get statsBodyPartSplit => '부위별 볼륨';

  @override
  String get statsNoData => '아직 기록된 운동이 없어요';

  @override
  String get statsNoDataDescription => '운동을 기록하면 이번 주의 변화를 볼 수 있어요.';

  @override
  String get statsLoadError => '통계를 불러오지 못했어요';

  @override
  String get monster => '몬스터';

  @override
  String get monsterComingSoon => '곧 만나요';

  @override
  String get monsterComingSoonDescription => '몬스터 성장은 P6에서 제공됩니다.';

  @override
  String get muscleChest => '가슴';

  @override
  String get muscleBack => '등';

  @override
  String get muscleShoulders => '어깨';

  @override
  String get muscleLegs => '하체';

  @override
  String get muscleArms => '팔';

  @override
  String get muscleCore => '코어';

  @override
  String get muscleFullBody => '전신';

  @override
  String get muscleOther => '기타';

  @override
  String get myParties => '내 파티';

  @override
  String get partySubtitle => '함께 기록하면 운동이 더 오래갑니다';

  @override
  String get createParty => '새 파티';

  @override
  String get joinParty => '가입';

  @override
  String get randomParty => '랜덤';

  @override
  String get partyName => '파티 이름';

  @override
  String get partyNameHint => '예: 헬지옥 정복단';

  @override
  String get partyDescription => '파티 설명';

  @override
  String get partyDescriptionHint => '파티의 목표나 규칙을 적어보세요';

  @override
  String get inviteCode => '초대 코드';

  @override
  String get inviteCodeHint => '예: ABC123';

  @override
  String get create => '생성';

  @override
  String get join => '가입하기';

  @override
  String get cancel => '취소';

  @override
  String get randomPartyTitle => '랜덤 파티 찾기';

  @override
  String get randomPartyDescription => '지금 함께 운동하는 사람들과 만나보세요';

  @override
  String get openParty => '파티 열기';

  @override
  String get partyRoom => '파티 방';

  @override
  String get members => '멤버';

  @override
  String get activity => '활동';

  @override
  String get reaction => '응원';

  @override
  String get leaveParty => '나가기';

  @override
  String get invite => '초대';

  @override
  String get inviteCopied => '초대 코드가 복사됐어요';

  @override
  String get profileTitle => '내 캐릭터';

  @override
  String get profileDescription => '운동 기록이 캐릭터를 성장시킵니다';

  @override
  String get level => '레벨';

  @override
  String get strength => '근력';

  @override
  String get endurance => '지구력';

  @override
  String get consistency => '꾸준함';

  @override
  String get workoutTags => '운동 취향 태그';

  @override
  String get save => '저장';

  @override
  String get saved => '설정이 저장되었습니다';

  @override
  String get tagStrength => '근력';

  @override
  String get tagCardio => '유산소';

  @override
  String get tagHomeTraining => '홈트';

  @override
  String get tagCrossfit => '크로스핏';

  @override
  String get tagYoga => '요가';

  @override
  String get tagRunning => '러닝';

  @override
  String get tagSwimming => '수영';

  @override
  String get streakValue => '3일';

  @override
  String get weekWorkoutValue => '4회';

  @override
  String get partyActivityMessage => '오늘 2명의 파티원이 운동했어요';

  @override
  String setItem(int number) {
    return '세트 $number';
  }

  @override
  String get samplePartyName => '헬지옥 정복단';

  @override
  String get samplePartyDescription => '주 4회, 끝까지 함께 기록하는 파티';

  @override
  String get samplePartyNameSecond => '새벽 6시 웨이트';

  @override
  String get samplePartyDescriptionSecond => '아침 운동 루틴을 만드는 중';

  @override
  String get memberCount => '3명';

  @override
  String get memberCountSecond => '4명';

  @override
  String get feedMemberJoined => '민수님이 파티에 참가했습니다';

  @override
  String get feedWorkoutStarted => '지훈님이 오늘의 운동을 시작했습니다';

  @override
  String get feedWorkoutDone => '서연님이 운동을 완료했습니다';

  @override
  String reactionCount(int count) {
    return '응원 $count';
  }

  @override
  String get mockOnlyNotice => '목업 화면에서는 실제 데이터가 저장되지 않습니다';

  @override
  String get recordTypeStart => '시작';

  @override
  String get recordTypeMiddle => '중간';

  @override
  String get recordTypeEnd => '종료';

  @override
  String get photo => '사진';

  @override
  String get photoMockNotice => '사진 첨부는 목업에서만 표시됩니다';

  @override
  String get avatarSeed => '아바타 시드';

  @override
  String get sampleSetDetails => '60 kg · 10회';

  @override
  String get sampleCurrentUser => '존';

  @override
  String get sampleMemberMinsu => '민수';

  @override
  String get sampleMemberSeoyeon => '서연';

  @override
  String get rest => '휴식';

  @override
  String addSeconds(int seconds) {
    return '+$seconds초';
  }

  @override
  String get skip => '건너뛰기';

  @override
  String get selectExercise => '종목 선택';

  @override
  String get setDeleted => '세트를 삭제했어요';

  @override
  String get undo => '실행 취소';

  @override
  String get partyCreateShort => '개설';

  @override
  String get partyExplore => '탐색';

  @override
  String get partyChat => '채팅';

  @override
  String partyMemberProgress(int members, int limit) {
    return '$members/$limit명';
  }

  @override
  String partyMissionProgress(int completed, int target) {
    return '오늘의 미션 $completed/$target';
  }

  @override
  String get partyTodayXp => '오늘 +240 XP';

  @override
  String get partyRandomMatch => 'RANDOM MATCH';

  @override
  String get partyRandomMatchDescription => '지금 함께 운동할 파티를 찾아보세요.';

  @override
  String get partyGo => 'GO';

  @override
  String get partyInviteFriends => '친구 초대';

  @override
  String partyLevel(int level) {
    return 'LV $level';
  }

  @override
  String get partyInvited => '초대됨';

  @override
  String get partyAll => '전체';

  @override
  String get muscleLowerBody => '하체';

  @override
  String get partySearchHint => '파티 검색';

  @override
  String get partyProTitle => 'PRO 파티';

  @override
  String get partyProDescription => 'PRO 전용 파티 혜택을 확인하세요.';

  @override
  String get partyChatHint => '메시지를 입력하세요';

  @override
  String get partySend => '전송';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsProfile => '프로필';

  @override
  String get settingsEditProfile => '프로필 편집';

  @override
  String settingsLevelXp(int level, int xp) {
    return 'LV $level · $xp XP';
  }

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsWorkoutReminder => '운동 리마인더';

  @override
  String get settingsPartyNotification => '파티 알림';

  @override
  String get settingsChatNotification => '채팅 알림';

  @override
  String get settingsMonsterGrowth => '몬스터 성장 알림';

  @override
  String get settingsPrivacy => '개인정보';

  @override
  String get settingsFeedVisibility => '피드 공개범위';

  @override
  String get settingsWorkoutVisibility => '운동기록 공개';

  @override
  String get settingsApp => '앱 설정';

  @override
  String get settingsDarkMode => '다크 모드';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsKorean => '한국어';

  @override
  String get settingsWeightUnit => '무게 단위';

  @override
  String get settingsKg => 'kg';

  @override
  String get settingsLb => 'lb';

  @override
  String get settingsSubscription => '구독';

  @override
  String get settingsProUpgrade => 'HELL-LOG PRO 업그레이드';

  @override
  String get settingsProDescription => '더 깊은 운동 경험을 준비하고 있어요';

  @override
  String get settingsOther => '기타';

  @override
  String get settingsNotices => '공지사항';

  @override
  String get settingsSupport => '문의하기';

  @override
  String get settingsPrivacyPolicy => '개인정보처리방침';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsMockMessage => '목업 화면에서는 실제 변경이 저장되지 않습니다';

  @override
  String get settingsProMockMessage => 'PRO 구독은 정식 출시 후 이용할 수 있습니다';

  @override
  String get settingsLogoutMockMessage => '로그아웃은 목업에서만 표시됩니다';

  @override
  String get settingsEditName => '이름';

  @override
  String get settingsEditSave => '완료';

  @override
  String get settingsPublic => '전체 공개';

  @override
  String get settingsPrivate => '비공개';

  @override
  String get close => '닫기';

  @override
  String get shareWorkout => '운동 공유';

  @override
  String get cameraPreviewMock => '카메라 미리보기 (P5)';

  @override
  String get tapToRecord => '탭하여 녹화';

  @override
  String get recording => '녹화 중';

  @override
  String get shareCaptionHint => '운동 소감을 남겨보세요';

  @override
  String get shareToFeed => '피드에 공유';

  @override
  String get workoutSharedMock => '피드에 공유됨 (mock)';
}

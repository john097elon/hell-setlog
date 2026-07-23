import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ko')];

  /// No description provided for @monsterMockName.
  ///
  /// In ko, this message translates to:
  /// **'타이냥'**
  String get monsterMockName;

  /// No description provided for @monsterExperience.
  ///
  /// In ko, this message translates to:
  /// **'EXP'**
  String get monsterExperience;

  /// No description provided for @monsterBodyTypeUpper.
  ///
  /// In ko, this message translates to:
  /// **'상체형'**
  String get monsterBodyTypeUpper;

  /// No description provided for @monsterBodyTypeLower.
  ///
  /// In ko, this message translates to:
  /// **'하체형'**
  String get monsterBodyTypeLower;

  /// No description provided for @monsterBodyTypeBalanced.
  ///
  /// In ko, this message translates to:
  /// **'균형형'**
  String get monsterBodyTypeBalanced;

  /// No description provided for @monsterStatArm.
  ///
  /// In ko, this message translates to:
  /// **'ARM'**
  String get monsterStatArm;

  /// No description provided for @monsterStatLeg.
  ///
  /// In ko, this message translates to:
  /// **'LEG'**
  String get monsterStatLeg;

  /// No description provided for @monsterStatCore.
  ///
  /// In ko, this message translates to:
  /// **'CORE'**
  String get monsterStatCore;

  /// No description provided for @monsterStatEndure.
  ///
  /// In ko, this message translates to:
  /// **'ENDURE'**
  String get monsterStatEndure;

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'헬셋로그'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get login;

  /// No description provided for @loginIntro.
  ///
  /// In ko, this message translates to:
  /// **'지옥의 피트니스 파티에 오신 것을 환영합니다'**
  String get loginIntro;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginButton;

  /// No description provided for @noAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요?'**
  String get noAccount;

  /// No description provided for @register.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get register;

  /// No description provided for @registerIntro.
  ///
  /// In ko, this message translates to:
  /// **'파티에 참여할 준비가 되셨나요?'**
  String get registerIntro;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @registerButton.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get registerButton;

  /// No description provided for @hasAccount.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요?'**
  String get hasAccount;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @record.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get record;

  /// No description provided for @workout.
  ///
  /// In ko, this message translates to:
  /// **'운동'**
  String get workout;

  /// No description provided for @stats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get stats;

  /// No description provided for @party.
  ///
  /// In ko, this message translates to:
  /// **'파티'**
  String get party;

  /// No description provided for @profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profile;

  /// No description provided for @todayWorkout.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 운동'**
  String get todayWorkout;

  /// No description provided for @todayWorkoutDescription.
  ///
  /// In ko, this message translates to:
  /// **'운동을 시작하고 세트로그를 기록하세요'**
  String get todayWorkoutDescription;

  /// No description provided for @startWorkout.
  ///
  /// In ko, this message translates to:
  /// **'운동 시작하기'**
  String get startWorkout;

  /// No description provided for @routines.
  ///
  /// In ko, this message translates to:
  /// **'루틴'**
  String get routines;

  /// No description provided for @routinesDescription.
  ///
  /// In ko, this message translates to:
  /// **'저장한 루틴을 바로 시작하세요'**
  String get routinesDescription;

  /// No description provided for @streak.
  ///
  /// In ko, this message translates to:
  /// **'연속 운동'**
  String get streak;

  /// No description provided for @weekWorkout.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 운동'**
  String get weekWorkout;

  /// No description provided for @partyActivity.
  ///
  /// In ko, this message translates to:
  /// **'파티 활동'**
  String get partyActivity;

  /// No description provided for @viewParty.
  ///
  /// In ko, this message translates to:
  /// **'내 파티 보기'**
  String get viewParty;

  /// No description provided for @memoOptional.
  ///
  /// In ko, this message translates to:
  /// **'운동 메모 (선택)'**
  String get memoOptional;

  /// No description provided for @memoHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 운동 목표나 메모를 적어보세요'**
  String get memoHint;

  /// No description provided for @workoutInProgress.
  ///
  /// In ko, this message translates to:
  /// **'운동 진행 중'**
  String get workoutInProgress;

  /// No description provided for @completedSets.
  ///
  /// In ko, this message translates to:
  /// **'완료 세트'**
  String get completedSets;

  /// No description provided for @completeSet.
  ///
  /// In ko, this message translates to:
  /// **'세트 완료'**
  String get completeSet;

  /// No description provided for @endWorkout.
  ///
  /// In ko, this message translates to:
  /// **'운동 종료'**
  String get endWorkout;

  /// No description provided for @workoutComplete.
  ///
  /// In ko, this message translates to:
  /// **'운동 완료!'**
  String get workoutComplete;

  /// No description provided for @potentialAccumulated.
  ///
  /// In ko, this message translates to:
  /// **'잠재력이 누적됐어요'**
  String get potentialAccumulated;

  /// No description provided for @totalTime.
  ///
  /// In ko, this message translates to:
  /// **'총 운동 시간'**
  String get totalTime;

  /// No description provided for @setLogs.
  ///
  /// In ko, this message translates to:
  /// **'세트로그'**
  String get setLogs;

  /// No description provided for @startNewWorkout.
  ///
  /// In ko, this message translates to:
  /// **'새 운동 시작'**
  String get startNewWorkout;

  /// No description provided for @goHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로 돌아가기'**
  String get goHome;

  /// No description provided for @statsTitle.
  ///
  /// In ko, this message translates to:
  /// **'운동 통계'**
  String get statsTitle;

  /// No description provided for @statsDescription.
  ///
  /// In ko, this message translates to:
  /// **'기록이 쌓이면 볼륨과 1RM 변화를 보여드릴게요.'**
  String get statsDescription;

  /// No description provided for @statsLater.
  ///
  /// In ko, this message translates to:
  /// **'통계는 P2에서 연결됩니다'**
  String get statsLater;

  /// No description provided for @statsLaterDescription.
  ///
  /// In ko, this message translates to:
  /// **'지금은 기존 디자인을 확인하는 목업 화면입니다.'**
  String get statsLaterDescription;

  /// No description provided for @statsThisWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get statsThisWeek;

  /// No description provided for @statsWorkoutDays.
  ///
  /// In ko, this message translates to:
  /// **'운동 일수'**
  String get statsWorkoutDays;

  /// No description provided for @statsWorkoutDaysValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String statsWorkoutDaysValue(int count);

  /// No description provided for @statsTotalVolume.
  ///
  /// In ko, this message translates to:
  /// **'총 볼륨'**
  String get statsTotalVolume;

  /// No description provided for @statsVolumeValue.
  ///
  /// In ko, this message translates to:
  /// **'{volume} kg'**
  String statsVolumeValue(String volume);

  /// No description provided for @statsWeeklyVolume.
  ///
  /// In ko, this message translates to:
  /// **'주간 볼륨'**
  String get statsWeeklyVolume;

  /// No description provided for @statsBodyPartSplit.
  ///
  /// In ko, this message translates to:
  /// **'부위별 볼륨'**
  String get statsBodyPartSplit;

  /// No description provided for @statsNoData.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록된 운동이 없어요'**
  String get statsNoData;

  /// No description provided for @statsNoDataDescription.
  ///
  /// In ko, this message translates to:
  /// **'운동을 기록하면 이번 주의 변화를 볼 수 있어요.'**
  String get statsNoDataDescription;

  /// No description provided for @statsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'통계를 불러오지 못했어요'**
  String get statsLoadError;

  /// No description provided for @monster.
  ///
  /// In ko, this message translates to:
  /// **'몬스터'**
  String get monster;

  /// No description provided for @monsterComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'곧 만나요'**
  String get monsterComingSoon;

  /// No description provided for @monsterComingSoonDescription.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 성장은 P6에서 제공됩니다.'**
  String get monsterComingSoonDescription;

  /// No description provided for @muscleChest.
  ///
  /// In ko, this message translates to:
  /// **'가슴'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In ko, this message translates to:
  /// **'등'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In ko, this message translates to:
  /// **'어깨'**
  String get muscleShoulders;

  /// No description provided for @muscleLegs.
  ///
  /// In ko, this message translates to:
  /// **'하체'**
  String get muscleLegs;

  /// No description provided for @muscleArms.
  ///
  /// In ko, this message translates to:
  /// **'팔'**
  String get muscleArms;

  /// No description provided for @muscleCore.
  ///
  /// In ko, this message translates to:
  /// **'코어'**
  String get muscleCore;

  /// No description provided for @muscleFullBody.
  ///
  /// In ko, this message translates to:
  /// **'전신'**
  String get muscleFullBody;

  /// No description provided for @muscleOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get muscleOther;

  /// No description provided for @myParties.
  ///
  /// In ko, this message translates to:
  /// **'내 파티'**
  String get myParties;

  /// No description provided for @partySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'함께 기록하면 운동이 더 오래갑니다'**
  String get partySubtitle;

  /// No description provided for @createParty.
  ///
  /// In ko, this message translates to:
  /// **'새 파티'**
  String get createParty;

  /// No description provided for @joinParty.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get joinParty;

  /// No description provided for @randomParty.
  ///
  /// In ko, this message translates to:
  /// **'랜덤'**
  String get randomParty;

  /// No description provided for @partyName.
  ///
  /// In ko, this message translates to:
  /// **'파티 이름'**
  String get partyName;

  /// No description provided for @partyNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 헬지옥 정복단'**
  String get partyNameHint;

  /// No description provided for @partyDescription.
  ///
  /// In ko, this message translates to:
  /// **'파티 설명'**
  String get partyDescription;

  /// No description provided for @partyDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'파티의 목표나 규칙을 적어보세요'**
  String get partyDescriptionHint;

  /// No description provided for @inviteCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get inviteCode;

  /// No description provided for @inviteCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'예: ABC123'**
  String get inviteCodeHint;

  /// No description provided for @create.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get create;

  /// No description provided for @join.
  ///
  /// In ko, this message translates to:
  /// **'가입하기'**
  String get join;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @randomPartyTitle.
  ///
  /// In ko, this message translates to:
  /// **'랜덤 파티 찾기'**
  String get randomPartyTitle;

  /// No description provided for @randomPartyDescription.
  ///
  /// In ko, this message translates to:
  /// **'지금 함께 운동하는 사람들과 만나보세요'**
  String get randomPartyDescription;

  /// No description provided for @openParty.
  ///
  /// In ko, this message translates to:
  /// **'파티 열기'**
  String get openParty;

  /// No description provided for @partyRoom.
  ///
  /// In ko, this message translates to:
  /// **'파티 방'**
  String get partyRoom;

  /// No description provided for @members.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get members;

  /// No description provided for @activity.
  ///
  /// In ko, this message translates to:
  /// **'활동'**
  String get activity;

  /// No description provided for @reaction.
  ///
  /// In ko, this message translates to:
  /// **'응원'**
  String get reaction;

  /// No description provided for @leaveParty.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get leaveParty;

  /// No description provided for @invite.
  ///
  /// In ko, this message translates to:
  /// **'초대'**
  String get invite;

  /// No description provided for @inviteCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드가 복사됐어요'**
  String get inviteCopied;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 캐릭터'**
  String get profileTitle;

  /// No description provided for @profileDescription.
  ///
  /// In ko, this message translates to:
  /// **'운동 기록이 캐릭터를 성장시킵니다'**
  String get profileDescription;

  /// No description provided for @level.
  ///
  /// In ko, this message translates to:
  /// **'레벨'**
  String get level;

  /// No description provided for @strength.
  ///
  /// In ko, this message translates to:
  /// **'근력'**
  String get strength;

  /// No description provided for @endurance.
  ///
  /// In ko, this message translates to:
  /// **'지구력'**
  String get endurance;

  /// No description provided for @consistency.
  ///
  /// In ko, this message translates to:
  /// **'꾸준함'**
  String get consistency;

  /// No description provided for @workoutTags.
  ///
  /// In ko, this message translates to:
  /// **'운동 취향 태그'**
  String get workoutTags;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In ko, this message translates to:
  /// **'설정이 저장되었습니다'**
  String get saved;

  /// No description provided for @tagStrength.
  ///
  /// In ko, this message translates to:
  /// **'근력'**
  String get tagStrength;

  /// No description provided for @tagCardio.
  ///
  /// In ko, this message translates to:
  /// **'유산소'**
  String get tagCardio;

  /// No description provided for @tagHomeTraining.
  ///
  /// In ko, this message translates to:
  /// **'홈트'**
  String get tagHomeTraining;

  /// No description provided for @tagCrossfit.
  ///
  /// In ko, this message translates to:
  /// **'크로스핏'**
  String get tagCrossfit;

  /// No description provided for @tagYoga.
  ///
  /// In ko, this message translates to:
  /// **'요가'**
  String get tagYoga;

  /// No description provided for @tagRunning.
  ///
  /// In ko, this message translates to:
  /// **'러닝'**
  String get tagRunning;

  /// No description provided for @tagSwimming.
  ///
  /// In ko, this message translates to:
  /// **'수영'**
  String get tagSwimming;

  /// No description provided for @streakValue.
  ///
  /// In ko, this message translates to:
  /// **'3일'**
  String get streakValue;

  /// No description provided for @weekWorkoutValue.
  ///
  /// In ko, this message translates to:
  /// **'4회'**
  String get weekWorkoutValue;

  /// No description provided for @partyActivityMessage.
  ///
  /// In ko, this message translates to:
  /// **'오늘 2명의 파티원이 운동했어요'**
  String get partyActivityMessage;

  /// No description provided for @setItem.
  ///
  /// In ko, this message translates to:
  /// **'세트 {number}'**
  String setItem(int number);

  /// No description provided for @samplePartyName.
  ///
  /// In ko, this message translates to:
  /// **'헬지옥 정복단'**
  String get samplePartyName;

  /// No description provided for @samplePartyDescription.
  ///
  /// In ko, this message translates to:
  /// **'주 4회, 끝까지 함께 기록하는 파티'**
  String get samplePartyDescription;

  /// No description provided for @samplePartyNameSecond.
  ///
  /// In ko, this message translates to:
  /// **'새벽 6시 웨이트'**
  String get samplePartyNameSecond;

  /// No description provided for @samplePartyDescriptionSecond.
  ///
  /// In ko, this message translates to:
  /// **'아침 운동 루틴을 만드는 중'**
  String get samplePartyDescriptionSecond;

  /// No description provided for @memberCount.
  ///
  /// In ko, this message translates to:
  /// **'3명'**
  String get memberCount;

  /// No description provided for @memberCountSecond.
  ///
  /// In ko, this message translates to:
  /// **'4명'**
  String get memberCountSecond;

  /// No description provided for @feedMemberJoined.
  ///
  /// In ko, this message translates to:
  /// **'민수님이 파티에 참가했습니다'**
  String get feedMemberJoined;

  /// No description provided for @feedWorkoutStarted.
  ///
  /// In ko, this message translates to:
  /// **'지훈님이 오늘의 운동을 시작했습니다'**
  String get feedWorkoutStarted;

  /// No description provided for @feedWorkoutDone.
  ///
  /// In ko, this message translates to:
  /// **'서연님이 운동을 완료했습니다'**
  String get feedWorkoutDone;

  /// No description provided for @reactionCount.
  ///
  /// In ko, this message translates to:
  /// **'응원 {count}'**
  String reactionCount(int count);

  /// No description provided for @mockOnlyNotice.
  ///
  /// In ko, this message translates to:
  /// **'목업 화면에서는 실제 데이터가 저장되지 않습니다'**
  String get mockOnlyNotice;

  /// No description provided for @recordTypeStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get recordTypeStart;

  /// No description provided for @recordTypeMiddle.
  ///
  /// In ko, this message translates to:
  /// **'중간'**
  String get recordTypeMiddle;

  /// No description provided for @recordTypeEnd.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get recordTypeEnd;

  /// No description provided for @photo.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photo;

  /// No description provided for @photoMockNotice.
  ///
  /// In ko, this message translates to:
  /// **'사진 첨부는 목업에서만 표시됩니다'**
  String get photoMockNotice;

  /// No description provided for @avatarSeed.
  ///
  /// In ko, this message translates to:
  /// **'아바타 시드'**
  String get avatarSeed;

  /// No description provided for @sampleSetDetails.
  ///
  /// In ko, this message translates to:
  /// **'60 kg · 10회'**
  String get sampleSetDetails;

  /// No description provided for @sampleCurrentUser.
  ///
  /// In ko, this message translates to:
  /// **'존'**
  String get sampleCurrentUser;

  /// No description provided for @sampleMemberMinsu.
  ///
  /// In ko, this message translates to:
  /// **'민수'**
  String get sampleMemberMinsu;

  /// No description provided for @sampleMemberSeoyeon.
  ///
  /// In ko, this message translates to:
  /// **'서연'**
  String get sampleMemberSeoyeon;

  /// No description provided for @rest.
  ///
  /// In ko, this message translates to:
  /// **'휴식'**
  String get rest;

  /// No description provided for @addSeconds.
  ///
  /// In ko, this message translates to:
  /// **'+{seconds}초'**
  String addSeconds(int seconds);

  /// No description provided for @skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// No description provided for @selectExercise.
  ///
  /// In ko, this message translates to:
  /// **'종목 선택'**
  String get selectExercise;

  /// No description provided for @setDeleted.
  ///
  /// In ko, this message translates to:
  /// **'세트를 삭제했어요'**
  String get setDeleted;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get undo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

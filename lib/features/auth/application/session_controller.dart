import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../data/repositories/supabase_sync_repository.dart';
import '../../exercise_db/application/exercise_providers.dart';
import '../../feed/application/post_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../../party/application/party_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../routine/application/routine_providers.dart';
import '../../stats/application/stats_providers.dart';
import '../../workout_log/application/workout_providers.dart';
import 'auth_service.dart';

/// 로그인 세션 종료를 한곳에서 처리한다.
final sessionControllerProvider = Provider<SessionController>(
  (ref) => SessionController(ref),
);

/// 로그아웃 결과. 올리지 못한 기록이 있으면 로컬 데이터를 지우지 않는다.
typedef SignOutOutcome = ({bool localDataKept});

class SessionController {
  const SessionController(this._ref);

  final Ref _ref;

  /// 로그아웃하면서 이 기기에 남은 개인 데이터를 지운다. 지우지 않으면 다음에
  /// 로그인한 계정이 이전 사용자의 루틴·운동 기록을 그대로 보게 된다.
  ///
  /// 다만 아직 서버에 올리지 못한 기록이 있으면 지우지 않는다. 지우면 복구할
  /// 방법이 없다. 이 경우 호출자가 사용자에게 알려야 한다.
  Future<SignOutOutcome> signOut() async {
    final pushed = await _pushPending();
    await _ref.read(authServiceProvider).signOut();
    if (pushed) await _ref.read(appDatabaseProvider).clearUserData();
    _invalidateAccountScopedCaches();
    return (localDataKept: !pushed);
  }

  /// 계정과 서버에 남은 모든 기록을 지운다. 되돌릴 수 없다.
  ///
  /// 서버가 사용자 행 하나를 지우면 기록·게시물·파티 활동이 함께 사라진다.
  /// 성공하면 이 기기에 남은 사본도 지우고 로그아웃한다.
  Future<Result<void, Failure>> deleteAccount() async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null || client.auth.currentUser == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다'));
    }
    final userId = client.auth.currentUser!.id;
    try {
      // 파일은 Storage API로만 지울 수 있어 서버 함수가 대신 지워 주지 못한다.
      await _removeUploads(client, userId);
      await client.rpc<void>('delete_my_account');
    } on Object catch (error) {
      return Err(DatabaseFailure('계정을 삭제하지 못했습니다: $error'));
    }
    // 서버에서 지워졌으므로 올릴 것도, 남길 것도 없다.
    await _ref.read(authServiceProvider).signOut();
    await _ref.read(appDatabaseProvider).clearUserData();
    _invalidateAccountScopedCaches();
    return const Ok(null);
  }

  /// 내가 올린 사진·영상을 지운다. 게시물은 `{uid}/파일`, 프로필 사진은
  /// `{uid}/avatar/파일`에 있다.
  Future<void> _removeUploads(SupabaseClient client, String userId) async {
    final bucket = client.storage.from('post-media');
    final paths = <String>[];
    for (final folder in <String>[userId, '$userId/avatar']) {
      final entries = await bucket.list(path: folder);
      for (final entry in entries) {
        // 폴더는 id가 없다. 파일만 모은다.
        if (entry.id == null) continue;
        paths.add('$folder/${entry.name}');
      }
    }
    if (paths.isNotEmpty) await bucket.remove(paths);
  }

  /// 남은 변경을 서버로 올린다. 실패하면 로컬 데이터를 보존한다.
  Future<bool> _pushPending() async {
    try {
      await _ref.read(syncRepositoryProvider).pushAll();
      return true;
    } on Object {
      return false;
    }
  }

  /// 계정에 묶인 캐시. 남겨두면 다음 사용자가 이전 사용자의 화면을 보게 된다.
  void _invalidateAccountScopedCaches() {
    _ref
      ..invalidate(myProfileProvider)
      ..invalidate(myPostsProvider)
      ..invalidate(myFollowCountsProvider)
      ..invalidate(publicFeedProvider)
      ..invalidate(myPartiesProvider)
      ..invalidate(partyExploreProvider)
      ..invalidate(myNotificationsProvider)
      ..invalidate(unreadNotificationCountProvider)
      ..invalidate(routinesProvider)
      ..invalidate(activeSessionProvider)
      ..invalidate(weeklyVolumeProvider)
      ..invalidate(bodyPartSplitProvider);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercise_db/application/exercise_providers.dart';
import 'auth_service.dart';

/// 로그인 세션 종료를 한곳에서 처리한다.
final sessionControllerProvider = Provider<SessionController>(
  (ref) => SessionController(ref),
);

class SessionController {
  const SessionController(this._ref);

  final Ref _ref;

  /// 로그아웃하면서 이 기기에 남은 개인 데이터를 지운다. 지우지 않으면 다음에
  /// 로그인한 계정이 이전 사용자의 루틴·운동 기록을 그대로 보게 된다.
  Future<void> signOut() async {
    await _ref.read(authServiceProvider).signOut();
    await _ref.read(appDatabaseProvider).clearUserData();
  }
}

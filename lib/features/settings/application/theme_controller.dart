import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePreferenceKey = 'theme_id';

/// 선택된 테마 상태. 기본값으로 즉시 렌더하고, 저장된 값은 비동기로 복원한다.
final themeControllerProvider = NotifierProvider<ThemeController, AppThemeId>(
  ThemeController.new,
);

class ThemeController extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    _restore();
    return AppThemeId.appleWhite;
  }

  /// 저장된 테마를 비동기로 불러온다. prefs를 못 쓰면(테스트 등) 기본값을 유지한다.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_themePreferenceKey);
      if (name == null) return;
      for (final id in AppThemeId.values) {
        if (id.name == name && id != state) {
          state = id;
          return;
        }
      }
    } on Object {
      // prefs 불가 — 기본 테마 유지.
    }
  }

  /// 테마를 선택하고 저장한다.
  Future<void> select(AppThemeId id) async {
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, id.name);
    } on Object {
      // 저장 실패는 무시(다음 실행에 기본값).
    }
  }
}

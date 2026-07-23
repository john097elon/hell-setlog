import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/features/settings/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults immediately then restores the saved theme async', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_id': AppThemeId.nikeBlack.name,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 즉시 기본값(렌더 블로킹 없음), 비동기 복원 후 저장값.
    expect(container.read(themeControllerProvider), AppThemeId.appleWhite);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(themeControllerProvider), AppThemeId.nikeBlack);
  });

  test('select updates state and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeControllerProvider.notifier)
        .select(AppThemeId.nikeBlack);
    expect(container.read(themeControllerProvider), AppThemeId.nikeBlack);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_id'), AppThemeId.nikeBlack.name);
  });
}

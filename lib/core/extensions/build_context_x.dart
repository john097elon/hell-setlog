import 'package:flutter/widgets.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

/// BuildContext에서 지역화 문자열에 접근하도록 돕는다.
extension BuildContextX on BuildContext {
  /// 현재 언어의 앱 문자열을 반환한다.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

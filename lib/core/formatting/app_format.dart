// 숫자/단위 표시 포맷. 화면 전역에서 일관된 표기를 위해 여기만 쓴다.
import 'package:characters/characters.dart';

/// 천단위 콤마. `12400` → `"12,400"`.
String formatInt(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

/// 볼륨(kg). 정수면 소수 생략, 아니면 소수 1자리. `12400` → `"12,400"`.
String formatWeight(double kg) {
  if (kg == kg.roundToDouble()) return formatInt(kg);
  final whole = kg.truncate();
  final frac = ((kg - whole).abs() * 10).round();
  return '${formatInt(whole)}.$frac';
}

/// 볼륨 + 단위. `12400` → `"12,400 kg"`.
String formatVolumeKg(double kg) => '${formatWeight(kg)} kg';

/// 큰 볼륨 축약. `12400` → `"12.4K"`, `1200000` → `"1.2M"`. 통계 요약용.
String formatCompactNumber(num value) {
  final v = value.abs();
  final sign = value < 0 ? '-' : '';
  if (v >= 1000000) return '$sign${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '$sign${(v / 1000).toStringAsFixed(1)}K';
  return '$sign${value.round()}';
}

/// 아바타에 넣을 첫 글자. 이름이 비어 있어도 던지지 않는다.
String initialOf(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? '?' : trimmed.characters.first;
}

/// 목록에 쓰는 상대 시각. `방금`, `12분 전`, `3일 전`, 그 이상은 날짜.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${time.month}월 ${time.day}일';
}

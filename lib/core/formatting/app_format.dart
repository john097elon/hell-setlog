// 숫자/단위 표시 포맷. 화면 전역에서 일관된 표기를 위해 여기만 쓴다.
import 'package:characters/characters.dart';

const double poundsPerKilogram = 2.20462;

enum WeightUnit { kg, lb }

/// kg로 저장된 값을 선택한 표시 단위로 바꾼다.
double weightFromKg(double kg, WeightUnit unit) =>
    unit == WeightUnit.kg ? kg : kg * poundsPerKilogram;

/// 선택한 표시 단위로 입력된 값을 저장 단위인 kg로 바꾼다.
double weightToKg(double value, WeightUnit unit) =>
    unit == WeightUnit.kg ? value : value / poundsPerKilogram;

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

/// kg로 저장된 무게를 선택 단위로 표시한다. 정수면 소수를 생략한다.
String formatWeight(double kg, {WeightUnit unit = WeightUnit.kg}) {
  final value = weightFromKg(kg, unit);
  // 소수 첫째 자리로 먼저 반올림해야 1.96이 '1.10'으로 새지 않는다.
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return formatInt(rounded);
  final whole = rounded.truncate();
  final frac = ((rounded - whole).abs() * 10).round();
  return '${formatInt(whole)}.$frac';
}

/// kg로 저장된 무게와 선택 단위를 함께 표시한다.
String formatWeightWithUnit(double kg, {WeightUnit unit = WeightUnit.kg}) =>
    '${formatWeight(kg, unit: unit)} ${unit.name}';

/// 큰 kg 값을 선택 단위로 변환해 축약 표시한다.
String formatCompactWeight(double kg, {WeightUnit unit = WeightUnit.kg}) =>
    '${formatCompactNumber(weightFromKg(kg, unit))} ${unit.name}';

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

/// 거리(m)를 사람이 읽는 문구로. 1km 미만은 m로 둔다.
String formatDistance(double meters) {
  if (meters <= 0) return '0m';
  if (meters < 1000) return '${meters.round()}m';
  final km = meters / 1000;
  final rounded = (km * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? '${formatInt(rounded)}km'
      : '${rounded.toStringAsFixed(1)}km';
}

/// 시간(초)을 사람이 읽는 문구로. 한 시간이 넘으면 시간까지 보여준다.
String formatDuration(int seconds) {
  if (seconds <= 0) return '0분';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours <= 0) return '$minutes분';
  return minutes == 0 ? '$hours시간' : '$hours시간 $minutes분';
}

/// 속도(m/s)를 달리기 페이스(분'초"/km)로 바꾼다. 페이스는 낮을수록 빠르다.
String formatPace(double metersPerSecond) {
  if (metersPerSecond <= 0) return '-';
  final secondsPerKm = 1000 / metersPerSecond;
  final minutes = secondsPerKm ~/ 60;
  final seconds = (secondsPerKm % 60).round();
  final normalizedMinutes = seconds == 60 ? minutes + 1 : minutes;
  final normalizedSeconds = seconds == 60 ? 0 : seconds;
  return "$normalizedMinutes'${normalizedSeconds.toString().padLeft(2, '0')}\"/km";
}

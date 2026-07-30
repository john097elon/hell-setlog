// Supabase(PostgREST) 응답을 안전하게 읽는다.
//
// PostgREST는 정밀도 보존을 위해 numeric 계열을 문자열로 돌려줄 수 있고,
// 스키마 변경 중에는 기대한 컬럼이 없을 수도 있다. 캐스팅으로 바로 열면
// 목록 하나 때문에 화면 전체가 죽으므로 여기서만 변환한다.

/// 문자열을 읽는다. 없으면 [fallback].
String rowString(Map<String, Object?> row, String key, {String fallback = ''}) {
  final value = row[key];
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

/// 문자열을 읽는다. 비었거나 없으면 null.
String? rowStringOrNull(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is String) return value.isEmpty ? null : value;
  if (value == null) return null;
  return value.toString();
}

/// 실수를 읽는다. `numeric`이 문자열로 와도 처리한다.
double? rowDouble(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// 정수를 읽는다. 문자열/실수로 와도 처리한다.
int? rowInt(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String)
    return int.tryParse(value) ?? double.tryParse(value)?.round();
  return null;
}

/// 참/거짓을 읽는다. 없으면 [fallback].
bool rowBool(Map<String, Object?> row, String key, {bool fallback = false}) {
  final value = row[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == 'true' || value == 't' || value == '1';
  return fallback;
}

/// 시각을 읽는다. 파싱에 실패하면 [fallback] 또는 현재 시각.
DateTime rowDate(Map<String, Object?> row, String key, {DateTime? fallback}) {
  final value = row[key];
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.now();
}

/// 시각을 읽는다. 없거나 파싱 실패면 null.
DateTime? rowDateOrNull(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// 조인으로 함께 온 하위 객체를 읽는다. 배열로 오면 첫 항목을 쓴다.
Map<String, Object?>? rowNested(Map<String, Object?> row, String key) {
  final value = row[key];
  if (value is Map) return Map<String, Object?>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, Object?>.from(value.first as Map);
  }
  return null;
}

/// 응답 목록을 행 맵 목록으로 바꾼다. 형태가 달라도 던지지 않는다.
List<Map<String, Object?>> rowList(Object? response) {
  if (response is! List) return const <Map<String, Object?>>[];
  return <Map<String, Object?>>[
    for (final item in response)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

/// In-memory content displayed by the video share mock sheet.
class ShareViewData {
  const ShareViewData({
    required this.workoutTags,
    this.sessionId,
    this.volumeKg,
    this.durationMin,
    this.bodyPart,
    this.prLabel,
    this.xp,
  });

  final List<String> workoutTags;

  /// 게시물에 함께 저장할 세션 지표다.
  final String? sessionId;
  final double? volumeKg;
  final int? durationMin;
  final String? bodyPart;

  /// 이번 세션에서 세운 개인 기록과 얻은 경험치.
  final String? prLabel;
  final int? xp;

  static const mock = ShareViewData(
    workoutTags: <String>['BENCH 80KG × 4', 'SQUAT 100KG × 3', '+210 XP'],
  );
}

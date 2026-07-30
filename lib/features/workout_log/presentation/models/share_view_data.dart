/// In-memory content displayed by the video share mock sheet.
class ShareViewData {
  const ShareViewData({
    required this.workoutTags,
    this.sessionId,
    this.volumeKg,
    this.durationMin,
    this.bodyPart,
  });

  final List<String> workoutTags;

  /// 게시물에 함께 저장할 세션 지표다.
  final String? sessionId;
  final double? volumeKg;
  final int? durationMin;
  final String? bodyPart;

  static const mock = ShareViewData(
    workoutTags: <String>['BENCH 80KG × 4', 'SQUAT 100KG × 3', '+210 XP'],
  );
}

/// In-memory content displayed by the video share mock sheet.
class ShareViewData {
  const ShareViewData({required this.workoutTags});

  final List<String> workoutTags;

  static const mock = ShareViewData(
    workoutTags: <String>['BENCH 80KG × 4', 'SQUAT 100KG × 3', '+210 XP'],
  );
}

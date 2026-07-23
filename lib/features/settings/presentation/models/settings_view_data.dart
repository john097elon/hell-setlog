/// Settings screen data used only by the in-memory presentation mock.
class SettingsViewData {
  const SettingsViewData({
    required this.name,
    required this.level,
    required this.experience,
  });

  final String name;
  final int level;
  final int experience;

  static const mock = SettingsViewData(name: '존', level: 12, experience: 820);
}

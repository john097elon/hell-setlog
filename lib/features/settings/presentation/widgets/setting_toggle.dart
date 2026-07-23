import 'package:flutter/material.dart';

/// A settings row paired with a Material switch.
class SettingToggle extends StatelessWidget {
  const SettingToggle({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) =>
      SwitchListTile(title: Text(title), value: value, onChanged: onChanged);
}

import 'package:flutter/widgets.dart';

/// 숫자 칸을 탭하면 있던 값을 통째로 고른다.
///
/// 그러지 않으면 60을 65로 고치려고 백스페이스를 두 번 눌러야 한다. 운동 중에는
/// 이 한 번이 크다.
VoidCallback selectAllOnTap(TextEditingController controller) => () {
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );
};

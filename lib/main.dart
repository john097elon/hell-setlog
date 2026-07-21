import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 헬셋로그 애플리케이션을 시작한다.
void main() {
  runApp(const ProviderScope(child: HealSetLogApp()));
}

/// P0 기반 애플리케이션 루트다.
class HealSetLogApp extends StatelessWidget {
  /// 애플리케이션 루트를 생성한다.
  const HealSetLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
  }
}

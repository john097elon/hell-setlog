import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';

/// 다섯 개의 주요 목업 화면을 전환하는 하단 내비게이션 셸이다.
class AppShell extends StatelessWidget {
  /// 하단 내비게이션 위에 표시할 현재 라우트 화면이다.
  const AppShell({required this.child, super.key});

  /// 현재 라우트가 렌더링한 화면이다.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final int selectedIndex = _selectedIndex(
      GoRouterState.of(context).uri.path,
    );
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) => context.go(_paths[index]),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: copy.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            label: copy.record,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: copy.stats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: copy.party,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: copy.profile,
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String path) =>
      _paths.indexWhere((String item) => path.startsWith(item));
}

const List<String> _paths = <String>[
  '/home',
  '/workout',
  '/stats',
  '/party',
  '/profile',
];

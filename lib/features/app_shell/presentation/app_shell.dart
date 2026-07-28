import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

/// 네 개의 주요 화면을 전환하는 하단 내비게이션 셸이다.
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
      bottomNavigationBar: DecoratedBox(
        // 두 테마 모두에서 보이는 구분선(다크에서 사라지지 않게).
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.tokens.border)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) => context.go(_paths[index]),
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: copy.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.fitness_center_outlined),
              selectedIcon: const Icon(Icons.fitness_center),
              label: copy.workout,
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
      ),
    );
  }

  int _selectedIndex(String path) {
    if (path.startsWith('/workout') || path.startsWith('/routines')) return 1;
    return _paths.indexWhere((String item) => path.startsWith(item));
  }
}

const List<String> _paths = <String>['/home', '/workout', '/party', '/profile'];

import 'package:go_router/go_router.dart';
import 'package:heal_setlog/features/app_shell/presentation/app_shell.dart';
import 'package:heal_setlog/features/auth/presentation/login_page.dart';
import 'package:heal_setlog/features/auth/presentation/register_page.dart';
import 'package:heal_setlog/features/home/presentation/home_page.dart';
import 'package:heal_setlog/features/character/presentation/profile_page.dart';
import 'package:heal_setlog/features/party/presentation/party_list_page.dart';
import 'package:heal_setlog/features/party/presentation/party_room_page.dart';
import 'package:heal_setlog/features/stats/presentation/stats_page.dart';
import 'package:heal_setlog/features/workout_log/presentation/workout_page.dart';

/// 애플리케이션 목업의 새 라우터 인스턴스를 생성한다.
GoRouter createAppRouter() => GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/party/room',
      builder: (context, state) => const PartyRoomPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/workout',
          builder: (context, state) => const WorkoutPage(),
        ),
        GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
        GoRoute(
          path: '/party',
          builder: (context, state) => const PartyListPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);

import 'package:go_router/go_router.dart';
import 'package:heal_setlog/features/app_shell/presentation/app_shell.dart';
import 'package:heal_setlog/features/auth/presentation/login_page.dart';
import 'package:heal_setlog/features/auth/presentation/register_page.dart';
import 'package:heal_setlog/features/home/presentation/dashboard_page.dart';
import 'package:heal_setlog/features/home/presentation/home_page.dart';
import 'package:heal_setlog/features/settings/presentation/settings_page.dart';
import 'package:heal_setlog/features/profile/presentation/my_profile_page.dart';
import 'package:heal_setlog/features/party/presentation/party_page.dart';
import 'package:heal_setlog/features/party/presentation/party_room_page.dart';
import 'package:heal_setlog/features/app_shell/presentation/workout_tab_page.dart';
import 'package:heal_setlog/features/routine/presentation/routine_editor_page.dart';
import 'package:heal_setlog/features/routine/presentation/routine_detail_page.dart';
import 'package:heal_setlog/features/routine/presentation/routine_list_page.dart';
import 'package:heal_setlog/features/onboarding/presentation/onboarding_page.dart';
import 'package:heal_setlog/features/notifications/presentation/notifications_page.dart';
import 'package:heal_setlog/features/search/presentation/search_page.dart';
import 'package:heal_setlog/core/config/app_env.dart';
import 'package:heal_setlog/core/supabase/supabase_init.dart';

/// 애플리케이션 목업의 새 라우터 인스턴스를 생성한다.
GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? '/login',
  redirect: (context, state) {
    if (state.matchedLocation == '/onboarding') return null;
    if (!isSupabaseConfigured) return null;
    final signedIn = supabaseClientOrNull?.auth.currentSession != null;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    if (!signedIn && !isAuthRoute) return '/login';
    if (signedIn && isAuthRoute) return '/home';
    return null;
  },
  routes: <RouteBase>[
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/party/room/:id',
      builder: (context, state) =>
          PartyRoomPage(partyId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          OnboardingPage(onDone: () => context.go('/login')),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
    // 피드는 부가 기능이라 하단 탭이 아니라 홈 상단에서 들어간다.
    GoRoute(path: '/feed', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/workout',
          builder: (context, state) => const WorkoutTabPage(),
        ),
        GoRoute(
          path: '/routines',
          builder: (context, state) => const RoutineListPage(),
        ),
        GoRoute(
          path: '/routines/detail/:id',
          builder: (context, state) =>
              RoutineDetailPage(routineId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/routines/edit/:id',
          builder: (context, state) => RoutineEditorPage(
            routineId: state.pathParameters['id'] == 'new'
                ? null
                : state.pathParameters['id'],
          ),
        ),
        GoRoute(path: '/party', builder: (context, state) => const PartyPage()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const MyProfilePage(),
        ),
      ],
    ),
  ],
);

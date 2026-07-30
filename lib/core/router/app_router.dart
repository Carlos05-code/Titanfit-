import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import '../../features/workout/presentation/screens/workout_detail_screen.dart';
import '../../features/workout/presentation/screens/workout_session_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/sleep/presentation/screens/sleep_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/splash');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute && state.matchedLocation != '/splash') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/workouts',
            builder: (_, __) => const WorkoutScreen(),
          ),
          GoRoute(
            path: '/workouts/:id',
            builder: (_, state) => WorkoutDetailScreen(
              workoutId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/workouts/session',
            builder: (_, __) => const WorkoutSessionScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (_, __) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/sleep',
            builder: (_, __) => const SleepScreen(),
          ),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/reminders',
            builder: (_, __) => const RemindersScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(context),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.bedtime), label: 'Sleep'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/workouts')) return 1;
    if (location.startsWith('/habits')) return 2;
    if (location.startsWith('/sleep')) return 3;
    if (location.startsWith('/progress')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/workouts');
      case 2: context.go('/habits');
      case 3: context.go('/sleep');
      case 4: context.go('/progress');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:gate_pass_flutter/screens/profile/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/gate_pass_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/security/security_dashboard.dart';
import 'utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GatePassProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Gate Pass Management',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: _createRouter(authProvider),
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final user = authProvider.user;

        // If not logged in and trying to access protected route
        if (!isLoggedIn && !_isPublicRoute(state.matchedLocation)) {
          return '/login';
        }

        // If logged in and trying to access auth routes
        if (isLoggedIn && _isAuthRoute(state.matchedLocation)) {
          return _getDashboardRoute(user?.role ?? '');
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/student',
          builder: (context, state) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const TeacherDashboard(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecurityDashboard(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );
  }

  bool _isPublicRoute(String route) {
    const publicRoutes = ['/splash', '/login', '/register'];
    return publicRoutes.contains(route);
  }

  bool _isAuthRoute(String route) {
    const authRoutes = ['/login', '/register'];
    return authRoutes.contains(route);
  }

  String _getDashboardRoute(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return '/admin';
      case 'TEACHER':
        return '/teacher';
      case 'STUDENT':
        return '/student';
      case 'SECURITY':
        return '/security';
      default:
        return '/login';
    }
  }
}

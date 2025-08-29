// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this import
import 'providers/auth_provider.dart';
import 'providers/gate_pass_provider.dart';
import 'providers/admin_provider.dart'; // Add this import
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/approved_students_screen.dart'; // Add this import
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
        ChangeNotifierProvider(create: (_) => AdminProvider()), // Add this line
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Gate Pass Management',
            theme: AppTheme.lightTheme.copyWith(
              // Override the theme with Poppins font family
              textTheme: GoogleFonts.poppinsTextTheme(
                AppTheme.lightTheme.textTheme,
              ),
              // Also apply to primary text theme for consistency
              primaryTextTheme: GoogleFonts.poppinsTextTheme(
                AppTheme.lightTheme.primaryTextTheme,
              ),
            ),
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
          return _getDashboardRoute(user?.role ?? 'STUDENT');
        }

        return null;
      },
      routes: [
        // Public routes
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

        // Protected routes
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
          path: '/admin/approved-students',
          builder: (context, state) => const ApprovedStudentsScreen(),
        ),
        GoRoute(
          path: '/security',
          builder: (context, state) => const SecurityDashboard(),
        ),
      ],
    );
  }

  bool _isPublicRoute(String route) {
    return ['/splash', '/login', '/register'].contains(route);
  }

  bool _isAuthRoute(String route) {
    return ['/login', '/register', '/splash'].contains(route);
  }

  String _getDashboardRoute(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return '/admin';
      case 'TEACHER':
        return '/teacher';
      case 'SECURITY':
        return '/security';
      case 'STUDENT':
      default:
        return '/student';
    }
  }
}
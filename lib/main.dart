// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/gate_pass_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/approved_students_screen.dart';
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
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Gate Pass Management',
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                AppTheme.lightTheme.textTheme,
              ),
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
      // Disable automatic redirects during auth operations
      redirect: (context, state) {
        // Don't redirect while loading or not initialized
        if (!authProvider.isInitialized) {
          return null; // Stay on current route
        }

        final location = state.matchedLocation;
        final isLoggedIn = authProvider.isLoggedIn;

        debugPrint('Router redirect - Location: $location, LoggedIn: $isLoggedIn, Loading: ${authProvider.isLoading}');

        // If we're loading, don't redirect
        if (authProvider.isLoading) {
          return null;
        }

        // If not logged in and trying to access protected route
        if (!isLoggedIn && _isProtectedRoute(location)) {
          if (location != '/login') {
            debugPrint('Redirecting to login from protected route: $location');
            return '/login';
          }
        }

        // If logged in and on auth routes, redirect to dashboard
        if (isLoggedIn && _isAuthRoute(location)) {
          final dashboardRoute = _getDashboardRoute(authProvider.user?.role ?? 'STUDENT');
          debugPrint('Redirecting logged in user from $location to $dashboardRoute');
          return dashboardRoute;
        }

        return null; // No redirect needed
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

  bool _isProtectedRoute(String route) {
    const protectedRoutes = [
      '/student',
      '/teacher', 
      '/admin',
      '/security',
    ];
    
    return protectedRoutes.any((protectedRoute) => 
      route.startsWith(protectedRoute)
    );
  }

  bool _isAuthRoute(String route) {
    return ['/login', '/register'].contains(route);
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
// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white70,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if already loading
    if (authProvider.isLoading) {
      debugPrint('Login already in progress, ignoring request');
      return;
    }
    
    try {
      debugPrint('=== STARTING LOGIN ===');
      debugPrint('Email: ${_emailController.text.trim()}');
      debugPrint('AuthProvider loading: ${authProvider.isLoading}');
      
      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      debugPrint('=== LOGIN RESULT ===');
      debugPrint('Success: ${result.isSuccess}');
      debugPrint('Message: ${result.message}');
      debugPrint('AuthProvider loading after: ${authProvider.isLoading}');

      // Force a small delay to ensure state updates
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      if (result.isSuccess) {
        debugPrint('=== LOGIN SUCCESS ===');
        debugPrint('User: ${authProvider.user?.name}');
        debugPrint('Role: ${authProvider.user?.role}');
        
        _showSuccessSnackBar('Welcome back, ${authProvider.user?.name ?? 'User'}!');
        
        // Wait for success message to show
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (!mounted) return;
        
        // Navigate based on role
        final role = authProvider.user?.role?.toUpperCase() ?? 'STUDENT';
        String targetRoute;
        
        switch (role) {
          case 'SUPER_ADMIN':
            targetRoute = '/admin';
            break;
          case 'TEACHER':
            targetRoute = '/teacher';
            break;
          case 'SECURITY':
            targetRoute = '/security';
            break;
          case 'STUDENT':
          default:
            targetRoute = '/student';
            break;
        }
        
        debugPrint('=== NAVIGATING TO: $targetRoute ===');
        context.go(targetRoute);
        
      } else {
        debugPrint('=== LOGIN FAILED ===');
        debugPrint('Showing error: ${result.message}');
        _showErrorSnackBar(result.message);
      }
    } catch (e, stackTrace) {
      debugPrint('=== LOGIN EXCEPTION ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      
      if (!mounted) return;
      
      _showErrorSnackBar('Login failed: ${e.toString()}');
    }
    
    // Force UI update
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            debugPrint('Building login screen - isLoading: ${authProvider.isLoading}');
            
            return SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),
                          
                          // Logo and Title
                          Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryYellow,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryYellow.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Welcome Back',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to your account',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Login Form
                          Card(
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Debug info (remove in production)
                                    if (authProvider.isLoading)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue[200]!),
                                        ),
                                        child: const Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Processing login...', 
                                                style: TextStyle(color: Colors.blue, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    
                                    CustomTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      hintText: 'Enter your email',
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.email_outlined,
                                      enabled: !authProvider.isLoading,
                                      validator: EmailValidator.validateEmail,
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hintText: 'Enter your password',
                                      obscureText: true,
                                      prefixIcon: Icons.lock_outlined,
                                      enabled: !authProvider.isLoading,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    CustomButton(
                                      onPressed: authProvider.isLoading ? null : _handleLogin,
                                      text: authProvider.isLoading ? 'Signing In...' : 'Sign In',
                                      isLoading: authProvider.isLoading,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: authProvider.isLoading ? Colors.grey : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: authProvider.isLoading ? null : () => context.go('/register'),
                                child: Text(
                                  'Register as Student',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: authProvider.isLoading ? Colors.grey : AppTheme.primaryYellow,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
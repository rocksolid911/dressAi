import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Start minimum splash screen duration
    _startMinimumDelay();
  }

  Future<void> _startMinimumDelay() async {
    // Wait minimum 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));
  }

  void _navigateBasedOnAuthState(AuthState state) {
    if (_hasNavigated || !mounted) return;

    // Only navigate when we have a definitive auth state (not initial or loading)
    if (state is AuthAuthenticated) {
      _hasNavigated = true;
      final user = state.user;
      if (user.onboardingCompleted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } else if (state is AuthUnauthenticated) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (state is AuthError) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed('/login');
    }
    // For AuthInitial and AuthLoading, keep showing splash screen
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _navigateBasedOnAuthState(state);
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.checkroom_rounded,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                Text(
                  'Digital Wardrobe',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI-Powered Style Assistant',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

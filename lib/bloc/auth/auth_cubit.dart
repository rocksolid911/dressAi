import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  AuthCubit() : super(const AuthInitial()) {
    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        emit(const AuthUnauthenticated());
      }
    });
  }

  // Load user data
  Future<void> _loadUserData(String userId) async {
    try {
      final user = await _authService.getUserData(userId);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        emit(AuthAuthenticated(user));
        return true;
      } else {
        emit(const AuthUnauthenticated());
        return false;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (user != null) {
        emit(AuthAuthenticated(user));
        return true;
      } else {
        emit(const AuthUnauthenticated());
        return false;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      emit(const AuthLoading());

      final user = await _authService.signInWithGoogle();

      if (user != null) {
        emit(AuthAuthenticated(user));
        return true;
      } else {
        emit(const AuthUnauthenticated());
        return false;
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      emit(const AuthLoading());

      await _authService.updateUserData(updatedUser);
      emit(AuthAuthenticated(updatedUser));
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Complete onboarding
  Future<bool> completeOnboarding({
    required String city,
    required String genderPreference,
    required List<String> stylePreferences,
    required Map<String, String> sizes,
  }) async {
    if (state is! AuthAuthenticated) return false;

    try {
      final currentUser = (state as AuthAuthenticated).user;
      final updatedUser = currentUser.copyWith(
        city: city,
        genderPreference: genderPreference,
        stylePreferences: stylePreferences,
        sizes: sizes,
        onboardingCompleted: true,
        updatedAt: DateTime.now(),
      );

      return await updateProfile(updatedUser);
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      emit(const AuthLoading());

      await _authService.sendPasswordResetEmail(email);
      emit(const AuthUnauthenticated());
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      emit(const AuthLoading());

      await _authService.deleteAccount();
      emit(const AuthUnauthenticated());
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // Clear error
  void clearError() {
    if (state is AuthError) {
      emit(const AuthUnauthenticated());
    }
  }

  // Get current user
  UserModel? get currentUser {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    }
    return null;
  }

  // Check if authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

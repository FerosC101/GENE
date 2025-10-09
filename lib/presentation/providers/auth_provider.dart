// lib/presentation/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_hospital_app/data/models/user_model.dart';
import 'package:smart_hospital_app/data/models/user_type.dart';
import 'package:smart_hospital_app/services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user data provider
final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  await for (final user in authState.stream) {
    if (user != null) {
      final userData = await ref.read(authServiceProvider).getUserData(user.uid);
      yield userData;
    } else {
      yield null;
    }
  }
});

// Auth controller
class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.loading());

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserType userType,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        userType: userType,
        phoneNumber: phoneNumber,
        additionalData: additionalData,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
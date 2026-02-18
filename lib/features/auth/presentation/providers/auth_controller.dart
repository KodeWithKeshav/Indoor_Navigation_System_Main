import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'auth_providers.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../admin_map/presentation/providers/admin_map_providers.dart';

final authControllerProvider = NotifierProvider<AuthController, bool>(AuthController.new);

class AuthController extends Notifier<bool> {
  late final LoginUseCase _loginUseCase;

  @override
  bool build() {
    _loginUseCase = ref.read(loginUseCaseProvider);
    return false;
  }

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    print('AuthController: Attempting login for $email');
    state = true; // Loading
    final result = await _loginUseCase(LoginParams(email: email, password: password));
    state = false; // Not loading

    result.fold(
      (failure) {
        print('AuthController: Login failed - ${failure.message}');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (user) {
        print('AuthController: Login success. User: ${user.email}, Role: ${user.role}');
        ref.read(currentUserProvider.notifier).setUser(user);
        // User login success
      },
    );
  }

  Future<void> loginAdmin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = true; // Loading
    final result = await _loginUseCase(LoginParams(email: email, password: password));
    state = false; // Not loading

    result.fold(
      (failure) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (user) {
        if (user.role == UserRole.admin) {
           ref.read(currentUserProvider.notifier).setUser(user);
           // Admin login success
        } else {
          // Not an admin, logout immediately
          ref.read(authRemoteDataSourceProvider).logout(); // Direct logout or use usecase
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Access Denied: Admins only')),
            );
          }
        }
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    state = true;
    
    // Clear navigation state before logout to prevent it from leaking between sessions
    ref.read(navigationProvider.notifier).clear();
    ref.read(graphServiceProvider).markDirty();
    
    await ref.read(authRemoteDataSourceProvider).logout();
    ref.read(currentUserProvider.notifier).setUser(null);
    state = false;
    
    // Router should handle redirect since user is now null
  }
}

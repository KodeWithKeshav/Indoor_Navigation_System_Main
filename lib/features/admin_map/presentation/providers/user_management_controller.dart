import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final allUsersProvider = FutureProvider.autoDispose<List<UserEntity>>((ref) async {
  final useCase = ref.watch(manageUsersUseCaseProvider);
  final result = await useCase.getAllUsers();
  return result.fold(
    (failure) => throw failure.message,
    (users) => users,
  );
});

class UserManagementController extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<void> updateUserRole(String uid, UserRole newRole) async {
    state = true;
    final useCase = ref.read(manageUsersUseCaseProvider);
    final result = await useCase.updateUserRole(uid: uid, role: newRole.name);
    state = false;

    result.fold(
      (failure) => throw failure.message, // Caller should handle error or show snackbar
      (_) => ref.refresh(allUsersProvider),
    );
  }
}

final userManagementControllerProvider = NotifierProvider<UserManagementController, bool>(UserManagementController.new);

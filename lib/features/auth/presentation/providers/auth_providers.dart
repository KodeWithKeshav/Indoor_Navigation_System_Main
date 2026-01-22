import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/manage_users_usecase.dart';
import '../../domain/entities/user_entity.dart';

final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

final loginUseCaseProvider = Provider((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final manageUsersUseCaseProvider = Provider((ref) {
  return ManageUsersUseCase(ref.read(authRepositoryProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(firebaseAuthProvider).authStateChanges();
});

// A provider to manage user state
class CurrentUserNotifier extends Notifier<UserEntity?> {
  @override
  UserEntity? build() => null;
  
  void setUser(UserEntity? user) {
    state = user;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserEntity?>(CurrentUserNotifier.new);

final userProfileProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user != null) {
      final remoteDataSource = ref.read(authRemoteDataSourceProvider);
      final userModel = await remoteDataSource.getCurrentUser();
      ref.read(currentUserProvider.notifier).setUser(userModel);
      return userModel;
  } else {
    ref.read(currentUserProvider.notifier).setUser(null);
  }
  return null;
});


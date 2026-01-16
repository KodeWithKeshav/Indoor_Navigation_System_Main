import 'package:equatable/equatable.dart';

enum UserRole { admin, user }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final UserRole role;
  final String organizationId;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.organizationId = '',
  });

  @override
  List<Object> get props => [id, email, role, organizationId];
}

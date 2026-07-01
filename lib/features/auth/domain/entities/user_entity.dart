import 'package:equatable/equatable.dart';

/// User entity - Pure business object (no dependencies)
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;

  /// Backend role: 'manager' or 'member'. The app maps this to admin/user.
  final String role;

  const UserEntity({required this.id, required this.email, required this.name, this.phone, this.photoUrl, this.role = 'member'});

  /// Whether this user manages a mess (maps to the admin experience).
  bool get isManager => role == 'manager';

  @override
  List<Object?> get props => [id, email, name, phone, photoUrl, role];
}

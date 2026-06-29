import 'package:equatable/equatable.dart';

/// User entity - Pure business object (no dependencies)
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  const UserEntity({required this.id, required this.email, required this.name, this.photoUrl});

  @override
  List<Object?> get props => [id, email, name, photoUrl];
}

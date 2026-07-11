import 'package:equatable/equatable.dart';

/// User entity - Pure business object (no dependencies)
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final CurrentSeasonEntity? currentSeason;

  /// Backend role: 'manager' or 'member'. The app maps this to admin/user.
  final String role;

  const UserEntity({required this.id, required this.email, required this.name, this.phone, this.photoUrl, this.currentSeason, this.role = 'member'});

  /// Whether this user manages a mess (maps to the admin experience).
  bool get isManager => role == 'manager';

  @override
  List<Object?> get props => [id, email, name, phone, photoUrl, currentSeason, role];
}

class CurrentSeasonEntity extends Equatable {
  final int id;
  final String name;
  final int messId;
  final String messName;
  final String? startDate;
  final String? endDate;
  final String status;

  const CurrentSeasonEntity({required this.id, required this.name, required this.messId, required this.messName, required this.status, this.startDate, this.endDate});

  @override
  List<Object?> get props => [id, name, messId, messName, startDate, endDate, status];
}

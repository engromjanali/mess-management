import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The two roles the app supports while we preview each experience.
enum UserRole {
  user,
  admin;

  bool get isAdmin => this == UserRole.admin;

  String get label => this == UserRole.admin ? 'Admin' : 'User';

  IconData get icon => this == UserRole.admin ? Icons.admin_panel_settings_rounded : Icons.person_rounded;
}

/// Holds the currently previewed [UserRole].
///
/// Temporary dev affordance: a global floating button toggles this so we can
/// see the app rendered for each role without a real auth/role backend.
class RoleCubit extends Cubit<UserRole> {
  RoleCubit() : super(UserRole.user);

  void toggle() => emit(state.isAdmin ? UserRole.user : UserRole.admin);

  void setRole(UserRole role) => emit(role);
}

import 'dart:async';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The mess roles supported by the app.
enum UserRole {
  member,
  manager,
  actingManager;

  bool get canManage => this == UserRole.manager || this == UserRole.actingManager;

  IconData get icon => canManage ? Icons.admin_panel_settings_rounded : Icons.person_rounded;
}

/// Derives the UI role from the authenticated server profile.
class RoleCubit extends Cubit<UserRole> {
  RoleCubit(AuthBloc authBloc) : super(_roleFrom(authBloc.state)) {
    _subscription = authBloc.stream.listen((state) => emit(_roleFrom(state)));
  }

  late final StreamSubscription<AuthState> _subscription;

  static UserRole _roleFrom(AuthState state) => state.maybeWhen(
    authenticated: (user) => switch (user.role) {
      'manager' => UserRole.manager,
      'acting_manager' => UserRole.actingManager,
      _ => UserRole.member,
    },
    orElse: () => UserRole.member,
  );

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

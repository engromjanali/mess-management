import 'dart:async';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The two role-based experiences supported by the app.
enum UserRole {
  user,
  admin;

  bool get isAdmin => this == UserRole.admin;

  String get label => this == UserRole.admin ? 'Admin' : 'User';

  IconData get icon => this == UserRole.admin ? Icons.admin_panel_settings_rounded : Icons.person_rounded;
}

/// Derives the UI role from the authenticated server profile.
class RoleCubit extends Cubit<UserRole> {
  RoleCubit(AuthBloc authBloc) : super(_roleFrom(authBloc.state)) {
    _subscription = authBloc.stream.listen((state) => emit(_roleFrom(state)));
  }

  late final StreamSubscription<AuthState> _subscription;

  static UserRole _roleFrom(AuthState state) => state.maybeWhen(authenticated: (user) => user.isManager ? UserRole.admin : UserRole.user, orElse: () => UserRole.user);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

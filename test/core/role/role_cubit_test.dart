import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _TestAuthBloc(super.initialState);

  void update(AuthState state) => emit(state);

  @override
  Future<void> refreshProfile() async {}
}

AuthState signedIn(String role) => AuthState.authenticated(UserEntity(id: '1', email: 'user@example.com', name: 'User', activeMessId: 1, role: role));

void main() {
  test('Restored server roles determine the initial experience and unknown roles fail closed', () async {
    for (final role in ['member', 'manager', 'acting_manager', 'admin', 'unknown']) {
      final auth = _TestAuthBloc(signedIn(role));
      final cubit = RoleCubit(auth);
      expect(cubit.state.isAdmin, role == 'manager' || role == 'acting_manager');
      await cubit.close();
      await auth.close();
    }
  });

  test('Profile changes, ownership transfers and logout replace the current role', () async {
    final auth = _TestAuthBloc(signedIn('member'));
    final cubit = RoleCubit(auth);
    final changes = expectLater(cubit.stream, emitsInOrder([UserRole.admin, UserRole.user, UserRole.admin, UserRole.user]));
    auth.update(signedIn('manager'));
    auth.update(signedIn('member'));
    auth.update(signedIn('acting_manager'));
    auth.update(const AuthState.unauthenticated());
    await changes;
    expect(cubit.state, UserRole.user);
    await cubit.close();
    auth.update(signedIn('manager'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, UserRole.user);
    await auth.close();
  });

  test('Initial, loading and failed authentication never grant manager access', () async {
    for (final state in [const AuthState.initial(), const AuthState.loading(), const AuthState.error('Failed')]) {
      final auth = _TestAuthBloc(state);
      final cubit = RoleCubit(auth);
      expect(cubit.state.isAdmin, isFalse);
      await cubit.close();
      await auth.close();
    }
  });
}

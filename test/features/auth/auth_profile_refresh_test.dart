import 'dart:async';

import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/domain/repositories/auth_repository.dart';
import 'package:mess_pilot/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/login_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/register_usecase.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProfileRepository implements AuthRepository {
  Future<Result<UserEntity?>> Function()? profile;
  int requests = 0;

  @override
  ResultFuture<UserEntity?> getCurrentUser() {
    requests++;
    return profile!();
  }

  @override
  ResultFuture<void> logout() async => const Success(data: null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const original = UserEntity(id: '1', email: 'member@example.com', name: 'Member', activeMessId: 2);
  const updated = UserEntity(id: '1', email: 'member@example.com', name: 'Member', activeMessId: 1);
  late _ProfileRepository repository;
  late AuthBloc bloc;

  setUp(() async {
    repository = _ProfileRepository();
    bloc = AuthBloc(LoginUseCase(repository), RegisterUseCase(repository), LogoutUseCase(repository), GetCurrentUserUseCase(repository));
    final authenticated = bloc.stream.firstWhere((state) => state == const AuthState.authenticated(original));
    bloc.add(const AuthEvent.userUpdated(original));
    await authenticated;
  });

  tearDown(() async => bloc.close());

  test('Profile refresh updates mess ID before completing without a loading state', () async {
    repository.profile = () async => const Success(data: updated);
    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);
    await bloc.refreshProfile();
    expect(bloc.state, const AuthState.authenticated(updated));
    expect(repository.requests, 1);
    expect(states, [const AuthState.authenticated(updated)]);
    await subscription.cancel();
  });

  test('Profile refresh failure is reported and keeps the existing user', () async {
    final error = StateError('Profile unavailable');
    repository.profile = () async => Result.failure(error: error);
    await expectLater(bloc.refreshProfile(), throwsA(same(error)));
    expect(bloc.state, const AuthState.authenticated(original));
  });

  test('Delayed profile response cannot restore a logged-out account', () async {
    final response = Completer<Result<UserEntity?>>();
    final requested = Completer<void>();
    repository.profile = () {
      requested.complete();
      return response.future;
    };
    final refreshing = bloc.refreshProfile();
    await requested.future;
    final loggedOut = bloc.stream.firstWhere((state) => state == const AuthState.unauthenticated());
    bloc.add(const AuthEvent.logoutRequested());
    await loggedOut;
    response.complete(const Success(data: updated));
    await refreshing;
    expect(bloc.state, const AuthState.unauthenticated());
  });
}

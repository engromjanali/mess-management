import 'package:mess_pilot/config/theme/app_theme.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/deposit/domain/entities/deposit_entity.dart';
import 'package:mess_pilot/features/deposit/domain/repositories/deposit_repository.dart';
import 'package:mess_pilot/features/deposit/domain/usecases/deposit_usecases.dart';
import 'package:mess_pilot/features/deposit/presentation/bloc/deposit_bloc.dart';
import 'package:mess_pilot/features/deposit/presentation/bloc/deposit_view_mode.dart';
import 'package:mess_pilot/features/deposit/presentation/screens/deposit_screen.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_filter_bar.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/features/splash/domain/entities/config_entity.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthBloc()
      : super(AuthState.authenticated(
          const UserEntity(id: '1', email: 'manager@example.com', name: 'Manager', activeMessId: 3, role: 'manager'),
        )) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  Future<void> refreshProfile() async {}
}

class _ThemeBloc extends Bloc<ThemeEvent, ThemeState> implements ThemeBloc {
  _ThemeBloc() : super(const ThemeState.system()) {
    on<ThemeEvent>((event, emit) {});
  }
}

class _LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> implements LocalizationBloc {
  _LocalizationBloc() : super(const LocalizationState.initial(Locale('en'))) {
    on<LocalizationEvent>((event, emit) {});
  }
}

class _SplashBloc extends Bloc<SplashEvent, SplashState> implements SplashBloc {
  _SplashBloc() : super(const SplashState.loaded(ConfigEntity(latestVersion: '1.0.0', minimumVersion: '1.0.0'))) {
    on<SplashEvent>((event, emit) {});
  }
}

class _Repo implements DepositRepository {
  static const _members = [DepositMemberEntity(id: '13', name: 'Raihan'), DepositMemberEntity(id: '14', name: 'Abir')];

  static final _deposits = [
    DepositEntity(id: '1', memberId: '13', memberName: 'Raihan', amount: 500, date: DateTime(2026, 11)),
    DepositEntity(id: '2', memberId: '14', memberName: 'Abir', amount: 1000, date: DateTime(2026, 11, 2)),
  ];

  @override
  Future<Result<List<DepositMemberEntity>>> getMembers() async => Result.success(data: _members);

  @override
  Future<Result<List<DepositEntity>>> getAllDeposits() async => Result.success(data: _deposits);

  @override
  Future<Result<List<DepositEntity>>> getMemberDeposits(String memberId) async => Result.success(data: _deposits.where((d) => d.memberId == memberId).toList());

  @override
  Future<Result<List<DepositEntity>>> getDepositsByDate(DateTime date) async => Result.success(data: _deposits);

  @override
  Future<Result<List<DepositEntity>>> getDepositsInRange(DateTime start, DateTime end) async => Result.success(data: _deposits);

  @override
  Future<Result<List<DepositEntity>>> getMyDeposits() async => Result.success(data: _deposits);

  @override
  Future<Result<DepositEntity>> addDeposit({required String memberId, required double amount, required DateTime date, String? note}) async => Result.success(data: _deposits.first);

  @override
  Future<Result<DepositEntity>> updateDeposit({required String id, required double amount, required DateTime date, String? note}) async => Result.success(data: _deposits.first);

  @override
  Future<Result<void>> deleteDeposit(String id) async => Result.success(data: null);
}

void main() {
  late _AuthBloc auth;

  setUp(() {
    final repo = _Repo();
    auth = _AuthBloc();
    getIt.registerFactory<DepositBloc>(
      () => DepositBloc(
        GetDepositMembersUseCase(repo),
        GetAllDepositsUseCase(repo),
        GetMemberDepositsUseCase(repo),
        GetDepositsByDateUseCase(repo),
        GetDepositsInRangeUseCase(repo),
        GetMyDepositsUseCase(repo),
        AddDepositUseCase(repo),
        UpdateDepositUseCase(repo),
        DeleteDepositUseCase(repo),
      ),
    );
    addTearDown(getIt.reset);
  });

  for (final width in [1000.0, 1600.0]) {
    testWidgets('breakdown tab renders with the pinned filters and footer at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final role = RoleCubit(auth);
      final theme = _ThemeBloc();
      final localization = _LocalizationBloc();
      final splash = _SplashBloc();
      addTearDown(role.close);
      addTearDown(auth.close);
      addTearDown(theme.close);
      addTearDown(localization.close);
      addTearDown(splash.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<RoleCubit>.value(value: role),
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<ThemeBloc>.value(value: theme),
            BlocProvider<LocalizationBloc>.value(value: localization),
            BlocProvider<SplashBloc>.value(value: splash),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DepositScreen(tab: DepositTab.breakdown),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'width $width');
      expect(find.byType(DepositFilterBar), findsWidgets, reason: 'width $width');
      expect(find.byType(AppFooter), findsOneWidget, reason: 'width $width');
      expect(find.text('Raihan'), findsWidgets, reason: 'width $width');
      expect(find.text('Abir'), findsWidgets, reason: 'width $width');
    });
  }

  testWidgets('filter bar scrolls horizontally on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = getIt<DepositBloc>();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<DepositBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 358,
              child: DepositFilterBar(
                mode: DepositViewMode.byMember,
                members: const [],
                selectedMember: null,
                dateFilter: DepositDateFilter.allTime,
                selectedDate: DateTime(2026, 11),
                selectedRange: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final horizontal = tester.widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView)).where((view) => view.scrollDirection == Axis.horizontal);
    expect(horizontal, isNotEmpty);
  });
}

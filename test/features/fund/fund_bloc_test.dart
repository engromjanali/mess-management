import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/features/fund/domain/entities/fund_entity.dart';
import 'package:clean_boilerplate/features/fund/domain/repositories/fund_repository.dart';
import 'package:clean_boilerplate/features/fund/domain/usecases/fund_usecases.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_bloc.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_event.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_state.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repository whose writes can be made to fail like the backend does.
class _FakeFundRepository implements FundRepository {
  _FakeFundRepository(this.funds);

  final List<FundEntity> funds;
  String? writeError;

  @override
  ResultFuture<List<FundEntity>> getAllFunds() async => Result.success(data: List.of(funds));

  @override
  ResultFuture<List<FundEntity>> getFundsByDate(DateTime date) async => Result.success(data: funds.where((f) => f.date == date).toList());

  @override
  ResultFuture<List<FundEntity>> getFundsInRange(DateTime start, DateTime end) async => Result.success(data: List.of(funds));

  @override
  ResultFuture<FundEntity> addFund({required double amount, required DateTime date, String? note}) async {
    if (writeError != null) return Result.failure(error: ServerFailure(message: writeError!, statusCode: 403));
    final fund = FundEntity(id: 'new', amount: amount, date: date, note: note);
    funds.add(fund);
    return Result.success(data: fund);
  }

  @override
  ResultFuture<FundEntity> updateFund({required String id, required double amount, required DateTime date, String? note}) async => throw UnimplementedError();

  @override
  ResultVoid deleteFund(String id) async => throw UnimplementedError();
}

void main() {
  final date = DateTime(2026, 10);

  FundBloc buildBloc(_FakeFundRepository repo) => FundBloc(
    GetAllFundsUseCase(repo),
    GetFundsByDateUseCase(repo),
    GetFundsInRangeUseCase(repo),
    AddFundUseCase(repo),
    UpdateFundUseCase(repo),
    DeleteFundUseCase(repo),
  );

  test('a failed add shows the backend message and keeps the list on screen', () async {
    final repo = _FakeFundRepository([FundEntity(id: '1', amount: 1500, date: date)])..writeError = 'Only the manager or acting manager can do this.';
    final bloc = buildBloc(repo)..add(const FundEvent.started(isAdmin: true));
    await bloc.stream.firstWhere((s) => s is FundLoaded);

    final states = <FundState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(FundEvent.add(amount: 200, date: date));
    await bloc.stream.firstWhere((s) => s is FundLoaded && !s.saving);
    await sub.cancel();

    expect(states.whereType<FundError>().single.message, 'Only the manager or acting manager can do this.');
    final last = states.last as FundLoaded;
    expect(last.funds.map((f) => f.id), ['1']);
    await bloc.close();
  });

  test('a successful add reloads the list', () async {
    final repo = _FakeFundRepository([]);
    final bloc = buildBloc(repo)..add(const FundEvent.started(isAdmin: true));
    await bloc.stream.firstWhere((s) => s is FundLoaded);

    bloc.add(FundEvent.add(amount: -300, date: date, note: 'Gas'));
    final loaded = await bloc.stream.firstWhere((s) => s is FundLoaded && s.funds.isNotEmpty) as FundLoaded;
    expect(loaded.funds.single.isDebit, isTrue);
    await bloc.close();
  });

  test('plainAmount pre-fills a value the amount field can parse back', () {
    expect(FundFormatters.plainAmount(1500), '1500');
    expect(FundFormatters.plainAmount(-1234.5), '1234.5');
    expect(FundFormatters.plainAmount(99.99), '99.99');
    expect(double.parse(FundFormatters.plainAmount(25000)), 25000);
  });

  test('a failure prints its message, not the class name', () {
    expect(const ServerFailure(message: 'Fund entry not found in the current season.').toString(), 'Fund entry not found in the current season.');
  });
}

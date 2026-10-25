import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/domain/repositories/cost_repository.dart';
import 'package:clean_boilerplate/features/cost/domain/usecases/cost_usecases.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_bloc.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_event.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_state.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repository whose calls can be made to fail like the backend does.
class _FakeCostRepository implements CostRepository {
  _FakeCostRepository(this.costs);

  final List<CostEntity> costs;
  String? membersError;
  String? writeError;

  @override
  ResultFuture<List<CostMemberEntity>> getMembers() async {
    if (membersError != null) return Result.failure(error: ServerFailure(message: membersError!, statusCode: 403));
    return Result.success(data: const [CostMemberEntity(id: '7', name: 'Alice')]);
  }

  @override
  ResultFuture<CostSeasonEntity> getCosts() async => Result.success(data: CostSeasonEntity(seasonName: 'July 2026', costs: List.of(costs)));

  @override
  ResultFuture<CostEntity> addCost({required String personId, required DateTime date, required List<CostItemEntity> items}) async {
    if (writeError != null) return Result.failure(error: ServerFailure(message: writeError!, statusCode: 400));
    final cost = CostEntity(id: 'new', personId: personId, personName: 'Alice', date: date, items: items);
    costs.add(cost);
    return Result.success(data: cost);
  }

  @override
  ResultFuture<CostEntity> updateCost({required String id, required String personId, required DateTime date, required List<CostItemEntity> items}) async => throw UnimplementedError();

  @override
  ResultVoid deleteCost(String id) async => throw UnimplementedError();
}

void main() {
  final date = DateTime(2026, 7, 2, 16, 31);
  const items = [CostItemEntity(product: 'Rice', price: 700)];

  CostBloc buildBloc(_FakeCostRepository repo) => CostBloc(GetCostMembersUseCase(repo), GetCostsUseCase(repo), AddCostUseCase(repo), UpdateCostUseCase(repo), DeleteCostUseCase(repo));

  test('loads the season name with its entries', () async {
    final repo = _FakeCostRepository([CostEntity(id: '1', personId: '7', personName: 'Alice', date: date, items: items)]);
    final bloc = buildBloc(repo)..add(const CostEvent.started(isAdmin: true));
    final loaded = await bloc.stream.firstWhere((s) => s is CostLoaded) as CostLoaded;

    expect(loaded.seasonName, 'July 2026');
    expect(loaded.costs.single.total, 700);
    expect(loaded.members.single.name, 'Alice');
    await bloc.close();
  });

  test('a failed member load shows the backend message, then the list', () async {
    final repo = _FakeCostRepository([])..membersError = 'Only the manager or acting manager can do this.';
    final bloc = buildBloc(repo);
    final states = <CostState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const CostEvent.started(isAdmin: true));
    await bloc.stream.firstWhere((s) => s is CostLoaded);
    await sub.cancel();

    expect(states.whereType<CostError>().single.message, 'Only the manager or acting manager can do this.');
    await bloc.close();
  });

  test('a failed add shows the backend message and keeps the list on screen', () async {
    final repo = _FakeCostRepository([CostEntity(id: '1', personId: '7', personName: 'Alice', date: date, items: items)])..writeError = 'Member is not part of the current season.';
    final bloc = buildBloc(repo)..add(const CostEvent.started(isAdmin: true));
    await bloc.stream.firstWhere((s) => s is CostLoaded);

    final states = <CostState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(CostEvent.add(personId: '7', date: date, items: items));
    await bloc.stream.firstWhere((s) => s is CostLoaded && !s.saving);
    await sub.cancel();

    expect(states.whereType<CostError>().single.message, 'Member is not part of the current season.');
    expect((states.last as CostLoaded).costs.map((c) => c.id), ['1']);
    await bloc.close();
  });

  test('a successful add reloads the list and flags it as saved', () async {
    final repo = _FakeCostRepository([]);
    final bloc = buildBloc(repo)..add(const CostEvent.started(isAdmin: true));
    await bloc.stream.firstWhere((s) => s is CostLoaded);

    bloc.add(CostEvent.add(personId: '7', date: date, items: items));
    final loaded = await bloc.stream.firstWhere((s) => s is CostLoaded && s.costs.isNotEmpty) as CostLoaded;
    expect(loaded.justSaved, isTrue);
    await bloc.close();
  });

  test('plainAmount pre-fills a price the form can parse back', () {
    expect(CostFormatters.plainAmount(1500), '1500');
    expect(CostFormatters.plainAmount(220.5), '220.5');
    expect(double.parse(CostFormatters.plainAmount(25000)), 25000);
  });
}

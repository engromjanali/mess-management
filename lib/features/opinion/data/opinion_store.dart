import 'package:clean_boilerplate/features/opinion/domain/entities/opinion_entity.dart';

class OpinionStore {
  OpinionStore._();

  static final OpinionStore instance = OpinionStore._();

  final List<OpinionPeriodEntity> _periods = [];
  final List<AnonymousOpinionEntity> _opinions = [];
  int _periodSequence = 1;
  int _opinionSequence = 1;

  List<OpinionPeriodEntity> periodsForMess(String messId) {
    final periods = _periods.where((period) => period.messId == messId).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
    return List<OpinionPeriodEntity>.unmodifiable(periods);
  }

  List<AnonymousOpinionEntity> opinionsForPeriod(String periodId) {
    final opinions = _opinions.where((opinion) => opinion.periodId == periodId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<AnonymousOpinionEntity>.unmodifiable(opinions);
  }

  OpinionPeriodEntity createPeriod({required String messId, required String title, required String details, required DateTime startDate, required DateTime endDate}) {
    final period = OpinionPeriodEntity(id: 'opinion-period-${_periodSequence++}', messId: messId, title: title, details: details, startDate: startDate, endDate: endDate);
    _periods.add(period);
    return period;
  }

  void setMessageSending({required String periodId, required bool enabled}) {
    final index = _periods.indexWhere((period) => period.id == periodId);
    if (index == -1) throw StateError('Opinion period not found');
    _periods[index] = _periods[index].copyWith(acceptingMessages: enabled);
  }

  void updateEndDate({required String periodId, required DateTime endDate}) {
    final index = _periods.indexWhere((period) => period.id == periodId);
    if (index == -1) throw StateError('Opinion period not found');
    if (endDate.isBefore(_periods[index].startDate)) throw ArgumentError('End date cannot be before start date');
    _periods[index] = _periods[index].copyWith(endDate: endDate);
  }

  AnonymousOpinionEntity submitOpinion({required String periodId, required String message}) {
    final index = _periods.indexWhere((period) => period.id == periodId);
    if (index == -1) throw StateError('Opinion period not found');
    final period = _periods[index];
    if (!period.isActiveAt(DateTime.now())) throw StateError('This opinion period is not accepting messages');
    final opinion = AnonymousOpinionEntity(id: 'anonymous-opinion-${_opinionSequence++}', periodId: periodId, message: message, createdAt: DateTime.now());
    _opinions.add(opinion);
    return opinion;
  }
}

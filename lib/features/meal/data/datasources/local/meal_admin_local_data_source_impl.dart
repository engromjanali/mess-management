import 'package:injectable/injectable.dart';
import '../../models/meal_admin_model.dart';
import '../interfaces/meal_admin_data_source.dart';

/// Local, in-memory mock admin meal source.
///
/// Seeds a small roster of members with a few days of records each so the
/// admin management view is fully previewable without a backend, and keeps
/// add/edit/delete mutations in memory for the session. Swap this binding for
/// a remote implementation later — the repository and presentation layers
/// won't change.
@LazySingleton(as: MealAdminDataSource)
class MealAdminLocalDataSourceImpl implements MealAdminDataSource {
  static const double _mealRate = 62.5;

  static const List<MealMemberModel> _members = [
    MealMemberModel(id: 'm1', name: 'Romjan'),
    MealMemberModel(id: 'm2', name: 'Karim'),
    MealMemberModel(id: 'm3', name: 'Sadia'),
    MealMemberModel(id: 'm4', name: 'Tanvir'),
  ];

  late final List<MemberMealModel> _entries = _seed();

  /// Deterministic recent history for every member (no randomness).
  List<MemberMealModel> _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Per-member repeating B/L/D pattern over the past few days.
    const breakfast = [1.0, 0.0, 1.0, 1.0];
    const lunch = [1.0, 1.0, 1.5, 1.0];
    const dinner = [1.0, 1.0, 1.0, 1.5];

    final result = <MemberMealModel>[];
    for (var m = 0; m < _members.length; m++) {
      for (var d = 0; d < 5; d++) {
        // d = 0 → 4 days ago, d = 4 → today.
        final date = today.subtract(Duration(days: 4 - d));
        result.add(
          MemberMealModel(
            memberId: _members[m].id,
            date: date,
            breakfast: breakfast[m],
            lunch: lunch[m],
            dinner: dinner[m],
          ),
        );
      }
    }
    return result;
  }

  int _indexOf(String memberId, DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _entries.indexWhere(
      (e) =>
          e.memberId == memberId &&
          e.date.year == key.year &&
          e.date.month == key.month &&
          e.date.day == key.day,
    );
  }

  @override
  Future<MealAdminModel> getAdminData() async {
    // Simulate IO latency so loading + refresh states are visible.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _payload();
  }

  @override
  Future<MealAdminModel> saveMemberMeal({
    required String memberId,
    required DateTime date,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    final key = DateTime(date.year, date.month, date.day);
    final index = _indexOf(memberId, key);
    final record = MemberMealModel(
      memberId: memberId,
      date: key,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
    );

    if (index == -1) {
      _entries.add(record);
    } else {
      _entries[index] = record;
    }

    return _payload();
  }

  @override
  Future<MealAdminModel> deleteMemberMeal({
    required String memberId,
    required DateTime date,
  }) async {
    final index = _indexOf(memberId, date);
    if (index != -1) _entries.removeAt(index);
    return _payload();
  }

  MealAdminModel _payload() => MealAdminModel(
        members: _members,
        mealRate: _mealRate,
        entries: List<MemberMealModel>.unmodifiable(_entries),
      );
}

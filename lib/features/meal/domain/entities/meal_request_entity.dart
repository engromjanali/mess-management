import 'package:equatable/equatable.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_member_entity.dart';

/// The meals one member selected for a meal request.
class MealSelectionEntity extends Equatable {
  const MealSelectionEntity({required this.breakfast, required this.lunch, required this.dinner});

  final double breakfast;
  final double lunch;
  final double dinner;

  double get total => breakfast + lunch + dinner;

  bool get isEmpty => total == 0;

  @override
  List<Object?> get props => [breakfast, lunch, dinner];
}

/// A meal request the manager opened for a date; members respond before [endAt].
class MealRequestEntity extends Equatable {
  const MealRequestEntity({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.endAt,
    required this.isOpen,
    required this.canRespond,
    required this.canManage,
    required this.responseCount,
    required this.eligibleMemberCount,
    required this.breakfastTotal,
    required this.lunchTotal,
    required this.dinnerTotal,
    this.mySelection,
  });

  final String id;
  final DateTime date;
  final String title;
  final String description;
  final DateTime endAt;
  final bool isOpen;
  final bool canRespond;
  final bool canManage;
  final int responseCount;
  final int eligibleMemberCount;
  final double breakfastTotal;
  final double lunchTotal;
  final double dinnerTotal;
  final MealSelectionEntity? mySelection;

  bool get hasSelection => mySelection != null && !mySelection!.isEmpty;

  @override
  List<Object?> get props => [
        id,
        date,
        title,
        description,
        endAt,
        isOpen,
        canRespond,
        canManage,
        responseCount,
        eligibleMemberCount,
        breakfastTotal,
        lunchTotal,
        dinnerTotal,
        mySelection,
      ];
}

class MealRequestOverviewEntity extends Equatable {
  const MealRequestOverviewEntity({required this.requests, required this.canManage});

  final List<MealRequestEntity> requests;
  final bool canManage;

  @override
  List<Object?> get props => [requests, canManage];
}

/// Values needed to create a meal request.
class MealRequestDraft extends Equatable {
  const MealRequestDraft({required this.date, required this.title, required this.description, required this.endAt});

  final DateTime date;
  final String title;
  final String description;
  final DateTime endAt;

  @override
  List<Object?> get props => [date, title, description, endAt];
}

/// Legacy payload used when reviewing meal requests as meal entries.
class MealRequestApplyDraft extends Equatable {
  const MealRequestApplyDraft({required this.date, required this.requestIds, required this.meals});

  final DateTime date;
  final List<String> requestIds;
  final List<MemberMealEntity> meals;

  @override
  List<Object?> get props => [date, requestIds, meals];
}

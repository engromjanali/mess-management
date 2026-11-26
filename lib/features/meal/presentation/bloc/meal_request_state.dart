import 'package:equatable/equatable.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';

sealed class MealRequestState extends Equatable {
  const MealRequestState();
}

final class MealRequestInitial extends MealRequestState {
  const MealRequestInitial();

  @override
  List<Object?> get props => [];
}

final class MealRequestLoading extends MealRequestState {
  const MealRequestLoading();

  @override
  List<Object?> get props => [];
}

final class MealRequestLoaded extends MealRequestState {
  const MealRequestLoaded({required this.overview, this.busy = false});

  final MealRequestOverviewEntity overview;
  final bool busy;

  @override
  List<Object?> get props => [overview, busy];
}

final class MealRequestError extends MealRequestState {
  const MealRequestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

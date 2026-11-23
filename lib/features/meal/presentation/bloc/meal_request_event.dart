import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';

sealed class MealRequestEvent extends Equatable {
  const MealRequestEvent();
}

final class MealRequestLoad extends MealRequestEvent {
  const MealRequestLoad();

  @override
  List<Object?> get props => [];
}

final class MealRequestCreate extends MealRequestEvent {
  const MealRequestCreate({required this.draft, this.done});

  final MealRequestDraft draft;
  final Completer<Failure?>? done;

  @override
  List<Object?> get props => [draft, done];
}

final class MealRequestUpdate extends MealRequestEvent {
  const MealRequestUpdate({required this.id, required this.draft, this.done});

  final String id;
  final MealRequestDraft draft;
  final Completer<Failure?>? done;

  @override
  List<Object?> get props => [id, draft, done];
}

final class MealRequestDelete extends MealRequestEvent {
  const MealRequestDelete({required this.id, this.done});

  final String id;
  final Completer<Failure?>? done;

  @override
  List<Object?> get props => [id, done];
}

final class MealRequestSelect extends MealRequestEvent {
  const MealRequestSelect({required this.id, required this.breakfast, required this.lunch, required this.dinner, this.done});

  final String id;
  final double breakfast;
  final double lunch;
  final double dinner;
  final Completer<Failure?>? done;

  @override
  List<Object?> get props => [id, breakfast, lunch, dinner, done];
}

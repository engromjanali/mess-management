import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_date_filter.dart';

part 'fund_event.freezed.dart';

/// Fund events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class FundEvent with _$FundEvent {
  /// Initial load. [isAdmin] decides whether add / edit / delete are available.
  const factory FundEvent.started({required bool isAdmin}) = FundStarted;

  /// Switch the date scope (e.g. to "all time").
  const factory FundEvent.changeDateFilter(FundDateFilter filter) =
      FundChangeDateFilter;

  /// Show fund entries on a single [date] (day scope).
  const factory FundEvent.selectDate(DateTime date) = FundSelectDate;

  /// Show fund entries within an inclusive range (range scope).
  const factory FundEvent.selectRange({
    required DateTime start,
    required DateTime end,
  }) = FundSelectRange;

  /// Record a fund entry. [amount] is signed
  /// (positive → credit, negative → debit).
  const factory FundEvent.add({
    required double amount,
    required DateTime date,
    String? note,
  }) = FundAdd;

  /// Edit an existing fund entry.
  const factory FundEvent.update({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  }) = FundUpdate;

  /// Remove a fund entry.
  const factory FundEvent.delete(String id) = FundDelete;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'deposit_view_mode.dart';

part 'deposit_event.freezed.dart';

/// Deposit events. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class DepositEvent with _$DepositEvent {
  /// Initial load. [isAdmin] decides whether admin filters are available;
  /// non-admins are locked to their own deposits.
  const factory DepositEvent.started({required bool isAdmin}) = DepositStarted;

  /// Switch the active filter mode (admin only).
  const factory DepositEvent.changeMode(DepositViewMode mode) =
      DepositChangeMode;

  /// Show deposits for [memberId] (switches to by-member mode). A null
  /// [memberId] means "all members".
  const factory DepositEvent.selectMember(String? memberId) =
      DepositSelectMember;

  /// Switch the by-date scope (e.g. to "all time").
  const factory DepositEvent.changeDateFilter(DepositDateFilter filter) =
      DepositChangeDateFilter;

  /// Show every member's deposits on a single [date] (by-date / day scope).
  const factory DepositEvent.selectDate(DateTime date) = DepositSelectDate;

  /// Show every member's deposits within an inclusive range (by-date / range).
  const factory DepositEvent.selectRange({
    required DateTime start,
    required DateTime end,
  }) = DepositSelectRange;

  /// Record a deposit for one member. [amount] is signed
  /// (positive → credit, negative → debit).
  const factory DepositEvent.add({
    required String memberId,
    required double amount,
    required DateTime date,
    String? note,
  }) = DepositAdd;

  /// Edit an existing deposit.
  const factory DepositEvent.update({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  }) = DepositUpdate;

  /// Remove a deposit.
  const factory DepositEvent.delete(String id) = DepositDelete;
}

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/deposit_entity.dart';
import 'deposit_view_mode.dart';

part 'deposit_state.freezed.dart';

/// Deposit states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class DepositState with _$DepositState {
  /// Before the first load.
  const factory DepositState.initial() = DepositInitial;

  /// The list is loading for the first time.
  const factory DepositState.loading() = DepositLoading;

  /// Deposits loaded (or just mutated).
  ///
  /// [mode] is the active filter; [selectedMember] / [selectedDate] describe
  /// what that filter currently points at. [members] backs the add/edit picker
  /// and the by-member filter (empty for non-admins). [saving] flags an
  /// in-flight add/update/delete so the UI can show subtle progress.
  const factory DepositState.loaded({
    required DepositViewMode mode,
    required List<DepositEntity> deposits,
    required List<DepositMemberEntity> members,
    required DepositDateFilter dateFilter,
    required DateTime selectedDate,
    required bool isAdmin,
    DepositMemberEntity? selectedMember,
    DateTimeRange? selectedRange,
    @Default(false) bool saving,
  }) = DepositLoaded;

  /// Loading failed.
  const factory DepositState.error(String message) = DepositError;
}

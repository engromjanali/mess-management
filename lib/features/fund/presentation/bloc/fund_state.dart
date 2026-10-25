import 'package:flutter/material.dart' show DateTimeRange;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:clean_boilerplate/features/fund/domain/entities/fund_entity.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_date_filter.dart';

part 'fund_state.freezed.dart';

/// Fund states. Runtime-only, so no JSON serialization.
@Freezed(toJson: false, fromJson: false)
class FundState with _$FundState {
  /// Before the first load.
  const factory FundState.initial() = FundInitial;

  /// The list is loading for the first time.
  const factory FundState.loading() = FundLoading;

  /// Funds loaded (or just mutated).
  ///
  /// [dateFilter] is the active scope; [selectedDate] / [selectedRange]
  /// describe what that scope points at. [isAdmin] gates add / edit / delete.
  /// [saving] flags an in-flight mutation so the UI can show subtle progress.
  const factory FundState.loaded({
    required List<FundEntity> funds,
    required FundDateFilter dateFilter,
    required DateTime selectedDate,
    required bool isAdmin,
    DateTimeRange? selectedRange,
    @Default(false) bool saving,
  }) = FundLoaded;

  /// Loading failed.
  const factory FundState.error(String message) = FundError;
}

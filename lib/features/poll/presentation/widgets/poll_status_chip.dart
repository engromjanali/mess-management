import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

/// Tinted status pill: Open / Closed / Cancelled.
class PollStatusChip extends StatelessWidget {
  const PollStatusChip({required this.status, super.key});

  final PollStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final (label, color) = switch (status) {
      PollStatus.open => (context.local.uiOpen, colors.successColor),
      PollStatus.closed => (context.local.uiClosed, colors.textSecondaryColor),
      PollStatus.cancelled => (context.local.pollCancelled, colors.errorColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color),
      ),
    );
  }
}

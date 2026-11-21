import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

/// Vote counts and percentages, or the reason results are hidden yet.
class PollResultsView extends StatelessWidget {
  const PollResultsView({required this.poll, this.dense = false, super.key});

  final PollEntity poll;

  /// Compact layout for the list card.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    if (!poll.resultsVisible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_off_outlined, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                poll.resultsVisibility == PollResultsVisibility.afterClose ? context.local.pollResultsHiddenUntilClose : context.local.pollResultsHidden,
                style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
              ),
            ),
          ],
        ),
      );
    }

    final totalSelections = poll.options.fold<int>(0, (sum, option) => sum + (option.voteCount ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < poll.options.length; index++) ...[
          if (index > 0) SizedBox(height: dense ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeDefault),
          _ResultRow(
            option: poll.options[index],
            totalSelections: totalSelections,
            selected: poll.myOptionIds.contains(poll.options[index].id),
            dense: dense,
          ),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.option, required this.totalSelections, required this.selected, required this.dense});

  final PollOptionEntity option;
  final int totalSelections;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final count = option.voteCount ?? 0;
    final ratio = totalSelections == 0 ? 0.0 : count / totalSelections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (selected) ...[
              Icon(Icons.check_circle_rounded, size: Dimensions.iconSizeSmall, color: colors.successColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ],
            Expanded(
              child: Text(
                option.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                  fontSize: dense ? Dimensions.fontSizeSmall : Dimensions.fontSizeDefault,
                  color: colors.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              '${(ratio * 100).round()}% · ${context.local.pollVotesCount(count)}',
              style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textSecondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: dense ? 5 : 7,
            backgroundColor: colors.primaryColor.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation(selected ? colors.successColor : colors.primaryColor),
          ),
        ),
      ],
    );
  }
}

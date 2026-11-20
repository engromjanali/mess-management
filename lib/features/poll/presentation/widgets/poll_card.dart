import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_formatters.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_results_view.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_status_chip.dart';

enum _PollAction { edit, toggleClosed, delete }

/// One poll in the list: date, question, status, participation and — for a
/// manager — edit / close / delete actions.
class PollCard extends StatelessWidget {
  const PollCard({
    required this.poll,
    required this.onTap,
    this.onEdit,
    this.onToggleClosed,
    this.onDelete,
    this.showResults = true,
    super.key,
  });

  final PollEntity poll;
  final VoidCallback onTap;

  /// Null callbacks disable their menu entry (e.g. while another action runs).
  final ValueChanged<PollEntity>? onEdit;
  final ValueChanged<PollEntity>? onToggleClosed;
  final ValueChanged<PollEntity>? onDelete;
  final bool showResults;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final canManage = poll.canManage && (onEdit != null || onToggleClosed != null || onDelete != null);
    final compact = ResponsiveHelper.isMobile(context) || ResponsiveHelper.isSmallTab(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.22 : 0.10),
                colors.secondaryColor.withValues(alpha: context.isDarkMode ? 0.14 : 0.06),
              ],
            ),
            border: Border.all(color: colors.primaryColor.withValues(alpha: poll.isOpen ? 0.45 : 0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    child: Icon(Icons.poll_outlined, size: compact ? Dimensions.iconSizeSmall : Dimensions.iconSizeDefault, color: colors.primaryColor),
                  ),
                  SizedBox(width: compact ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      poll.title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedBold.copyWith(
                        fontSize: compact ? Dimensions.fontSizeLarge : Dimensions.fontSizeExtraLarge,
                        color: colors.textPrimaryColor,
                      ),
                    ),
                  ),
                  if (canManage)
                    PopupMenuButton<_PollAction>(
                      tooltip: context.local.pollManage,
                      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
                      iconSize: compact ? 20 : 24,
                      icon: Icon(Icons.more_vert_rounded, color: colors.textSecondaryColor),
                      onSelected: (action) => switch (action) {
                        _PollAction.edit => onEdit?.call(poll),
                        _PollAction.toggleClosed => onToggleClosed?.call(poll),
                        _PollAction.delete => onDelete?.call(poll),
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _PollAction.edit,
                          enabled: onEdit != null && !poll.isPast && poll.status != PollStatus.cancelled,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(context.local.editPoll),
                          ),
                        ),
                        PopupMenuItem(
                          value: _PollAction.toggleClosed,
                          enabled: onToggleClosed != null && poll.status != PollStatus.cancelled,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(poll.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
                            title: Text(poll.isOpen ? context.local.pollClose : context.local.pollReopen),
                          ),
                        ),
                        PopupMenuItem(
                          value: _PollAction.delete,
                          enabled: onDelete != null,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline_rounded, color: colors.errorColor),
                            title: Text(poll.hasVotes ? context.local.pollCancel : context.local.delete, style: TextStyle(color: colors.errorColor)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: compact ? Dimensions.paddingSizeExtraSmall : Dimensions.paddingSizeSmall),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeExtraSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InfoChip(icon: Icons.event_outlined, label: PollFormatters.relativeDay(context.local, poll.pollDate), compact: compact),
                  PollStatusChip(status: poll.status),
                  if (poll.hasVoted) _InfoChip(icon: Icons.how_to_vote_rounded, label: context.local.voted, compact: compact),
                  if (!compact && poll.isAnonymous) _InfoChip(icon: Icons.visibility_off_outlined, label: context.local.pollAnonymousShort),
                ],
              ),
              if (!compact && poll.description.trim().isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  poll.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor, height: 1.4),
                ),
              ],
              if (compact) ...[
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                _CompactSummary(poll: poll, showResults: showResults),
              ] else ...[
                const SizedBox(height: Dimensions.paddingSizeDefault),
                if (showResults && poll.resultsVisible)
                  PollResultsView(poll: poll, dense: true)
                else
                  _OptionPreview(poll: poll),
              ],
              SizedBox(height: compact ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeDefault),
              Row(
                children: [
                  Icon(Icons.groups_2_outlined, size: compact ? Dimensions.fontSizeDefault : Dimensions.iconSizeSmall, color: colors.textHintColor),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: Text(
                      PollFormatters.participation(context.local, poll.totalVotes, poll.eligibleMemberCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
                    ),
                  ),
                  if (poll.isOpen && poll.canVote && !poll.hasVoted)
                    Text(
                      context.local.vote,
                      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.primaryColor),
                    ),
                  Icon(Icons.chevron_right_rounded, size: compact ? 18 : 24, color: colors.textHintColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-line peek at the top results (or the options) for the phone card.
class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.poll, required this.showResults});

  final PollEntity poll;
  final bool showResults;

  @override
  Widget build(BuildContext context) {
    final options = poll.options;
    if (options.isEmpty) return const SizedBox.shrink();

    final showCounts = showResults && poll.resultsVisible && options.any((option) => option.voteCount != null);
    final String text;
    if (showCounts) {
      final totalSelections = options.fold<int>(0, (sum, option) => sum + (option.voteCount ?? 0));
      final ranked = [...options]..sort((a, b) => (b.voteCount ?? 0).compareTo(a.voteCount ?? 0));
      text = ranked
          .take(2)
          .map((option) {
            final percentage = totalSelections == 0 ? 0 : ((option.voteCount ?? 0) / totalSelections * 100).round();
            return '${option.text} $percentage%';
          })
          .join(' · ');
    } else {
      final preview = options.take(2).map((option) => option.text).join(' · ');
      text = options.length > 2 ? '$preview  +${options.length - 2}' : preview;
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: context.customThemeColors.textSecondaryColor),
    );
  }
}

class _OptionPreview extends StatelessWidget {
  const _OptionPreview({required this.poll});

  final PollEntity poll;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final preview = poll.options.take(3).toList();
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeExtraSmall,
      children: [
        for (final option in preview)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.7)),
            ),
            child: Text(
              option.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textSecondaryColor),
            ),
          ),
        if (poll.options.length > preview.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '+${poll.options.length - preview.length}',
              style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textHintColor),
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.compact = false});

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? Dimensions.fontSizeSmall : Dimensions.fontSizeDefault, color: colors.textHintColor),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Text(label, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textHintColor)),
      ],
    );
  }
}

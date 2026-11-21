import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_bloc.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_event.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_state.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_form_sheet.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_formatters.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_status_chip.dart';

/// Compact poll list for the meal screens. With a [date] it shows that day's
/// polls (the meal-entry view); without one it shows the nearest open polls.
/// Managers can create a poll here, pre-filled with [date].
class MealPollSection extends StatelessWidget {
  const MealPollSection({this.date, super.key});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollBloc>(
      create: (_) => getIt<PollBloc>()..add(const PollEvent.started()),
      child: _MealPollView(date: date),
    );
  }
}

class _MealPollView extends StatelessWidget {
  const _MealPollView({this.date});

  final DateTime? date;

  Future<void> _refresh(BuildContext context) async {
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.refresh(done: done));
    final failure = await done.future;
    if (failure != null && context.mounted) context.showErrorSnackBar(failure);
  }

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<PollBloc>();
    final saved = await showPollFormSheet(
      context: context,
      initialDate: date ?? DateTime.now(),
      onSubmit: (draft) {
        final done = Completer<Failure?>();
        bloc.add(PollEvent.create(draft: draft, done: done));
        return done.future;
      },
    );
    if ((saved ?? false) && context.mounted) context.showSuccessSnackBar(context.local.pollCreated);
  }

  Future<void> _open(BuildContext context, PollEntity poll) async {
    await context.push(AppRoutes.getPollDetailsRoute(poll.id), extra: poll);
    if (context.mounted) await _refresh(context);
  }

  Future<void> _viewAll(BuildContext context) async {
    await context.push(AppRoutes.polls);
    if (context.mounted) await _refresh(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.7)),
      ),
      child: BlocBuilder<PollBloc, PollState>(
        builder: (context, state) => state.maybeWhen(
          error: (message) => Row(
            children: [
              Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeSmall, color: colors.errorColor),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Text(message, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.errorColor))),
              TextButton(onPressed: () => context.read<PollBloc>().add(const PollEvent.started()), child: Text(context.local.tryAgain)),
            ],
          ),
          loaded: (polls, canManage, busy) {
            final selected = date;
            final visible = polls.where((poll) => selected == null ? poll.isOpen : poll.isSameDay(selected)).take(5).toList();
            return _loaded(context, visible, canManage, busy, polls.isNotEmpty);
          },
          orElse: () => const SizedBox(height: 56, child: Center(child: AppLoader(size: 22))),
        ),
      ),
    );
  }

  Widget _loaded(BuildContext context, List<PollEntity> polls, bool canManage, bool busy, bool hasAnyPolls) {
    final colors = context.customThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.poll_outlined, size: Dimensions.iconSizeDefault, color: colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                context.local.pollMealSection,
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
              ),
            ),
          ],
        ),
        if (polls.isEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            date == null ? context.local.pollNoOpen : context.local.pollNoneForDate,
            style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
          ),
        ] else ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          for (var index = 0; index < polls.length; index++) ...[
            if (index > 0) const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            _MiniPollTile(poll: polls[index], busy: busy, onTap: () => _open(context, polls[index])),
          ],
        ],
        if (canManage || hasAnyPolls) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeExtraSmall,
            children: [
              if (canManage)
                TextButton.icon(
                  onPressed: busy ? null : () => _create(context),
                  icon: const Icon(Icons.add_rounded, size: Dimensions.iconSizeSmall),
                  label: Text(context.local.pollNew),
                ),
              if (hasAnyPolls)
                TextButton.icon(
                  onPressed: busy ? null : () => _viewAll(context),
                  icon: const Icon(Icons.arrow_circle_right_outlined, size: Dimensions.iconSizeSmall),
                  label: Text(context.local.pollViewAll),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniPollTile extends StatelessWidget {
  const _MiniPollTile({required this.poll, required this.busy, required this.onTap});

  final PollEntity poll;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PollFormatters.participation(context.local, poll.totalVotes, poll.eligibleMemberCount),
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textHintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              PollStatusChip(status: poll.status),
              if (poll.hasVoted) ...[
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Icon(Icons.check_circle_rounded, size: Dimensions.iconSizeSmall, color: colors.successColor),
              ],
              Icon(Icons.chevron_right_rounded, color: colors.textHintColor),
            ],
          ),
        ),
      ),
    );
  }
}

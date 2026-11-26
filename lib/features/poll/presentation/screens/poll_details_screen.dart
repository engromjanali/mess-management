import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/extensions/screen_matres_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_dialog.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_bloc.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_event.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_state.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_form_sheet.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_formatters.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_results_view.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_status_chip.dart';

/// One poll: vote or change your answer and see results / manager actions.
class PollDetailsScreen extends StatelessWidget {
  const PollDetailsScreen({required this.pollId, super.key});

  final String pollId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollBloc>(
      create: (_) => getIt<PollBloc>()..add(const PollEvent.started()),
      child: _PollDetailsView(pollId: pollId),
    );
  }
}

class _PollDetailsView extends StatelessWidget {
  const _PollDetailsView({required this.pollId});

  final String pollId;

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final content = BlocBuilder<PollBloc, PollState>(
      builder: (context, state) => state.maybeWhen(
        error: (message) => AppErrorState(error: message, onRetry: () => context.read<PollBloc>().add(const PollEvent.started())),
        loaded: (polls, _, busy) {
          final poll = polls.where((item) => item.id == pollId).firstOrNull;
          if (poll == null) {
            return AppEmptyState(title: context.local.pollNoPolls, message: context.local.pollNoPollsSubtitle, icon: Icons.poll_outlined);
          }
          return _PollDetailBody(poll: poll, busy: busy);
        },
        orElse: () => const Center(child: AppLoader()),
      ),
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.pollDetails)),
      body: Column(
        children: [
          // Single fixed-type slot so crossing the responsive breakpoint never
          // remounts the content subtree (unsaved vote selections).
          showWebAppBar
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DashboardTopBar(),
                    WebPageTitleBar(title: context.local.pollDetails),
                  ],
                )
              : const SizedBox.shrink(),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _PollDetailBody extends StatefulWidget {
  const _PollDetailBody({required this.poll, required this.busy});

  final PollEntity poll;
  final bool busy;

  @override
  State<_PollDetailBody> createState() => _PollDetailBodyState();
}

class _PollDetailBodyState extends State<_PollDetailBody> {
  late Set<String> _selection = widget.poll.myOptionIds.toSet();

  @override
  void didUpdateWidget(covariant _PollDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.poll;
    final current = widget.poll;
    if (previous.id != current.id ||
        previous.status != current.status ||
        previous.myOptionIds.length != current.myOptionIds.length ||
        !previous.myOptionIds.every(current.myOptionIds.contains)) {
      _selection = current.myOptionIds.toSet();
    }
  }

  PollEntity get _poll => widget.poll;

  void _toggle(PollOptionEntity option) {
    if (!_poll.isOpen || !_poll.canVote) return;
    if (!_poll.allowMultiple) {
      setState(() => _selection = {option.id});
      return;
    }
    if (!_selection.contains(option.id) && _selection.length >= _poll.maxChoices) {
      context.showErrorSnackBar(context.local.pollTooMany(_poll.maxChoices));
      return;
    }
    setState(() {
      if (!_selection.remove(option.id)) _selection.add(option.id);
    });
  }

  Future<void> _report(Future<Failure?> outcome, String success) async {
    final failure = await outcome;
    if (!mounted) return;
    if (failure == null) {
      context.showSuccessSnackBar(success);
    } else {
      context.showErrorSnackBar(failure);
    }
  }

  Future<void> _saveVote() async {
    if (_selection.isEmpty) {
      context.showErrorSnackBar(context.local.pollSelectFirst);
      return;
    }
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.vote(id: _poll.id, optionIds: _selection.toList(), done: done));
    await _report(done.future, context.local.pollVoteSaved);
  }

  Future<void> _withdrawVote() async {
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.withdrawVote(id: _poll.id, done: done));
    await _report(done.future, context.local.pollVoteWithdrawn);
  }

  Future<void> _edit() async {
    final bloc = context.read<PollBloc>();
    final saved = await showPollFormSheet(
      context: context,
      existing: _poll,
      onSubmit: (draft) {
        final done = Completer<Failure?>();
        bloc.add(PollEvent.update(id: _poll.id, draft: draft, updateOptions: _poll.canEditOptions, done: done));
        return done.future;
      },
    );
    if ((saved ?? false) && mounted) context.showSuccessSnackBar(context.local.pollUpdated);
  }

  Future<void> _toggleClosed() async {
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.toggleClosed(id: _poll.id, closed: _poll.isOpen, done: done));
    await _report(done.future, _poll.isOpen ? context.local.pollClosedMessage : context.local.pollReopened);
  }

  Future<void> _delete() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: _poll.hasVotes ? context.local.pollCancel : context.local.delete,
      message: _poll.hasVotes ? context.local.pollCancelConfirm : context.local.pollDeleteConfirm,
      confirmLabel: _poll.hasVotes ? context.local.pollCancel : context.local.delete,
      icon: _poll.hasVotes ? Icons.cancel_outlined : Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.delete(id: _poll.id, done: done));
    final failure = await done.future;
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).maybePop();
    } else {
      context.showErrorSnackBar(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final changed = _selection.length != _poll.myOptionIds.length || !_selection.every(_poll.myOptionIds.contains);

    return Stack(
      children: [
        AppPageScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          maxWidth: 760,
          children: [
            _SummaryCard(poll: _poll),
            if (_poll.status == PollStatus.cancelled) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _Banner(icon: Icons.cancel_outlined, color: colors.errorColor, message: context.local.pollCancelledMessage),
            ],
            const SizedBox(height: Dimensions.paddingSizeLarge),

            if (_poll.isOpen) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _poll.allowMultiple ? context.local.pollSelectUpTo(_poll.maxChoices) : context.local.pollSelectOne,
                      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
                    ),
                  ),
                  if (_poll.hasVoted)
                    Text(context.local.voted, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.successColor)),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              for (final option in _poll.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: _OptionTile(
                    option: option,
                    selected: _selection.contains(option.id),
                    enabled: _poll.canVote && !widget.busy,
                    multiple: _poll.allowMultiple,
                    showCount: _poll.resultsVisible,
                    onTap: () => _toggle(option),
                  ),
                ),
              if (_poll.canVote) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.busy || !changed ? null : _saveVote,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                        icon: const Icon(Icons.how_to_vote_rounded),
                        label: Text(_poll.hasVoted ? context.local.pollChangeVote : context.local.vote),
                      ),
                    ),
                    if (_poll.hasVoted) ...[
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.busy ? null : _withdrawVote,
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                          child: Text(context.local.pollWithdrawVote),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],

            if (_poll.resultsVisible) ...[
              Text(
                context.local.pollResults,
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              PollResultsView(poll: _poll),
            ] else
              PollResultsView(poll: _poll),

            if (_poll.canManage) ...[
              const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              Text(
                context.local.pollManage,
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeSmall,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.busy || _poll.isPast || _poll.status == PollStatus.cancelled ? null : _edit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.local.editPoll),
                  ),
                  if (_poll.status != PollStatus.cancelled)
                    OutlinedButton.icon(
                      onPressed: widget.busy ? null : _toggleClosed,
                      icon: Icon(_poll.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
                      label: Text(_poll.isOpen ? context.local.pollClose : context.local.pollReopen),
                    ),
                  OutlinedButton.icon(
                    onPressed: widget.busy ? null : _delete,
                    style: OutlinedButton.styleFrom(foregroundColor: colors.errorColor),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(_poll.hasVotes ? context.local.pollCancel : context.local.delete),
                  ),
                ],
              ),
            ],
            SizedBox(height: context.bottomPadding + Dimensions.paddingSizeLarge),
          ],
        ),
        if (widget.busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.poll});

  final PollEntity poll;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.24 : 0.12),
            colors.secondaryColor.withValues(alpha: context.isDarkMode ? 0.16 : 0.06),
          ],
        ),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeExtraSmall,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PollStatusChip(status: poll.status),
              Icon(Icons.event_outlined, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
              Text(
                PollFormatters.relativeDay(context.local, poll.pollDate),
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
              ),
              if (poll.isAnonymous)
                Text(
                  '· ${context.local.pollAnonymousShort}',
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
                ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(poll.title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: colors.textPrimaryColor)),
          if (poll.description.trim().isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              poll.description,
              style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor, height: 1.5),
            ),
          ],
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            child: LinearProgressIndicator(
              value: poll.participation,
              minHeight: 7,
              backgroundColor: colors.primaryColor.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Expanded(
                child: Text(
                  PollFormatters.participation(context.local, poll.totalVotes, poll.eligibleMemberCount),
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                ),
              ),
              Flexible(
                child: Text(
                  PollFormatters.deadline(poll.closesAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.multiple,
    required this.showCount,
    required this.onTap,
  });

  final PollOptionEntity option;
  final bool selected;
  final bool enabled;
  final bool multiple;
  final bool showCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final accent = selected ? colors.primaryColor : colors.borderColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: selected ? colors.primaryColor.withValues(alpha: 0.10) : colors.cardBackgroundColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: accent, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Icon(
                multiple
                    ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                    : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
                color: selected ? colors.primaryColor : colors.textHintColor,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  option.text,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: enabled ? colors.textPrimaryColor : colors.textHintColor),
                ),
              ),
              if (showCount && option.voteCount != null)
                Text(
                  context.local.pollVotesCount(option.voteCount!),
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.message});

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: Dimensions.iconSizeSmall),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(message, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: color)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
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
import 'package:mess_pilot/core/widgets/pill_tab_bar.dart';
import 'package:mess_pilot/core/widgets/segmented_tab_bar.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/animated_entrance.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_bloc.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_event.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_state.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_card.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_form_sheet.dart';

enum PollPageTab { open, past, create }

/// Polls for the current season. Members vote; managers also create, edit,
/// close and cancel polls.
class PollScreen extends StatelessWidget {
  const PollScreen({this.tab = PollPageTab.open, super.key});

  final PollPageTab tab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollBloc>(
      create: (_) => getIt<PollBloc>()..add(const PollEvent.started()),
      child: _PollView(tab: tab),
    );
  }
}

class _PollView extends StatelessWidget {
  const _PollView({required this.tab});

  final PollPageTab tab;

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final content = BlocBuilder<PollBloc, PollState>(
      builder: (context, state) => state.maybeWhen(
        error: (message) => AppErrorState(error: message, onRetry: () => context.read<PollBloc>().add(const PollEvent.started())),
        loaded: (polls, canManage, busy) => _PollContent(tab: tab, polls: polls, canManage: canManage, busy: busy),
        orElse: () => const Center(child: AppLoader()),
      ),
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.pollPolls)),
      body: showWebAppBar
          ? Column(
              children: [
                const DashboardTopBar(),
                WebPageTitleBar(title: context.local.pollPolls),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

}

class _PollContent extends StatelessWidget {
  const _PollContent({required this.tab, required this.polls, required this.canManage, required this.busy});

  final PollPageTab tab;
  final List<PollEntity> polls;
  final bool canManage;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final openCount = polls.where((poll) => poll.isOpen).length;
    final pastCount = polls.where((poll) => poll.isPast).length;
    final selected = canManage || tab != PollPageTab.create ? tab : PollPageTab.open;

    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
              child: SegmentedTabBar<PollPageTab>(
                tabs: [
                  PillTab(value: PollPageTab.open, label: '${context.local.uiOpen} ($openCount)'),
                  PillTab(value: PollPageTab.past, label: '${context.local.pollPast} ($pastCount)'),
                  if (canManage) PillTab(value: PollPageTab.create, label: context.local.pollNew),
                ],
                selected: selected,
                onChanged: (value) => context.go(switch (value) {
                  PollPageTab.open => AppRoutes.pollsOpen,
                  PollPageTab.past => AppRoutes.pollsPast,
                  PollPageTab.create => AppRoutes.createPoll,
                }),
              ),
            ),
          ),
        ),
        Expanded(
          child: tab == PollPageTab.create
              ? canManage
                  ? const _PollCreateTab()
                  : const _PollCreateDenied()
              : _PollBody(tab: tab, polls: polls, canManage: canManage, busy: busy),
        ),
      ],
    );
  }
}

class _PollCreateTab extends StatelessWidget {
  const _PollCreateTab();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PollBloc>();
    return PollForm(
      initialDate: DateTime.now(),
      embedded: true,
      onSubmit: (draft) {
        final done = Completer<Failure?>();
        bloc.add(PollEvent.create(draft: draft, done: done));
        return done.future;
      },
      onSaved: () {
        context.showSuccessSnackBar(context.local.pollCreated);
        context.go(AppRoutes.pollsOpen);
      },
    );
  }
}

class _PollCreateDenied extends StatelessWidget {
  const _PollCreateDenied();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: AppEmptyState(title: context.local.actionNotAllowed, message: context.local.pollSubtitle, icon: Icons.lock_outline_rounded),
    );
  }
}

class _PollBody extends StatefulWidget {
  const _PollBody({required this.tab, required this.polls, required this.canManage, required this.busy});

  final PollPageTab tab;
  final List<PollEntity> polls;
  final bool canManage;
  final bool busy;

  @override
  State<_PollBody> createState() => _PollBodyState();
}

class _PollBodyState extends State<_PollBody> {
  List<PollEntity> get _visible => widget.tab == PollPageTab.open ? widget.polls.where((poll) => poll.isOpen).toList() : widget.polls.where((poll) => poll.isPast).toList();

  Future<void> _refresh() async {
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.refresh(done: done));
    final failure = await done.future;
    if (failure != null && mounted) context.showErrorSnackBar(failure);
  }

  Future<void> _open(PollEntity poll) async {
    await context.push<bool>(AppRoutes.getPollDetailsRoute(poll.id), extra: poll);
    if (mounted) await _refresh();
  }

  Future<void> _openEdit(PollEntity poll) async {
    final bloc = context.read<PollBloc>();
    final saved = await showPollFormSheet(
      context: context,
      existing: poll,
      onSubmit: (draft) {
        final done = Completer<Failure?>();
        bloc.add(PollEvent.update(id: poll.id, draft: draft, updateOptions: poll.canEditOptions, done: done));
        return done.future;
      },
    );
    if ((saved ?? false) && mounted) context.showSuccessSnackBar(context.local.pollUpdated);
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

  Future<void> _toggleClosed(PollEntity poll) async {
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.toggleClosed(id: poll.id, closed: poll.isOpen, done: done));
    await _report(done.future, poll.isOpen ? context.local.pollClosedMessage : context.local.pollReopened);
  }

  Future<void> _delete(PollEntity poll) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: poll.hasVotes ? context.local.pollCancel : context.local.delete,
      message: poll.hasVotes ? context.local.pollCancelConfirm : context.local.pollDeleteConfirm,
      confirmLabel: poll.hasVotes ? context.local.pollCancel : context.local.delete,
      icon: poll.hasVotes ? Icons.cancel_outlined : Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final done = Completer<Failure?>();
    context.read<PollBloc>().add(PollEvent.delete(id: poll.id, done: done));
    await _report(done.future, poll.hasVotes ? context.local.pollCancelledMessage : context.local.pollDeleted);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: AppPageScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            maxWidth: Dimensions.webMaxWidth,
            children: [
              if (_visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraLarge32),
                  child: AppEmptyState(
                    title: widget.tab == PollPageTab.open ? context.local.pollNoOpen : context.local.pollNoPast,
                    message: widget.tab == PollPageTab.open ? context.local.pollNoPollsSubtitle : context.local.pollNoPolls,
                    icon: Icons.poll_outlined,
                  ),
                )
              else
                _PollGrid(
                  polls: _visible,
                  canManage: widget.canManage,
                  busy: widget.busy,
                  onTap: _open,
                  onEdit: _openEdit,
                  onToggleClosed: _toggleClosed,
                  onDelete: _delete,
                ),
              SizedBox(height: context.bottomPadding + 72),
            ],
          ),
        ),
        if (widget.busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

class _PollGrid extends StatelessWidget {
  const _PollGrid({
    required this.polls,
    required this.canManage,
    required this.busy,
    required this.onTap,
    required this.onEdit,
    required this.onToggleClosed,
    required this.onDelete,
  });

  final List<PollEntity> polls;
  final bool canManage;
  final bool busy;
  final ValueChanged<PollEntity> onTap;
  final ValueChanged<PollEntity> onEdit;
  final ValueChanged<PollEntity> onToggleClosed;
  final ValueChanged<PollEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 720;
        final cards = [
          for (var index = 0; index < polls.length; index++)
            AnimatedEntrance(
              delay: Duration(milliseconds: 30 * index),
              child: PollCard(
                poll: polls[index],
                onTap: () => onTap(polls[index]),
                onEdit: busy || !canManage ? null : (poll) => onEdit(poll),
                onToggleClosed: busy || !canManage ? null : (poll) => onToggleClosed(poll),
                onDelete: busy || !canManage ? null : (poll) => onDelete(poll),
              ),
            ),
        ];

        if (!twoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in cards)
                Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault), child: card),
            ],
          );
        }

        final left = <Widget>[];
        final right = <Widget>[];
        for (var index = 0; index < cards.length; index++) {
          (index.isEven ? left : right).add(
            Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault), child: cards[index]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: Column(children: right)),
          ],
        );
      },
    );
  }
}

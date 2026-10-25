import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/extensions/screen_matres_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';

import 'package:mess_pilot/features/home/presentation/widgets/animated_entrance.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/notice/domain/entities/notice_entity.dart';
import 'package:mess_pilot/features/notice/presentation/bloc/notice_bloc.dart';
import 'package:mess_pilot/features/notice/presentation/bloc/notice_event.dart';
import 'package:mess_pilot/features/notice/presentation/bloc/notice_state.dart';
import 'package:mess_pilot/features/notice/presentation/widgets/notice_card.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/features/notice/presentation/widgets/notice_form_sheet.dart';

/// Notice board.
///
/// * **Manager / acting manager** — publish, edit, pin and delete notices.
/// * **Member** — a read-only list of notices, pinned first.
///
/// Every action shows progress (the list stays visible and actions are
/// disabled meanwhile) and ends with a success or a specific error message.
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return BlocProvider<NoticeBloc>(
      create: (_) => getIt<NoticeBloc>()..add(NoticeEvent.started(isAdmin: canManage)),
      child: const _NoticeView(),
    );
  }
}

class _NoticeView extends StatelessWidget {
  const _NoticeView();

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    final content = BlocBuilder<NoticeBloc, NoticeState>(
      builder: (context, state) {
        return state.maybeWhen(
          error: (message) => _ErrorView(message: message),
          loaded: (notices, isAdmin, busy) => _NoticeBody(notices: notices, isAdmin: isAdmin, busy: busy),
          orElse: () => const Center(child: AppLoader()),
        );
      },
    );

    // Reload when the authenticated role changes.
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) => context.read<NoticeBloc>().add(NoticeEvent.started(isAdmin: role.canManage)),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
        appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.notices)),
        floatingActionButton: BlocBuilder<NoticeBloc, NoticeState>(
          builder: (context, state) {
            final (canAdd, busy) = state.maybeWhen(loaded: (_, isAdmin, busy) => (isAdmin, busy), orElse: () => (false, false));
            if (!canAdd) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: busy ? null : () => _openAdd(context),
              backgroundColor: busy ? context.theme.disabledColor : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.local.newNotice),
            );
          },
        ),
        body: showWebAppBar
            ? Column(
                children: [
                  const DashboardTopBar(),
                  WebPageTitleBar(title: context.local.notices),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final bloc = context.read<NoticeBloc>();
    final saved = await showNoticeFormSheet(
      context: context,
      onSubmit: ({required title, required description}) {
        final done = Completer<Failure?>();
        bloc.add(NoticeEvent.add(title: title, description: description, done: done));
        return done.future;
      },
    );
    if ((saved ?? false) && context.mounted) context.showSuccessSnackBar(context.local.noticePublished);
  }
}



class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return AppErrorState(error: message, onRetry: () => context.read<NoticeBloc>().add(NoticeEvent.started(isAdmin: canManage)));
  }
}

class _NoticeBody extends StatelessWidget {
  const _NoticeBody({required this.notices, required this.isAdmin, required this.busy});

  final List<NoticeEntity> notices;
  final bool isAdmin;

  /// A refresh or change is running: show progress and disable the actions.
  final bool busy;

  Future<void> _onEdit(BuildContext context, NoticeEntity notice) async {
    final bloc = context.read<NoticeBloc>();
    final saved = await showNoticeFormSheet(
      context: context,
      existing: notice,
      onSubmit: ({required title, required description}) {
        final done = Completer<Failure?>();
        bloc.add(NoticeEvent.update(id: notice.id, title: title, description: description, done: done));
        return done.future;
      },
    );
    if ((saved ?? false) && context.mounted) context.showSuccessSnackBar(context.local.noticeUpdated);
  }

  Future<void> _onTogglePin(BuildContext context, NoticeEntity notice) async {
    final success = notice.pinned ? context.local.noticeUnpinned : context.local.noticePinned;
    final done = Completer<Failure?>();
    context.read<NoticeBloc>().add(NoticeEvent.togglePin(id: notice.id, pinned: !notice.pinned, done: done));
    await _report(context, done.future, success);
  }

  Future<void> _onDelete(BuildContext context, NoticeEntity notice) async {
    final bloc = context.read<NoticeBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.local.deleteNotice),
        content: Text(context.local.deleteNoticeConfirm(notice.title)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.local.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.local.delete)),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final success = context.local.noticeDeleted;
    final done = Completer<Failure?>();
    bloc.add(NoticeEvent.delete(notice.id, done: done));
    await _report(context, done.future, success);
  }

  Future<void> _onRefresh(BuildContext context) async {
    final done = Completer<Failure?>();
    context.read<NoticeBloc>().add(NoticeEvent.refresh(done: done));
    // Keeps the pull-to-refresh spinner until the reload actually finishes.
    final failure = await done.future;
    if (failure != null && context.mounted) context.showErrorSnackBar(failure);
  }

  /// Shows [success] or the failure's specific message once [outcome] lands.
  Future<void> _report(BuildContext context, Future<Failure?> outcome, String success) async {
    final failure = await outcome;
    if (!context.mounted) return;
    if (failure == null) {
      context.showSuccessSnackBar(success);
    } else {
      context.showErrorSnackBar(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _onRefresh(context),
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                // Fills the screen so the footer sits at the bottom on desktop.
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Column(
                  mainAxisAlignment: isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          child: notices.isEmpty
                              ? const _EmptyView()
                              : _NoticeList(
                                  notices: notices,
                                  isAdmin: isAdmin,
                                  onEdit: busy ? null : (n) => _onEdit(context, n),
                                  onDelete: busy ? null : (n) => _onDelete(context, n),
                                  onTogglePin: busy ? null : (n) => _onTogglePin(context, n),
                                ),
                        ),
                      ),
                    ),
                    if (isDesktop) const AppFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

/// Responsive notice list — single column on phones, two columns on wide
/// screens (tablet / desktop).
class _NoticeList extends StatelessWidget {
  const _NoticeList({required this.notices, required this.isAdmin, required this.onEdit, required this.onDelete, required this.onTogglePin});

  final List<NoticeEntity> notices;
  final bool isAdmin;

  /// Null while another action runs, which disables the card buttons.
  final ValueChanged<NoticeEntity>? onEdit;
  final ValueChanged<NoticeEntity>? onDelete;
  final ValueChanged<NoticeEntity>? onTogglePin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 720;
        final cards = [
          for (var i = 0; i < notices.length; i++)
            AnimatedEntrance(
              delay: Duration(milliseconds: 30 * i),
              child: NoticeCard(
                notice: notices[i],
                showActions: isAdmin,
                onTap: () => context.go(AppRoutes.getNoticeDetailsRoute(notices[i].id), extra: notices[i]),
                onEdit: onEdit == null ? null : () => onEdit!(notices[i]),
                onDelete: onDelete == null ? null : () => onDelete!(notices[i]),
                onTogglePin: onTogglePin == null ? null : () => onTogglePin!(notices[i]),
              ),
            ),
        ];

        if (!twoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: card,
                ),
              SizedBox(height: context.bottomPadding + 72),
            ],
          );
        }

        final left = <Widget>[];
        final right = <Widget>[];
        for (var i = 0; i < cards.length; i++) {
          (i.isEven ? left : right).add(
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: cards[i],
            ),
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: left)),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(child: Column(children: right)),
              ],
            ),
            SizedBox(height: context.bottomPadding + 72),
          ],
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(title: context.local.noNoticesYet, icon: Icons.campaign_outlined);
  }
}

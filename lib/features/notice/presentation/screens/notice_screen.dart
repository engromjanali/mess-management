import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/overly_extensions.dart';
import '../../../../core/extensions/screen_matres_extensions.dart';
import '../../../../core/role/role_cubit.dart';
import '../../../home/presentation/widgets/animated_entrance.dart';
import '../../domain/entities/notice_entity.dart';
import '../bloc/notice_bloc.dart';
import '../bloc/notice_event.dart';
import '../bloc/notice_state.dart';
import '../widgets/notice_card.dart';
import '../widgets/notice_form_sheet.dart';

/// Notice board.
///
/// * **Admin** — publish, edit and delete notices.
/// * **User** — a read-only list of notices.
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
    return BlocProvider<NoticeBloc>(
      create: (_) =>
          getIt<NoticeBloc>()..add(NoticeEvent.started(isAdmin: isAdmin)),
      child: const _NoticeView(),
    );
  }
}

class _NoticeView extends StatelessWidget {
  const _NoticeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) => context
          .read<NoticeBloc>()
          .add(NoticeEvent.started(isAdmin: role.isAdmin)),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Notices')),
        floatingActionButton: BlocBuilder<NoticeBloc, NoticeState>(
          builder: (context, state) {
            final canAdd = state.maybeWhen(
              loaded: (_, isAdmin, _) => isAdmin,
              orElse: () => false,
            );
            if (!canAdd) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New notice'),
            );
          },
        ),
        body: BlocConsumer<NoticeBloc, NoticeState>(
          listener: (context, state) {
            state.maybeWhen(
              error: (message) => context.showErrorSnackBar(message),
              orElse: () {},
            );
          },
          builder: (context, state) {
            return state.maybeWhen(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (message) => _ErrorView(message: message),
              loaded: (notices, isAdmin, saving) => _NoticeBody(
                notices: notices,
                isAdmin: isAdmin,
                saving: saving,
              ),
              orElse: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
            );
          },
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final bloc = context.read<NoticeBloc>();
    showNoticeFormSheet(
      context: context,
      onSave: ({required title, required description}) => bloc.add(
        NoticeEvent.add(title: title, description: description),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sfProRoundedMedium.copyWith(
                color: colors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<NoticeBloc>()
                  .add(NoticeEvent.started(isAdmin: isAdmin)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeBody extends StatelessWidget {
  const _NoticeBody({
    required this.notices,
    required this.isAdmin,
    required this.saving,
  });

  final List<NoticeEntity> notices;
  final bool isAdmin;
  final bool saving;

  void _onEdit(BuildContext context, NoticeEntity notice) {
    final bloc = context.read<NoticeBloc>();
    showNoticeFormSheet(
      context: context,
      existing: notice,
      onSave: ({required title, required description}) => bloc.add(
        NoticeEvent.update(
          id: notice.id,
          title: title,
          description: description,
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, NoticeEntity notice) async {
    final bloc = context.read<NoticeBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notice'),
        content: Text('Delete "${notice.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(NoticeEvent.delete(notice.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            context.read<NoticeBloc>().add(const NoticeEvent.refresh());
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
          child: notices.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyView(),
                  ],
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: Dimensions.webMaxWidth),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: _NoticeList(
                          notices: notices,
                          isAdmin: isAdmin,
                          onEdit: (n) => _onEdit(context, n),
                          onDelete: (n) => _onDelete(context, n),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        if (saving)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

/// Responsive notice list — single column on phones, two columns on wide
/// screens (tablet / desktop).
class _NoticeList extends StatelessWidget {
  const _NoticeList({
    required this.notices,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final List<NoticeEntity> notices;
  final bool isAdmin;
  final ValueChanged<NoticeEntity> onEdit;
  final ValueChanged<NoticeEntity> onDelete;

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
                onEdit: () => onEdit(notices[i]),
                onDelete: () => onDelete(notices[i]),
              ),
            ),
        ];

        if (!twoColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: Dimensions.paddingSizeDefault),
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
              padding:
                  const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
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
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeExtraLarge32),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined,
              size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            'No notices yet',
            style: AppTextStyles.sfProRoundedMedium.copyWith(
              color: colors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

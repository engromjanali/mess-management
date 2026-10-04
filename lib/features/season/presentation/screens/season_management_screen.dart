import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/season/domain/entities/auto_create_season_entity.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';
import 'package:clean_boilerplate/features/season/presentation/bloc/season_bloc.dart';
import 'package:clean_boilerplate/features/season/presentation/bloc/season_event.dart';
import 'package:clean_boilerplate/features/season/presentation/bloc/season_state.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/auto_create_day_sheet.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/auto_create_season_card.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/current_season_card.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_form_sheet.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_tile.dart';

/// Season management (manager / acting manager).
///
/// A mess can run many seasons at once; the manager works in the one "in
/// use". They can create (copying a season's members who haven't left),
/// edit, end, disable / enable, delete and switch seasons. Creating a season
/// doesn't end another; ending one stops new data after its end date. When
/// the season in use changes the app goes home so every screen reloads that
/// season's data. With auto-create on, the backend creates a new season on
/// the chosen day of each month and switches the members to it.
///
/// Every action shows progress (the list stays visible and actions are
/// disabled meanwhile) and ends with a success or the backend's specific error.
class SeasonManagementScreen extends StatelessWidget {
  const SeasonManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
    return BlocProvider<SeasonBloc>(
      create: (_) {
        final bloc = getIt<SeasonBloc>();
        if (isAdmin) bloc.add(const SeasonEvent.started());
        return bloc;
      },
      child: const _SeasonView(),
    );
  }
}

class _SeasonView extends StatelessWidget {
  const _SeasonView();

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<RoleCubit>().state.isAdmin;
    final showWebAppBar = MainPageBody.showWebAppBar(context);

    final content = BlocBuilder<SeasonBloc, SeasonState>(
      builder: (context, state) => state.maybeWhen(
        error: (message) => _ErrorView(message: message),
        loaded: (overview, busy) => _SeasonBody(overview: overview, busy: busy),
        orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
      ),
    );

    // Load when the global role switcher turns admin on.
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr && curr.isAdmin,
      listener: (context, _) => context.read<SeasonBloc>().add(const SeasonEvent.started()),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
        appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.seasonManagement)),
        floatingActionButton: isAdmin
            ? BlocBuilder<SeasonBloc, SeasonState>(
                builder: (context, state) {
                  final (overview, busy) = state.maybeWhen(loaded: (overview, busy) => (overview, busy), orElse: () => (null, true));
                  if (overview == null) return const SizedBox.shrink();
                  return FloatingActionButton.extended(
                    onPressed: busy ? null : () => _create(context, overview),
                    backgroundColor: busy ? context.theme.disabledColor : null,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(context.local.newSeason),
                  );
                },
              )
            : null,
        body: MainPageBody(
          title: context.local.seasonManagement,
          child: isAdmin ? content : const _AdminOnlyView(),
        ),
      ),
    );
  }

  /// New season; its members are copied from the season picked in the form
  /// (the one in use by default). Nobody switches to it.
  Future<void> _create(BuildContext context, SeasonOverviewEntity overview) async {
    final bloc = context.read<SeasonBloc>();
    final name = await showSeasonFormSheet(
      context,
      sources: overview.seasons,
      defaultSourceId: overview.currentSeasonId,
      onSubmit: (form) {
        final done = Completer<Failure?>();
        bloc.add(SeasonEvent.create(name: form.name, startDate: form.startDate, sourceSeasonId: form.sourceSeasonId!, done: done));
        return done.future;
      },
    );
    if (name != null && context.mounted) context.showSuccessSnackBar(context.local.seasonCreated(name));
  }
}

class _SeasonBody extends StatelessWidget {
  const _SeasonBody({required this.overview, required this.busy});

  final SeasonOverviewEntity overview;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 96),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CurrentSeasonCard(season: overview.current),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      AutoCreateSeasonCard(
                        setting: overview.autoCreate,
                        onToggle: busy ? null : (enabled) => _toggleAutoCreate(context, enabled),
                        onChangeDay: busy ? null : () => _changeAutoCreateDay(context),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      SectionTitle(title: context.local.allSeasons, icon: Icons.event_note_rounded),
                      if (overview.seasons.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                          child: Text(context.local.noSeasons, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: context.customThemeColors.textSecondaryColor)),
                        )
                      else
                        for (final season in overview.seasons)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                            child: SeasonTile(
                              season: season,
                              inUse: season.id == overview.currentSeasonId,
                              enabled: !busy,
                              onSwitch: () => _switchTo(context, season),
                              onEdit: () => _edit(context, season),
                              onEnd: () => _end(context, season),
                              onToggleDisabled: () => _toggleDisabled(context, season),
                              onDelete: () => _delete(context, season),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }

  /// Switches and, once saved, goes home so every screen loads the season.
  Future<void> _switchTo(BuildContext context, SeasonEntity season) async {
    final done = Completer<Failure?>();
    context.read<SeasonBloc>().add(SeasonEvent.switchTo(season.id, done: done));
    if (await _report(context, done.future, context.local.seasonSwitched(season.name)) && context.mounted) _reloadApp(context);
  }

  Future<void> _edit(BuildContext context, SeasonEntity season) async {
    final bloc = context.read<SeasonBloc>();
    final name = await showSeasonFormSheet(
      context,
      existing: season,
      onSubmit: (form) {
        final done = Completer<Failure?>();
        bloc.add(SeasonEvent.update(id: season.id, name: form.name, startDate: form.startDate, endDate: form.endDate, done: done));
        return done.future;
      },
    );
    if (name != null && context.mounted) context.showSuccessSnackBar(context.local.seasonUpdated(name));
  }

  Future<void> _end(BuildContext context, SeasonEntity season) async {
    if (!await _confirm(context, title: context.local.endSeason, message: context.local.endSeasonConfirm(season.name), action: context.local.endSeason) || !context.mounted) return;
    final done = Completer<Failure?>();
    context.read<SeasonBloc>().add(SeasonEvent.end(season.id, done: done));
    await _report(context, done.future, context.local.seasonEnded(season.name));
  }

  Future<void> _toggleDisabled(BuildContext context, SeasonEntity season) async {
    final done = Completer<Failure?>();
    context.read<SeasonBloc>().add(SeasonEvent.setDisabled(id: season.id, disabled: !season.disabled, done: done));
    await _report(context, done.future, season.disabled ? context.local.seasonEnabled(season.name) : context.local.seasonDisabled(season.name));
  }

  /// Deletes [season] with all its data. If it was in use the backend moves
  /// the manager to another season, so the app reloads from home.
  Future<void> _delete(BuildContext context, SeasonEntity season) async {
    final confirmed = await _confirm(context, title: context.local.deleteSeason, message: context.local.deleteSeasonConfirm(season.name), action: context.local.delete, destructive: true);
    if (!confirmed || !context.mounted) return;
    final wasInUse = season.id == overview.currentSeasonId;
    final done = Completer<Failure?>();
    context.read<SeasonBloc>().add(SeasonEvent.delete(season.id, done: done));
    if (await _report(context, done.future, context.local.seasonDeleted(season.name)) && wasInUse && context.mounted) _reloadApp(context);
  }

  Future<void> _toggleAutoCreate(BuildContext context, bool enabled) async {
    final done = Completer<Failure?>();
    context.read<SeasonBloc>().add(SeasonEvent.setAutoCreate(enabled: enabled, done: done));
    await _report(context, done.future, enabled ? context.local.autoCreateOn : context.local.autoCreateOff);
  }

  Future<void> _changeAutoCreateDay(BuildContext context) async {
    final bloc = context.read<SeasonBloc>();
    final day = await showAutoCreateDaySheet(context, selected: overview.autoCreate.day);
    if (day == null || day == overview.autoCreate.day || !context.mounted) return;
    final done = Completer<Failure?>();
    bloc.add(SeasonEvent.setAutoCreate(day: day, done: done));
    await _report(context, done.future, context.local.autoCreateDaySet(day == AutoCreateSeasonEntity.monthEnd ? context.local.monthEnd : context.local.dayOfMonth(day)));
  }

  Future<void> _refresh(BuildContext context) async {
    final done = Completer<Failure?>();
    context.read<SeasonBloc>().add(SeasonEvent.refresh(done: done));
    // Keeps the pull-to-refresh spinner until the reload actually finishes.
    final failure = await done.future;
    if (failure != null && context.mounted) context.showErrorSnackBar(failure.message);
  }

  /// Shows [success] or the failure's specific message once [outcome] lands;
  /// returns whether it succeeded.
  Future<bool> _report(BuildContext context, Future<Failure?> outcome, String success) async {
    final failure = await outcome;
    if (!context.mounted) return false;
    if (failure == null) {
      context.showSuccessSnackBar(success);
    } else {
      context.showErrorSnackBar(failure.message);
    }
    return failure == null;
  }

  /// The season in use changed: open home so every screen loads its data.
  void _reloadApp(BuildContext context) => context.go(AppRoutes.home);

  Future<bool> _confirm(BuildContext context, {required String title, required String message, required String action, bool destructive = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.local.cancel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: context.customThemeColors.errorColor) : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton.icon(
              onPressed: () => context.read<SeasonBloc>().add(const SeasonEvent.started()),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.local.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOnlyView extends StatelessWidget {
  const _AdminOnlyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(context.local.seasonManagementAdminOnly, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

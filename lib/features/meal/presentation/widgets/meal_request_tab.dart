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
import 'package:mess_pilot/core/extensions/screen_matres_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_date_time_picker_sheet.dart';
import 'package:mess_pilot/core/widgets/app_dialog.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_user_avatar.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_member_entity.dart';
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';
import 'package:mess_pilot/features/meal/presentation/bloc/meal_request_bloc.dart';
import 'package:mess_pilot/features/meal/presentation/bloc/meal_request_event.dart';
import 'package:mess_pilot/features/meal/presentation/bloc/meal_request_state.dart';
import 'package:mess_pilot/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:mess_pilot/features/meal/presentation/widgets/meal_stepper.dart';

/// The display title for a meal request: the meal date formatted into the
/// default "Please choose your meal for …" template. Not stored — derived.
String _mealRequestTitle(BuildContext context, DateTime date) {
  final text = MaterialLocalizations.of(context).formatMediumDate(date);
  return context.local.mealRequestDefaultTitle(text);
}

/// Meal requests: managers open a request for a date and members pick the meals
/// they will have before the deadline.
class MealRequestTab extends StatelessWidget {
  const MealRequestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MealRequestBloc>(
      create: (_) => getIt<MealRequestBloc>()..add(const MealRequestLoad()),
      child: const _MealRequestView(),
    );
  }
}

class _MealRequestView extends StatelessWidget {
  const _MealRequestView();

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<MealRequestBloc>();
    final draft = await context.showAdaptiveSheet<MealRequestDraft>(child: const _MealRequestForm());
    if (draft == null || !context.mounted) return;

    final done = Completer<Failure?>();
    bloc.add(MealRequestCreate(draft: draft, done: done));
    final failure = await done.future;
    if (!context.mounted) return;
    if (failure != null) {
      context.showErrorSnackBar(failure);
      return;
    }
    context.showSuccessSnackBar(context.local.mealRequestCreatedMessage);
  }

  Future<void> _edit(BuildContext context, MealRequestEntity request) async {
    final bloc = context.read<MealRequestBloc>();
    final draft = await context.showAdaptiveSheet<MealRequestDraft>(child: _MealRequestForm(initial: request));
    if (draft == null || !context.mounted) return;

    final done = Completer<Failure?>();
    bloc.add(MealRequestUpdate(id: request.id, draft: draft, done: done));
    final failure = await done.future;
    if (!context.mounted) return;
    if (failure != null) {
      context.showErrorSnackBar(failure);
      return;
    }
    context.showSuccessSnackBar(context.local.mealRequestUpdatedMessage);
  }

  Future<void> _delete(BuildContext context, MealRequestEntity request) async {
    final bloc = context.read<MealRequestBloc>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.local.mealRequestDeleteTitle,
      message: context.local.mealRequestDeleteMessage,
      confirmLabel: context.local.delete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final done = Completer<Failure?>();
    bloc.add(MealRequestDelete(id: request.id, done: done));
    final failure = await done.future;
    if (!context.mounted) return;
    if (failure != null) {
      context.showErrorSnackBar(failure);
      return;
    }
    context.showSuccessSnackBar(context.local.mealRequestDeletedMessage);
  }

  Future<void> _select(BuildContext context, MealRequestEntity request) async {
    final bloc = context.read<MealRequestBloc>();
    final result = await context.showAdaptiveSheet<(double, double, double)>(child: _MealSelectionSheet(request: request));
    if (result == null || !context.mounted) return;

    final done = Completer<Failure?>();
    bloc.add(MealRequestSelect(id: request.id, breakfast: result.$1, lunch: result.$2, dinner: result.$3, done: done));
    final failure = await done.future;
    if (!context.mounted) return;
    if (failure != null) {
      context.showErrorSnackBar(failure);
      return;
    }
    final total = result.$1 + result.$2 + result.$3;
    context.showSuccessSnackBar(total == 0 ? context.local.mealRequestSelectionWithdrawn : context.local.mealRequestSelectionSaved);
  }

  Future<void> _view(BuildContext context, MealRequestEntity request) async {
    await context.showAdaptiveSheet<void>(child: _MealSelectionsSheet(request: request));
  }

  Future<void> _addToMeal(BuildContext context, MealRequestEntity request) async {
    final draft = MealRequestApplyDraft(
      date: request.date,
      requestIds: [request.id],
      meals: [
        for (final s in request.selections)
          MemberMealEntity(memberId: s.memberId, date: request.date, breakfast: s.breakfast, lunch: s.lunch, dinner: s.dinner),
      ],
    );
    await context.push(AppRoutes.addMeal, extra: draft);
  }

  Future<void> _close(BuildContext context, MealRequestEntity request) async {
    final bloc = context.read<MealRequestBloc>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.local.mealRequestCloseTitle,
      message: context.local.mealRequestCloseMessage,
      confirmLabel: context.local.mealRequestClose,
      icon: Icons.lock_outline_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final done = Completer<Failure?>();
    bloc.add(MealRequestClose(id: request.id, done: done));
    final failure = await done.future;
    if (!context.mounted) return;
    if (failure != null) {
      context.showErrorSnackBar(failure);
      return;
    }
    context.showSuccessSnackBar(context.local.mealRequestClosedMessage);
  }

  Future<void> _reopen(BuildContext context, MealRequestEntity request) async {
    final bloc = context.read<MealRequestBloc>();
    final done = Completer<Failure?>();
    bloc.add(MealRequestReopen(id: request.id, done: done));
    final failure = await done.future;
    if (!context.mounted) return;
    if (failure != null) {
      context.showErrorSnackBar(failure);
      return;
    }
    context.showSuccessSnackBar(context.local.mealRequestReopenedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealRequestBloc, MealRequestState>(
      builder: (context, state) {
        if (state is MealRequestError) {
          return AppErrorState(error: state.message, onRetry: () => context.read<MealRequestBloc>().add(const MealRequestLoad()));
        }

        final overview = state is MealRequestLoaded ? state.overview : null;
        final busy = state is MealRequestLoaded && state.busy;
        final loading = overview == null;

        return RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<MealRequestBloc>()..add(const MealRequestLoad());
            await bloc.stream.firstWhere((next) => next is MealRequestLoaded || next is MealRequestError);
          },
          child: AppPageScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
            maxWidth: Dimensions.webMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (busy) const LinearProgressIndicator(minHeight: 2),
                _Header(canManage: overview?.canManage ?? false, onCreate: () => _create(context)),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                if (loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge24), child: Center(child: AppLoader()))
                else if (overview.requests.isEmpty)
                  AppEmptyState(title: context.local.mealRequestEmpty, message: context.local.mealRequestEmptyHint, icon: Icons.event_note_rounded)
                else
                  for (var index = 0; index < overview.requests.length; index++) ...[
                    if (index > 0) const SizedBox(height: Dimensions.paddingSizeDefault),
                    _RequestCard(
                      request: overview.requests[index],
                      onSelect: overview.requests[index].canRespond ? () => _select(context, overview.requests[index]) : null,
                      onView: overview.requests[index].canManage ? () => _view(context, overview.requests[index]) : null,
                      onEdit: overview.requests[index].canManage ? () => _edit(context, overview.requests[index]) : null,
                      onAddToMeal: overview.requests[index].canManage ? () => _addToMeal(context, overview.requests[index]) : null,
                      onClose: overview.requests[index].canManage ? () => _close(context, overview.requests[index]) : null,
                      onReopen: overview.requests[index].canManage ? () => _reopen(context, overview.requests[index]) : null,
                      onDelete: overview.requests[index].canManage ? () => _delete(context, overview.requests[index]) : null,
                    ),
                  ],
                SizedBox(height: context.bottomPadding),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.canManage, required this.onCreate});

  final bool canManage;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.22 : 0.12),
            colors.infoColor.withValues(alpha: context.isDarkMode ? 0.14 : 0.06),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final text = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                child: Icon(Icons.restaurant_rounded, color: colors.primaryColor),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.local.mealRequestTab, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
                    const SizedBox(height: 2),
                    Text(context.local.mealRequestScreenSubtitle, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor, height: 1.4)),
                  ],
                ),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.local.mealRequestNew),
          );

          if (!canManage) return text;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: Dimensions.paddingSizeDefault), SizedBox(height: Dimensions.buttonHeight, child: button)],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onSelect, this.onView, this.onEdit, this.onAddToMeal, this.onClose, this.onReopen, this.onDelete});

  final MealRequestEntity request;
  final VoidCallback? onSelect;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onAddToMeal;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final status = _statusOf(context);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _mealRequestTitle(context, request.date),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _StatusChip(label: status.$1, color: status.$2),
              if (request.canManage)
                PopupMenuButton<_RequestAction>(
                  tooltip: context.local.mealRequestManage,
                  padding: EdgeInsets.zero,
                  iconSize: Dimensions.iconSizeDefault,
                  icon: Icon(Icons.more_vert_rounded, color: colors.textSecondaryColor),
                  onSelected: (action) => switch (action) {
                    _RequestAction.view => onView?.call(),
                    _RequestAction.edit => onEdit?.call(),
                    _RequestAction.addToMeal => onAddToMeal?.call(),
                    _RequestAction.close => onClose?.call(),
                    _RequestAction.reopen => onReopen?.call(),
                    _RequestAction.delete => onDelete?.call(),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _RequestAction.view,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.visibility_outlined),
                        title: Text(context.local.mealRequestView),
                      ),
                    ),
                    PopupMenuItem(
                      value: _RequestAction.edit,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(context.local.edit),
                      ),
                    ),
                    if (request.responseCount > 0)
                      PopupMenuItem(
                        value: _RequestAction.addToMeal,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.restaurant_rounded),
                          title: Text(context.local.mealRequestAddToMeal),
                        ),
                      ),
                    if (request.isOpen)
                      PopupMenuItem(
                        value: _RequestAction.close,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock_outline_rounded),
                          title: Text(context.local.mealRequestClose),
                        ),
                      )
                    else
                      PopupMenuItem(
                        value: _RequestAction.reopen,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock_open_rounded),
                          title: Text(context.local.mealRequestReopen),
                        ),
                      ),
                    PopupMenuItem(
                      value: _RequestAction.delete,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded, color: colors.errorColor),
                        title: Text(context.local.delete, style: TextStyle(color: colors.errorColor)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeExtraSmall,
            children: [
              _MetaChip(icon: Icons.event_rounded, label: MealFormatters.dayLabel(request.date), color: colors.primaryColor),
              _MetaChip(icon: Icons.schedule_rounded, label: context.local.mealRequestEnds(TimeOfDay.fromDateTime(request.endAt).format(context)), color: colors.secondaryColor),
            ],
          ),
          if (request.description.trim().isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor, height: 1.4),
            ),
          ],
          if (request.hasSelection) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _MySelectionChips(selection: request.mySelection!),
          ],
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Divider(height: Dimensions.paddingSizeLarge, color: colors.dividerColor.withValues(alpha: 0.3)),
          Row(
            children: [
              Icon(Icons.groups_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  _footerSummary(context, compact: ResponsiveHelper.isSmallMobile(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              if (onSelect != null)
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault)),
                  onPressed: onSelect,
                  icon: Icon(request.hasSelection ? Icons.edit_rounded : Icons.check_circle_outline_rounded, size: Dimensions.iconSizeSmall),
                  label: Text(request.hasSelection ? context.local.mealRequestEditSelection : context.local.mealRequestSelectMeal),
                )
              else
                Text(context.local.mealRequestClosedHint, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
            ],
          ),
        ],
      ),
    );
  }

  String _footerSummary(BuildContext context, {required bool compact}) {
    final responded = compact
        ? context.local.mealRequestRespondedCompact(request.responseCount, request.eligibleMemberCount)
        : context.local.mealRequestResponded(request.responseCount, request.eligibleMemberCount);
    final local = context.local;
    final b = MealFormatters.count(request.breakfastTotal);
    final l = MealFormatters.count(request.lunchTotal);
    final d = MealFormatters.count(request.dinnerTotal);
    return '$responded | ${local.uiB} $b · ${local.uiL} $l · ${local.uiD} $d';
  }

  (String, Color) _statusOf(BuildContext context) {
    final colors = context.customThemeColors;
    if (request.closedAt != null) return (context.local.mealRequestClosed, colors.textHintColor);
    if (!request.isOpen) return (context.local.mealRequestTimedOut, colors.warningColor);
    return (context.local.mealRequestOpen, colors.successColor);
  }
}

class _MySelectionChips extends StatelessWidget {
  const _MySelectionChips({required this.selection});

  final MealSelectionEntity selection;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final local = context.local;
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeExtraSmall,
      children: [
        _MetaChip(icon: Icons.free_breakfast_rounded, label: '${local.uiB} ${MealFormatters.count(selection.breakfast)}', color: colors.warningColor),
        _MetaChip(icon: Icons.lunch_dining_rounded, label: '${local.uiL} ${MealFormatters.count(selection.lunch)}', color: colors.primaryColor),
        _MetaChip(icon: Icons.dinner_dining_rounded, label: '${local.uiD} ${MealFormatters.count(selection.dinner)}', color: colors.infoColor),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
      child: Text(
        label,
        style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textPrimaryColor)),
        ],
      ),
    );
  }
}

class _MealRequestForm extends StatefulWidget {
  const _MealRequestForm({this.initial});

  final MealRequestEntity? initial;

  @override
  State<_MealRequestForm> createState() => _MealRequestFormState();
}

class _MealRequestFormState extends State<_MealRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  late DateTime _date;
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final initial = widget.initial;
    if (initial != null) {
      _date = DateTime(initial.date.year, initial.date.month, initial.date.day);
      _endTime = TimeOfDay.fromDateTime(initial.endAt);
      _descriptionController.text = initial.description;
      return;
    }
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _endAt => DateTime(_date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 120)),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickEndAt() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await AppDateTimePickerSheet.show(
      context,
      initial: _endAt.isAfter(now) ? _endAt : now.add(const Duration(hours: 1)),
      minDate: today,
      maxDate: today.add(const Duration(days: 120)),
      timeLabel: context.local.mealRequestFormEndTime,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      _endTime = TimeOfDay(hour: picked.hour, minute: picked.minute);
    });
  }

  void _submit() {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final endAt = _endAt;
    if (!endAt.isAfter(DateTime.now())) {
      setState(() => _error = context.local.mealRequestEndTimeMustBeFuture);
      return;
    }
    Navigator.of(context).pop(
      MealRequestDraft(
        date: _date,
        description: _descriptionController.text.trim(),
        endAt: endAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final endLabel = '${_endTime.format(context)} · ${MealFormatters.dayLabel(_date)}';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? context.local.mealRequestFormHeading : context.local.mealRequestEditHeading,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _Label(context.local.mealRequestFormDate),
          _PickerField(icon: Icons.event_rounded, label: MealFormatters.dayLabel(_date), onTap: _pickDate),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _Label(context.local.mealRequestFormEndTime),
          _PickerField(icon: Icons.schedule_rounded, label: endLabel, onTap: _pickEndAt),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _Label(context.local.mealRequestFormDescription),
          TextFormField(
            controller: _descriptionController,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(context, hint: context.local.mealRequestFormDescriptionHint),
          ),
          if (_error != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(_error!, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.errorColor)),
          ],
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                  child: Text(context.local.cancel),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                  child: Text(widget.initial == null ? context.local.mealRequestCreate : context.local.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, {String? hint}) {
    final colors = context.customThemeColors;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      counterText: '',
      contentPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      filled: true,
      fillColor: colors.cardBackgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), borderSide: BorderSide(color: colors.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), borderSide: BorderSide(color: colors.borderColor)),
    );
  }
}

class _MealSelectionSheet extends StatefulWidget {
  const _MealSelectionSheet({required this.request});

  final MealRequestEntity request;

  @override
  State<_MealSelectionSheet> createState() => _MealSelectionSheetState();
}

class _MealSelectionSheetState extends State<_MealSelectionSheet> {
  late double _breakfast = widget.request.mySelection?.breakfast ?? 0;
  late double _lunch = widget.request.mySelection?.lunch ?? 0;
  late double _dinner = widget.request.mySelection?.dinner ?? 0;

  double get _total => _breakfast + _lunch + _dinner;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.local.mealRequestSelectionHeading, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
        const SizedBox(height: 4),
        Text(
          _mealRequestTitle(context, widget.request.date),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
        ),
        if (widget.request.description.trim().isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
            ),
            child: Text(
              widget.request.description,
              style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: Dimensions.paddingSizeLarge),
        _SelectionRow(icon: Icons.free_breakfast_rounded, label: context.local.uiBreakfast, accent: colors.warningColor, value: _breakfast, onChanged: (value) => setState(() => _breakfast = value)),
        const Divider(height: Dimensions.paddingSizeLarge),
        _SelectionRow(icon: Icons.lunch_dining_rounded, label: context.local.uiLunch, accent: colors.primaryColor, value: _lunch, onChanged: (value) => setState(() => _lunch = value)),
        const Divider(height: Dimensions.paddingSizeLarge),
        _SelectionRow(icon: Icons.dinner_dining_rounded, label: context.local.uiDinner, accent: colors.infoColor, value: _dinner, onChanged: (value) => setState(() => _dinner = value)),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Row(
          children: [
            Text(context.local.total, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textSecondaryColor)),
            const Spacer(),
            Text('${MealFormatters.count(_total)} meals', style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.primaryColor)),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                child: Text(context.local.cancel),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _total > 0 ? () => Navigator.of(context).pop((_breakfast, _lunch, _dinner)) : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                icon: const Icon(Icons.check_rounded),
                label: Text(context.local.mealRequestSaveSelection),
              ),
            ),
          ],
        ),
        if (widget.request.hasSelection)
          Align(
            alignment: AlignmentDirectional.center,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop((0.0, 0.0, 0.0)),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(context.local.mealRequestWithdraw),
            ),
          ),
      ],
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({required this.icon, required this.label, required this.accent, required this.value, required this.onChanged});

  final IconData icon;
  final String label;
  final Color accent;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      children: [
        Icon(icon, color: accent, size: Dimensions.iconSizeDefault),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(label, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor))),
        MealStepper(value: value, accent: accent, onChanged: onChanged, min: 0, max: 3),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: colors.cardBackgroundColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor)),
              ),
              Icon(Icons.expand_more_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RequestAction { view, edit, addToMeal, close, reopen, delete }

class _MealSelectionsSheet extends StatelessWidget {
  const _MealSelectionsSheet({required this.request});

  final MealRequestEntity request;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final local = context.local;
    final selections = request.selections;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(local.mealRequestSelectionsHeading, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
        const SizedBox(height: 4),
        Text(
          '${_mealRequestTitle(context, request.date)} · ${local.mealRequestResponded(request.responseCount, request.eligibleMemberCount)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        if (selections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
            child: Text(local.mealRequestNoSelections, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: selections.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.dividerColor.withValues(alpha: 0.3)),
              itemBuilder: (context, index) => _SelectionItemRow(item: selections[index]),
            ),
          ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
          child: Text(local.done),
        ),
      ],
    );
  }
}

class _SelectionItemRow extends StatelessWidget {
  const _SelectionItemRow({required this.item});

  final MealRequestSelectionItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final local = context.local;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          AppUserAvatar(name: item.memberName, photoUrl: item.memberPhoto),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.memberName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Wrap(
                  spacing: Dimensions.paddingSizeExtraSmall,
                  runSpacing: Dimensions.paddingSizeExtraSmall,
                  children: [
                    _MetaChip(icon: Icons.free_breakfast_rounded, label: '${local.uiB} ${MealFormatters.count(item.breakfast)}', color: colors.warningColor),
                    _MetaChip(icon: Icons.lunch_dining_rounded, label: '${local.uiL} ${MealFormatters.count(item.lunch)}', color: colors.primaryColor),
                    _MetaChip(icon: Icons.dinner_dining_rounded, label: '${local.uiD} ${MealFormatters.count(item.dinner)}', color: colors.infoColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Text(text, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor)),
    );
  }
}

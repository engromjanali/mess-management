import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_bloc.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_state.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/member_meal_form_sheet.dart';

/// Admin-only meal management section.
///
/// Lets a manager add, edit and delete meals for a specific member on a
/// specific date, with member and date filters over the full record list.
/// Provides its own [MealAdminBloc] so it is self-contained inside the screen.
class MealAdminPanel extends StatelessWidget {
  const MealAdminPanel({this.showViewAll = true, super.key});

  final bool showViewAll;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MealAdminBloc>(create: (_) => getIt<MealAdminBloc>()..add(const MealAdminEvent.load()), child: _MealAdminView(showViewAll: showViewAll));
  }
}

class _MealAdminView extends StatelessWidget {
  const _MealAdminView({required this.showViewAll});

  final bool showViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Manage meals',
          icon: Icons.manage_accounts_rounded,
          showViewAll: showViewAll,
          toolTipsLabel: 'See all members',
          viewAllAction: showViewAll ? () => context.push(AppRoutes.mealList) : null,
        ),
        BlocBuilder<MealAdminBloc, MealAdminState>(
          builder: (context, state) {
            return state.when(
              initial: _loading,
              loading: _loading,
              error: (message) => _ErrorCard(message: message),
              loaded: (data, memberId, date) => _ManageCard(data: data, selectedMemberId: memberId, selectedDate: date),
            );
          },
        ),
      ],
    );
  }

  Widget _loading() => const Padding(
    padding: EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
    child: Center(child: CircularProgressIndicator.adaptive()),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return _Card(
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.errorColor),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Text(message, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
          ),
          TextButton(onPressed: () => context.read<MealAdminBloc>().add(const MealAdminEvent.load()), child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({required this.data, required this.selectedMemberId, required this.selectedDate});

  final MealAdminEntity data;
  final String? selectedMemberId;
  final DateTime? selectedDate;

  Future<void> _add(BuildContext context) async {
    final result = await showMemberMealForm(context, members: data.members, presetMemberId: selectedMemberId, presetDate: selectedDate);
    if (result != null && context.mounted) {
      context.read<MealAdminBloc>().add(MealAdminEvent.save(memberId: result.memberId, date: result.date, breakfast: result.breakfast, lunch: result.lunch, dinner: result.dinner));
    }
  }

  Future<void> _edit(BuildContext context, MemberMealEntity entry) async {
    final result = await showMemberMealForm(context, members: data.members, existing: entry);
    if (result != null && context.mounted) {
      context.read<MealAdminBloc>().add(MealAdminEvent.update(memberId: result.memberId, date: result.date, breakfast: result.breakfast, lunch: result.lunch, dinner: result.dinner));
    }
  }

  Future<void> _confirmDelete(BuildContext context, MemberMealEntity entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text(
          '${data.memberName(entry.memberId)} · '
          '${MealFormatters.dayLabel(entry.date)}\n'
          'This removes the recorded meal for that day.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<MealAdminBloc>().add(MealAdminEvent.delete(memberId: entry.memberId, date: entry.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final entries = data.filtered(memberId: selectedMemberId, date: selectedDate);
    final compactActions = ResponsiveHelper.isMobile(context) || ResponsiveHelper.isSmallTab(context);
    final recordCount = Text(
      '${entries.length} '
      '${entries.length == 1 ? 'record' : 'records'}',
      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
    );
    final actionButtons = Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      alignment: WrapAlignment.end,
      children: [
        FilledButton.icon(onPressed: () => context.go(AppRoutes.addMeal), icon: const Icon(Icons.playlist_add_rounded, size: 20), label: const Text('Add meal for all')),
        FilledButton.icon(onPressed: () => _add(context), icon: const Icon(Icons.add_rounded, size: 20), label: const Text('Add meal')),
      ],
    );

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compactActions)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      recordCount,
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      actionButtons,
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: recordCount),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      actionButtons,
                    ],
                  ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _Filters(members: data.members, selectedMemberId: selectedMemberId, selectedDate: selectedDate),
              ],
            ),
          ),
          Divider(height: 1, color: colors.dividerColor.withValues(alpha: 0.3)),
          if (entries.isEmpty)
            _EmptyState(filtered: selectedMemberId != null || selectedDate != null)
          else
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.dividerColor.withValues(alpha: 0.3)),
              _EntryRow(
                entry: entries[i],
                memberName: data.memberName(entries[i].memberId),
                mealRate: data.mealRate,
                showMember: selectedMemberId == null,
                onEdit: () => _edit(context, entries[i]),
                onDelete: () => _confirmDelete(context, entries[i]),
              ),
            ],
        ],
      ),
    );
  }
}

/// Member dropdown + date picker filter row, with clear affordances.
class _Filters extends StatelessWidget {
  const _Filters({required this.members, required this.selectedMemberId, required this.selectedDate});

  final List<MealMemberEntity> members;
  final String? selectedMemberId;
  final DateTime? selectedDate;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: selectedDate ?? now, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 1, now.month, now.day));
    if (picked != null && context.mounted) {
      context.read<MealAdminBloc>().add(MealAdminEvent.selectDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final bloc = context.read<MealAdminBloc>();

    return Row(
      children: [
        // Member filter.
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedMemberId,
                isExpanded: true,
                icon: Icon(Icons.expand_more_rounded, color: colors.textHintColor),
                hint: Text(
                  'All members',
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    child: Text(
                      'All members',
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                    ),
                  ),
                  for (final m in members)
                    DropdownMenuItem<String?>(
                      value: m.id,
                      child: Text(
                        m.name,
                        style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                      ),
                    ),
                ],
                onChanged: (v) => bloc.add(MealAdminEvent.selectMember(v)),
              ),
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        // Date filter.
        Expanded(
          child: InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: colors.backgroundColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      selectedDate == null ? 'All dates' : MealFormatters.dayLabel(selectedDate!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: selectedDate == null ? colors.textSecondaryColor : colors.textPrimaryColor),
                    ),
                  ),
                  if (selectedDate != null)
                    InkWell(
                      onTap: () => bloc.add(const MealAdminEvent.selectDate(null)),
                      child: Icon(Icons.close_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.memberName, required this.mealRate, required this.showMember, required this.onEdit, required this.onDelete});

  final MemberMealEntity entry;
  final String memberName;
  final double mealRate;
  final bool showMember;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final showActionMenu = ResponsiveHelper.isMobile(context) || ResponsiveHelper.isSmallTab(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showMember)
                  Text(
                    memberName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                  ),
                Text(
                  MealFormatters.dayLabel(entry.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(
                    fontSize: showMember ? Dimensions.fontSizeSmall : Dimensions.fontSizeDefault,
                    color: showMember ? colors.textSecondaryColor : colors.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Mini(label: 'B', value: entry.breakfast, accent: colors.warningColor),
                _Mini(label: 'L', value: entry.lunch, accent: colors.primaryColor),
                _Mini(label: 'D', value: entry.dinner, accent: colors.infoColor),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${MealFormatters.count(entry.total)} meals',
                  style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                ),
                Text(
                  DashboardFormatters.taka(entry.total * mealRate),
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                ),
              ],
            ),
          ),
          // Edit / delete actions.
          if (showActionMenu)
            PopupMenuButton<_MealAction>(
              tooltip: 'Options',
              icon: Icon(Icons.more_vert_rounded, color: colors.textSecondaryColor),
              onSelected: (action) {
                switch (action) {
                  case _MealAction.edit:
                    onEdit();
                  case _MealAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _MealAction.edit,
                  child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.edit_rounded), title: Text('Edit')),
                ),
                PopupMenuItem(
                  value: _MealAction.delete,
                  child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(Icons.delete_outline_rounded), title: Text('Delete')),
                ),
              ],
            )
          else ...[
            IconButton(
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: Icon(Icons.edit_rounded, size: Dimensions.iconSizeDefault, color: colors.primaryColor),
            ),
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, size: Dimensions.iconSizeDefault, color: colors.errorColor),
            ),
          ],
        ],
      ),
    );
  }
}

enum _MealAction { edit, delete }

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
      child: Column(
        children: [
          Icon(Icons.no_meals_rounded, size: Dimensions.iconSizeLarge, color: colors.textHintColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            filtered ? 'No meals match these filters.' : 'No meals recorded yet. Tap "Add meal" to start.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.accent});
  final String label;
  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = value == 0;
    final colors = context.customThemeColors;
    final color = muted ? colors.textHintColor : accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
      child: Tooltip(
        message: '$label · ${MealFormatters.count(value)}',
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: muted ? 0.06 : 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            MealFormatters.count(value),
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: color),
          ),
        ),
      ),
    );
  }
}

/// Shared rounded card container matching the meal screen's surface style.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: padding ?? const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

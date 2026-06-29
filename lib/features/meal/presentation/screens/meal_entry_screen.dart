import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/stat_card.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_bloc.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_state.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/apply_to_all_card.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/member_meal_form_sheet.dart';

/// Admin page to add a meal for every member at once for a chosen day, with
/// per-member edit / delete. Responsive across phone / tablet / desktop.
class MealEntryScreen extends StatelessWidget {
  const MealEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MealAdminBloc>(create: (_) => getIt<MealAdminBloc>()..add(const MealAdminEvent.load()), child: const _MealEntryView());
  }
}

class _MealEntryView extends StatefulWidget {
  const _MealEntryView();

  @override
  State<_MealEntryView> createState() => _MealEntryViewState();
}

class _MealEntryViewState extends State<_MealEntryView> {
  DateTime _date = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(_date.year - 1), lastDate: DateTime(_date.year + 1));
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add Meal'),
        actions: [
          TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_today_rounded, size: 18), label: Text(MealFormatters.dayLabel(_date))),
          const SizedBox(width: Dimensions.paddingSizeSmall),
        ],
      ),
      body: BlocConsumer<MealAdminBloc, MealAdminState>(
        listener: (context, state) {
          state.maybeWhen(error: (message) => context.showErrorSnackBar(message), orElse: () {});
        },
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
            error: (message) => _ErrorView(message: message),
            loaded: (data, _, _) => _Body(data: data, date: _date),
            orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
          );
        },
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton.icon(onPressed: () => context.read<MealAdminBloc>().add(const MealAdminEvent.load()), icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.date});
  final MealAdminEntity data;
  final DateTime date;

  /// This member's record on [date], or null if none recorded.
  MemberMealEntity? _recordFor(String memberId) {
    for (final e in data.entries) {
      if (e.memberId == memberId && e.sameDay(date)) return e;
    }
    return null;
  }

  double get _totalMeals {
    var sum = 0.0;
    for (final m in data.members) {
      sum += _recordFor(m.id)?.total ?? 0;
    }
    return sum;
  }

  int get _withMeals => data.members.where((m) => (_recordFor(m.id)?.total ?? 0) > 0).length;

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    return [
      _Stat('Members', '${data.members.length}', Icons.groups_rounded, c.primaryColor),
      _Stat('With meals', '$_withMeals', Icons.how_to_reg_rounded, c.successColor),
      _Stat('Total meals', MealFormatters.count(_totalMeals), Icons.restaurant_rounded, c.secondaryColor),
      _Stat('Total cost', DashboardFormatters.taka(_totalMeals * data.mealRate), Icons.payments_rounded, c.infoColor),
    ];
  }

  void _applyAll(BuildContext context, double b, double l, double d) {
    context.read<MealAdminBloc>().add(MealAdminEvent.addForAll(date: date, breakfast: b, lunch: l, dinner: d));
    context.showSuccessSnackBar('Meal applied to all ${data.members.length} members');
  }

  Future<void> _edit(BuildContext context, MealMemberEntity member) async {
    final bloc = context.read<MealAdminBloc>();
    final result = await showMemberMealForm(context, members: data.members, existing: _recordFor(member.id), presetMemberId: member.id, presetDate: date);
    if (result != null) {
      bloc.add(MealAdminEvent.save(memberId: result.memberId, date: result.date, breakfast: result.breakfast, lunch: result.lunch, dinner: result.dinner));
    }
  }

  Future<void> _delete(BuildContext context, MealMemberEntity member) async {
    final bloc = context.read<MealAdminBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal'),
        content: Text("Clear ${member.name}'s meal for ${MealFormatters.dayLabel(date)}?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(MealAdminEvent.delete(memberId: member.id, date: date));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;

                final applyCard = AnimatedEntrance(
                  child: ApplyToAllCard(memberCount: data.members.length, onApply: (b, l, d) => _applyAll(context, b, l, d)),
                );

                final membersColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(title: 'Members', icon: Icons.people_alt_rounded),
                    for (var i = 0; i < data.members.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: AnimatedEntrance(
                          delay: Duration(milliseconds: 40 * i),
                          child: _MemberRow(
                            index: i + 1,
                            name: data.members[i].name,
                            record: _recordFor(data.members[i].id),
                            mealRate: data.mealRate,
                            onEdit: () => _edit(context, data.members[i]),
                            onDelete: () => _delete(context, data.members[i]),
                          ),
                        ),
                      ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryGrid(stats: _summary(context)),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SectionTitle(title: 'Bulk entry', icon: Icons.edit_calendar_rounded),
                                applyCard,
                              ],
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeLarge),
                          Expanded(flex: 3, child: membersColumn),
                        ],
                      )
                    else ...[
                      const SectionTitle(title: 'Bulk entry', icon: Icons.edit_calendar_rounded),
                      applyCard,
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      membersColumn,
                    ],
                    SizedBox(height: context.bottomPadding),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One member's row for the selected day, with edit / delete actions.
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.index, required this.name, required this.record, required this.mealRate, required this.onEdit, required this.onDelete});

  final int index;
  final String name;
  final MemberMealEntity? record;
  final double mealRate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final total = record?.total ?? 0;
    final hasMeal = total > 0;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
            child: Text(
              '$index',
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.primaryColor),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  hasMeal
                      ? '${MealFormatters.count(total)} meals · '
                            '${DashboardFormatters.taka(total * mealRate)}'
                      : 'No meal added',
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: hasMeal ? colors.textSecondaryColor : colors.textHintColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          _Badge(label: 'B', value: record?.breakfast ?? 0, accent: colors.warningColor),
          _Badge(label: 'L', value: record?.lunch ?? 0, accent: colors.primaryColor),
          _Badge(label: 'D', value: record?.dinner ?? 0, accent: colors.infoColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          IconButton(
            tooltip: 'Edit $name',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_rounded, size: Dimensions.iconSizeDefault, color: colors.infoColor),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete $name',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, size: Dimensions.iconSizeDefault, color: colors.errorColor),
            onPressed: hasMeal ? onDelete : null,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value, required this.accent});
  final String label;
  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final muted = value == 0;
    final color = muted ? colors.textHintColor : accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: '$label · ${MealFormatters.count(value)}',
        child: Container(
          width: 30,
          height: 30,
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 140,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return AnimatedEntrance(
          delay: Duration(milliseconds: 50 * index),
          child: StatCard(label: stat.label, value: stat.value, icon: stat.icon, accent: stat.accent),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.accent);
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

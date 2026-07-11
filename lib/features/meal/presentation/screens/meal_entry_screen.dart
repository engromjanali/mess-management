import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
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
  MealMutationEntity? _lastMutation;

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
      ),
      body: BlocConsumer<MealAdminBloc, MealAdminState>(
        listener: (context, state) {
          state.maybeWhen(
            loaded: (data, _, _) {
              final mutation = data.mutation;
              if (mutation != null && !identical(_lastMutation, mutation)) {
                _lastMutation = mutation;
                context.showSuccessSnackBar(_mutationMessage(mutation));
              }
            },
            error: (message) => context.showErrorSnackBar(message),
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
            error: (message) => _ErrorView(message: message),
            loaded: (data, _, _) => _Body(data: data, date: _date, onPickDate: _pickDate),
            orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
          );
        },
      ),
    );
  }

  String _mutationMessage(MealMutationEntity mutation) {
    if (mutation.createdCount > 0 && mutation.updatedCount > 0) return 'Meal saved for ${mutation.createdCount} and updated for ${mutation.updatedCount} members';
    if (mutation.updatedCount > 0) return 'Meal updated for ${mutation.updatedCount} members';
    return 'Meal saved for ${mutation.createdCount} members';
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

class _Body extends StatefulWidget {
  const _Body({required this.data, required this.date, required this.onPickDate});
  final MealAdminEntity data;
  final DateTime date;
  final VoidCallback onPickDate;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  double _breakfast = 0;
  double _lunch = 1;
  double _dinner = 1;
  final Map<String, MemberMealEntity> _drafts = {};

  @override
  void didUpdateWidget(covariant _Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date.year != widget.date.year || oldWidget.date.month != widget.date.month || oldWidget.date.day != widget.date.day) {
      _drafts.clear();
    }
  }

  /// This member's record on [date], or null if none recorded.
  MemberMealEntity? _recordFor(String memberId) {
    for (final e in widget.data.entries) {
      if (e.memberId == memberId && e.sameDay(widget.date)) return e;
    }
    return null;
  }

  MemberMealEntity? _mealFor(String memberId) => _drafts[memberId] ?? _recordFor(memberId);

  void _applyToAll(BuildContext context) {
    setState(() {
      for (final member in widget.data.members) {
        _drafts[member.id] = MemberMealEntity(memberId: member.id, date: widget.date, breakfast: _breakfast, lunch: _lunch, dinner: _dinner);
      }
    });
    context.showSuccessSnackBar('Meal applied to all members');
  }

  void _saveAll(BuildContext context) {
    final bloc = context.read<MealAdminBloc>();
    final bulk = _canSaveAsBulk;
    if (bulk) {
      bloc.add(MealAdminEvent.addForAll(date: widget.date, breakfast: _breakfast, lunch: _lunch, dinner: _dinner));
    } else {
      for (final meal in _drafts.values) {
        if (_recordFor(meal.memberId) == null) {
          bloc.add(MealAdminEvent.save(memberId: meal.memberId, date: widget.date, breakfast: meal.breakfast, lunch: meal.lunch, dinner: meal.dinner));
        } else {
          bloc.add(MealAdminEvent.update(memberId: meal.memberId, date: widget.date, breakfast: meal.breakfast, lunch: meal.lunch, dinner: meal.dinner));
        }
      }
    }
  }

  bool get _canSaveAsBulk {
    if (_drafts.length != widget.data.members.length) return false;
    for (final member in widget.data.members) {
      final meal = _drafts[member.id];
      if (meal == null) return false;
      if (meal.breakfast != _breakfast || meal.lunch != _lunch || meal.dinner != _dinner) return false;
    }
    return true;
  }

  Future<void> _edit(BuildContext context, MealMemberEntity member) async {
    final result = await showMemberMealForm(context, members: widget.data.members, existing: _mealFor(member.id), presetMemberId: member.id, presetDate: widget.date, mealOnlyEdit: true);
    if (result != null) {
      setState(() {
        _drafts[result.memberId] = MemberMealEntity(memberId: result.memberId, date: widget.date, breakfast: result.breakfast, lunch: result.lunch, dinner: result.dinner);
      });
    }
  }

  void _delete(BuildContext context, MealMemberEntity member) {
    setState(() {
      _drafts[member.id] = MemberMealEntity(memberId: member.id, date: widget.date);
    });
  }

  void _changeMeal(double breakfast, double lunch, double dinner) {
    setState(() {
      _breakfast = breakfast;
      _lunch = lunch;
      _dinner = dinner;
    });
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
                  child: ApplyToAllCard(memberCount: widget.data.members.length, breakfast: _breakfast, lunch: _lunch, dinner: _dinner, dateLabel: MealFormatters.dayLabel(widget.date), onChanged: _changeMeal, onApplyToAll: () => _applyToAll(context)),
                );

                final membersColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(title: 'Members', icon: Icons.people_alt_rounded),
                    for (var i = 0; i < widget.data.members.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                        child: AnimatedEntrance(
                          delay: Duration(milliseconds: 40 * i),
                          child: _MemberRow(
                            index: i + 1,
                            name: widget.data.members[i].name,
                            record: _mealFor(widget.data.members[i].id),
                            mealRate: widget.data.mealRate,
                            onEdit: () => _edit(context, widget.data.members[i]),
                            onDelete: () => _delete(context, widget.data.members[i]),
                          ),
                        ),
                      ),
                  ],
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedEntrance(child: _DateSelectorCard(date: widget.date, onTap: widget.onPickDate)),
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
                                const SectionTitle(title: 'Bulk set', icon: Icons.edit_calendar_rounded),
                                applyCard,
                              ],
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeLarge),
                          Expanded(flex: 3, child: membersColumn),
                        ],
                      )
                    else ...[
                      const SectionTitle(title: 'Bulk set', icon: Icons.edit_calendar_rounded),
                      applyCard,
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      membersColumn,
                    ],
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    _BottomSaveButton(onSave: _drafts.isEmpty ? null : () => _saveAll(context)),
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

class _BottomSaveButton extends StatelessWidget {
  const _BottomSaveButton({required this.onSave});
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final wide = ResponsiveHelper.isBigTab(context) || ResponsiveHelper.isDesktop(context);

    return Align(
      alignment: wide ? Alignment.centerRight : Alignment.center,
      child: SizedBox(
      width: wide ? 300 : double.infinity,
      height: Dimensions.buttonHeightLarge,
      child: ElevatedButton.icon(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge))),
        icon: const Icon(Icons.save_rounded),
        label: Text('Save', style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ),
      ),
    );
  }
}

class _DateSelectorCard extends StatelessWidget {
  const _DateSelectorCard({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                border: Border.all(color: colors.primaryColor.withValues(alpha: 0.25)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                    colors.infoColor.withValues(alpha: context.isDarkMode ? 0.14 : 0.06),
                  ],
                ),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _DateIcon(color: colors.primaryColor),
                            const SizedBox(width: Dimensions.paddingSizeDefault),
                            Expanded(child: _DateText(isToday: isToday, date: date)),
                          ],
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          label: const Text('Change date'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _DateIcon(color: colors.primaryColor),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        Expanded(child: _DateText(isToday: isToday, date: date)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          label: const Text('Change'),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _DateIcon extends StatelessWidget {
  const _DateIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
      child: Icon(Icons.calendar_month_rounded, color: color, size: Dimensions.iconSizeLarge),
    );
  }
}

class _DateText extends StatelessWidget {
  const _DateText({required this.isToday, required this.date});
  final bool isToday;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'Today meal entry' : 'Meal entry date',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          MealFormatters.dayLabel(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
        ),
      ],
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: colors.cardBackgroundColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _MemberIndex(index: index),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        Expanded(child: _MemberMealText(name: name, total: total, hasMeal: hasMeal)),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    Wrap(
                      spacing: Dimensions.paddingSizeExtraSmall,
                      runSpacing: Dimensions.paddingSizeExtraSmall,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 2,
                          children: [
                            _Badge(label: 'B', value: record?.breakfast ?? 0, accent: colors.warningColor),
                            _Badge(label: 'L', value: record?.lunch ?? 0, accent: colors.primaryColor),
                            _Badge(label: 'D', value: record?.dinner ?? 0, accent: colors.infoColor),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit $name',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.edit_rounded, size: Dimensions.iconSizeDefault, color: colors.infoColor),
                              onPressed: onEdit,
                            ),
                            IconButton(
                              tooltip: 'Clear $name',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.highlight_remove_sharp, size: Dimensions.iconSizeDefault, color: colors.errorColor),
                              onPressed: hasMeal ? onDelete : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    _MemberIndex(index: index),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(child: _MemberMealText(name: name, total: total, hasMeal: hasMeal,)),
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
                      tooltip: 'Clear $name',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.highlight_remove_sharp, size: Dimensions.iconSizeDefault, color: colors.errorColor),
                      onPressed: hasMeal ? onDelete : null,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _MemberIndex extends StatelessWidget {
  const _MemberIndex({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
      child: Text(
        '$index',
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.primaryColor),
      ),
    );
  }
}

class _MemberMealText extends StatelessWidget {
  const _MemberMealText({required this.name, required this.total, required this.hasMeal});
  final String name;
  final double total;
  final bool hasMeal;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Column(
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
              ? '${MealFormatters.count(total)} meals'
              : 'No meal added',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: hasMeal ? colors.textSecondaryColor : colors.textHintColor),
        ),
      ],
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

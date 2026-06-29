import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_stepper.dart';

/// Admin "set once, apply to everyone" card.
///
/// Holds local B/L/D values and stamps them onto all members for the selected
/// day in one action — the core business rule (add meal for all members at a
/// time, not one by one).
class ApplyToAllCard extends StatefulWidget {
  const ApplyToAllCard({required this.memberCount, required this.onApply, super.key});

  final int memberCount;
  final void Function(double breakfast, double lunch, double dinner) onApply;

  @override
  State<ApplyToAllCard> createState() => _ApplyToAllCardState();
}

class _ApplyToAllCardState extends State<ApplyToAllCard> {
  double _breakfast = 0;
  double _lunch = 1;
  double _dinner = 1;

  double get _total => _breakfast + _lunch + _dinner;

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.22 : 0.10),
            colors.secondaryColor.withValues(alpha: context.isDarkMode ? 0.16 : 0.07),
          ],
        ),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(Icons.groups_2_rounded, color: colors.primaryColor, size: Dimensions.iconSizeDefault),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add meal for everyone',
                      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
                    ),
                    Text(
                      'Applies to all ${widget.memberCount} members at once',
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _StepRow(icon: Icons.free_breakfast_rounded, label: 'Breakfast', accent: colors.warningColor, value: _breakfast, onChanged: (v) => setState(() => _breakfast = v)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _StepRow(icon: Icons.lunch_dining_rounded, label: 'Lunch', accent: colors.primaryColor, value: _lunch, onChanged: (v) => setState(() => _lunch = v)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _StepRow(icon: Icons.dinner_dining_rounded, label: 'Dinner', accent: colors.infoColor, value: _dinner, onChanged: (v) => setState(() => _dinner = v)),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          SizedBox(
            height: Dimensions.buttonHeightLarge,
            child: ElevatedButton.icon(
              onPressed: _total == 0 ? null : () => widget.onApply(_breakfast, _lunch, _dinner),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge))),
              icon: const Icon(Icons.done_all_rounded),
              label: Text('Apply ${_fmt(_total)} meals to all', style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.icon, required this.label, required this.accent, required this.value, required this.onChanged});

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
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
          ),
        ),
        MealStepper(value: value, onChanged: onChanged, accent: accent),
      ],
    );
  }
}

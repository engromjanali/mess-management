import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// A compact, accessible +/- stepper for a single meal count.
///
/// Steps in 0.5 increments between [min] and [max]; the buttons disable at the
/// bounds. The [accent] colours the value chip so it reads against the row.
class MealStepper extends StatelessWidget {
  const MealStepper({required this.value, required this.onChanged, required this.accent, this.step = 0.5, this.min = 0, this.max = 3, super.key});

  final double value;
  final ValueChanged<double> onChanged;
  final Color accent;
  final double step;
  final double min;
  final double max;

  String get _label => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(icon: Icons.remove_rounded, enabled: canDecrement, accent: accent, onTap: () => onChanged((value - step).clamp(min, max))),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: Text(
            _label,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
        ),
        _RoundButton(icon: Icons.add_rounded, enabled: canIncrement, accent: accent, onTap: () => onChanged((value + step).clamp(min, max))),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.enabled, required this.accent, required this.onTap});

  final IconData icon;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final fg = enabled ? accent : colors.textHintColor;

    return Material(
      color: enabled ? accent.withValues(alpha: 0.12) : colors.borderColor.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Icon(icon, size: Dimensions.iconSizeDefault, color: fg),
        ),
      ),
    );
  }
}

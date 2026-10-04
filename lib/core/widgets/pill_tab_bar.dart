import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// One tab of a [PillTabBar].
class PillTab<T> {
  const PillTab({required this.value, required this.label});

  final T value;
  final String label;
}

/// Common tab menu: a horizontally scrollable row of rounded pills, the
/// selected one filled with the primary color (e.g. Membership, Cost).
class PillTabBar<T> extends StatelessWidget {
  const PillTabBar({required this.tabs, required this.selected, required this.onChanged, super.key});

  final List<PillTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final tab in tabs) ...[
                if (tab != tabs.first) const SizedBox(width: Dimensions.paddingSizeDefault),
                _PillTabItem(label: tab.label, selected: tab.value == selected, onTap: () => onChanged(tab.value)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTabItem extends StatelessWidget {
  const _PillTabItem({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: selected ? colors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
          child: Text(label, maxLines: 1, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: selected ? Theme.of(context).colorScheme.onPrimary : colors.textPrimaryColor)),
        ),
      ),
    );
  }
}

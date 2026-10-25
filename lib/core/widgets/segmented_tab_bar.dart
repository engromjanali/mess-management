import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/widgets/pill_tab_bar.dart';

class SegmentedTabBar<T> extends StatefulWidget {
  const SegmentedTabBar({required this.tabs, required this.selected, required this.onChanged, super.key}) : assert(tabs.length >= 2);

  final List<PillTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  State<SegmentedTabBar<T>> createState() => _SegmentedTabBarState<T>();
}

class _SegmentedTabBarState<T> extends State<SegmentedTabBar<T>> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final selectedIndex = widget.tabs.indexWhere((tab) => tab.value == widget.selected);
    const outerPadding = 6.0;
    const tabSpacing = Dimensions.paddingSizeSmall;
    const duration = Duration(milliseconds: 320);
    const curve = Curves.easeOutCubic;
    final height = math.max(48.0, MediaQuery.textScalerOf(context).scale(Dimensions.fontSizeDefault) * 1.4 + 24);
    final borderRadius = BorderRadius.circular(Dimensions.radiusLarge);
    var labelWidth = 0.0;
    for (final tab in widget.tabs) {
      final painter = TextPainter(
        text: TextSpan(text: tab.label, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      labelWidth = math.max(labelWidth, painter.width);
      painter.dispose();
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
      width: (labelWidth + Dimensions.paddingSizeSmall * 2).ceilToDouble() * widget.tabs.length + outerPadding * 2 + tabSpacing * (widget.tabs.length - 1),
      height: height,
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: borderRadius,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = math.max(0.0, constraints.maxWidth - outerPadding * 2 - tabSpacing * (widget.tabs.length - 1)) / widget.tabs.length;
          return Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositionedDirectional(
                  duration: duration,
                  curve: curve,
                  start: outerPadding + (segmentWidth + tabSpacing) * selectedIndex,
                  top: outerPadding,
                  width: segmentWidth,
                  height: height - outerPadding * 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.primaryColor,
                      borderRadius: borderRadius,
                      boxShadow: [BoxShadow(color: colors.primaryColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(outerPadding),
                child: Row(
                  spacing: tabSpacing,
                  children: [
                    for (var index = 0; index < widget.tabs.length; index++)
                      Expanded(
                        child: Semantics(
                          selected: index == selectedIndex,
                          button: true,
                          child: Material(
                            color: index == selectedIndex ? Colors.transparent : colors.primaryColor.withValues(alpha: 0.15),
                            borderRadius: borderRadius,
                            child: InkWell(
                              borderRadius: borderRadius,
                              onHighlightChanged: (pressed) => setState(() => _pressedIndex = pressed ? index : null),
                              onTap: () { if (index != selectedIndex) widget.onChanged(widget.tabs[index].value); },
                              child: AnimatedScale(
                                scale: _pressedIndex == index ? 0.96 : 1,
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOut,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                                    child: AnimatedDefaultTextStyle(
                                      duration: duration,
                                      curve: curve,
                                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: index == selectedIndex ? context.theme.colorScheme.onPrimary : colors.primaryColor),
                                      child: Text(widget.tabs[index].label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

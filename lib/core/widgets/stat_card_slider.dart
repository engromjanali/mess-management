import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/widgets/stat_card.dart';

/// Prev/next arrow buttons that slide a stat row two cards per tap.
///
/// Listens to the given [controller] and enables/disables itself at the row's
/// bounds. [overlay] renders the buttons with an opaque surface fill so they
/// read on top of cards; [hideWhenDisabled] removes them entirely when the row
/// cannot scroll in either direction.
class StatRowScrollArrows extends StatefulWidget {
  const StatRowScrollArrows({required this.controller, required this.strideBuilder, this.overlay = false, this.hideWhenDisabled = false, super.key});

  final ScrollController controller;

  /// Per-card stride (card width + spacing) for the current viewport width.
  final double Function(double viewportWidth) strideBuilder;

  final bool overlay;
  final bool hideWhenDisabled;

  @override
  State<StatRowScrollArrows> createState() => _StatRowScrollArrowsState();
}

class _StatRowScrollArrowsState extends State<StatRowScrollArrows> {
  bool _lastBack = false;
  bool _lastForward = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant StatRowScrollArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    void refresh() {
      if (!mounted) return;
      final back = _canScrollBack;
      final forward = _canScrollForward;
      if (back == _lastBack && forward == _lastForward) return;
      setState(() {
        _lastBack = back;
        _lastForward = forward;
      });
    }

    // ScrollController fires during layout (position attach / first frame);
    // defer so we never call setState while the tree is building.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    } else {
      refresh();
    }
  }

  bool get _canScrollBack {
    if (!widget.controller.hasClients) return false;
    return widget.controller.position.pixels > 0;
  }

  bool get _canScrollForward {
    if (!widget.controller.hasClients) return false;
    final position = widget.controller.position;
    // maxScrollExtent is null until content dimensions are applied.
    return position.hasContentDimensions && position.pixels < position.maxScrollExtent;
  }

  void _scroll(int direction) {
    final controller = widget.controller;
    if (!controller.hasClients || !controller.position.hasContentDimensions) return;
    final stride = widget.strideBuilder(controller.position.viewportDimension);
    final target = (controller.offset + direction * stride * 2).clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideWhenDisabled && widget.controller.hasClients && widget.controller.position.hasContentDimensions && !_canScrollBack && !_canScrollForward) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrowButton(context, icon: Icons.chevron_left_rounded, enabled: _canScrollBack, direction: -1),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        _arrowButton(context, icon: Icons.chevron_right_rounded, enabled: _canScrollForward, direction: 1),
      ],
    );
  }

  Widget _arrowButton(BuildContext context, {required IconData icon, required bool enabled, required int direction}) {
    final colors = context.customThemeColors;
    return Material(
      color: enabled ? (widget.overlay ? colors.surfaceColor : colors.primaryColor.withValues(alpha: 0.10)) : colors.textHintColor.withValues(alpha: 0.08),
      shape: CircleBorder(side: widget.overlay ? BorderSide(color: colors.borderColor) : BorderSide.none),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? () => _scroll(direction) : null,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: Dimensions.iconSizeSmall + 2, color: enabled ? colors.primaryColor : colors.textHintColor),
        ),
      ),
    );
  }
}

/// Horizontally slidable single row of [StatCard]s with prev/next arrow
/// controls (two cards per tap) — the shared behaviour of the home mess
/// section, reused by every summary/stat grid.
///
/// Card width adapts to the viewport: compact devices scale between
/// [compactMinCardWidth] and [compactMaxCardWidth]; wider layouts pack cards
/// exactly like the width-adaptive grid this replaces (see [strideFor]).
class StatCardSlider extends StatefulWidget {
  const StatCardSlider({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.maxCardWidth = 230,
    this.compactMinCardWidth = 148,
    this.compactMaxCardWidth = 210,
    this.regularExtent = 150,
    this.padding = EdgeInsets.zero,
    this.clipBehavior = Clip.hardEdge,
    this.overlayArrows = true,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Pass the screen's own controller to drive [StatRowScrollArrows] placed in
  /// a section header; leave null to use an internal one.
  final ScrollController? controller;

  final double maxCardWidth;
  final double compactMinCardWidth;
  final double compactMaxCardWidth;
  final double regularExtent;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;

  /// Overlay arrow buttons pinned to the row's trailing edge. Turn off when a
  /// section header hosts [StatRowScrollArrows] for this row instead.
  final bool overlayArrows;

  /// Per-card stride (card width + spacing) for the given viewport width,
  /// mirroring this row's width logic so header arrows stay pixel-exact.
  static double strideFor(BuildContext context, double viewportWidth, {double compactMinCardWidth = 148, double compactMaxCardWidth = 210, double maxCardWidth = 230}) {
    const spacing = Dimensions.paddingSizeDefault;
    if (StatCard.isCompact(context)) {
      final cardWidth = (viewportWidth / 4.5).clamp(compactMinCardWidth, compactMaxCardWidth).toDouble();
      return cardWidth + spacing;
    }
    if (!viewportWidth.isFinite || viewportWidth <= 0) return maxCardWidth + spacing;
    final columns = math.max(1, (viewportWidth / (maxCardWidth + spacing)).ceil());
    return ((viewportWidth - spacing * (columns - 1)) / columns) + spacing;
  }

  @override
  State<StatCardSlider> createState() => _StatCardSliderState();
}

class _StatCardSliderState extends State<StatCardSlider> {
  ScrollController? _internalController;

  ScrollController get _controller => widget.controller ?? (_internalController ??= ScrollController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spacing = Dimensions.paddingSizeDefault;
    final compact = StatCard.isCompact(context);
    return Scrollbar(
      controller: _controller,
      thumbVisibility: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double cardWidth;
          if (compact) {
            cardWidth = (width / 4.5).clamp(widget.compactMinCardWidth, widget.compactMaxCardWidth).toDouble();
          } else if (width.isFinite && width > 0) {
            final columns = math.max(1, (width / (widget.maxCardWidth + spacing)).ceil());
            cardWidth = (width - spacing * (columns - 1)) / columns;
          } else {
            cardWidth = widget.maxCardWidth;
          }
          return SizedBox(
            height: StatCard.gridMainAxisExtent(context, cardWidth: cardWidth, regular: widget.regularExtent),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    clipBehavior: widget.clipBehavior,
                    padding: widget.padding,
                    itemCount: widget.itemCount,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: index == widget.itemCount - 1 ? 0 : spacing),
                      child: SizedBox(width: cardWidth, child: widget.itemBuilder(context, index)),
                    ),
                  ),
                ),
                if (widget.overlayArrows)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: StatRowScrollArrows(
                        controller: _controller,
                        strideBuilder: (_) => StatCardSlider.strideFor(context, width, compactMinCardWidth: widget.compactMinCardWidth, compactMaxCardWidth: widget.compactMaxCardWidth, maxCardWidth: widget.maxCardWidth),
                        overlay: true,
                        hideWhenDisabled: true,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

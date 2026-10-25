import 'dart:math' as math;
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';

class AppLoader extends StatefulWidget {
  const AppLoader({this.size = 96, super.key}) : assert(size > 0 && size < double.infinity);

  final double size;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Semantics(
      label: context.local.loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: FittedBox(
              child: SizedBox.square(
                dimension: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [colors.primaryColor.withValues(alpha: 0.18), colors.primaryColor.withValues(alpha: 0)])),
                    ),
                    RotationTransition(
                      turns: _controller,
                      child: CustomPaint(size: const Size.square(100), painter: _LoaderRingPainter(primary: colors.primaryColor, accent: colors.secondaryColor)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: colors.surfaceColor, shape: BoxShape.circle, border: Border.all(color: colors.primaryColor.withValues(alpha: 0.15)), boxShadow: [BoxShadow(color: colors.primaryColor.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 3))]),
                      child: const AppLogo(size: 54, shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({required this.isLoading, required this.child, super.key});

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Stack(
      children: [
        ExcludeSemantics(excluding: isLoading, child: ExcludeFocus(excluding: isLoading, child: AbsorbPointer(absorbing: isLoading, child: child))),
        if (isLoading) ...[
          Positioned.fill(child: ModalBarrier(dismissible: false, color: colors.backgroundColor.withValues(alpha: 0.82))),
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: colors.primaryColor.withValues(alpha: 0.12)), boxShadow: [BoxShadow(color: colors.shadowColor, blurRadius: 28, offset: const Offset(0, 8))]),
                  child: const AppLoader(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LoaderRingPainter extends CustomPainter {
  const _LoaderRingPainter({required this.primary, required this.accent});

  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = Rect.fromCircle(center: center, radius: size.width * 0.43);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, size.width * 0.43, paint..color = primary.withValues(alpha: 0.10));
    canvas.drawArc(ring, -math.pi / 2, math.pi * 0.85, false, paint..shader = SweepGradient(colors: [primary.withValues(alpha: 0.12), primary], endAngle: math.pi * 0.85, transform: const GradientRotation(-math.pi / 2)).createShader(ring));
    paint.shader = null;
    canvas.drawArc(ring, math.pi * 0.65, math.pi * 0.23, false, paint..color = accent);
    canvas.drawCircle(Offset(center.dx, center.dy - size.width * 0.43), 3.5, Paint()..color = primary);
  }

  @override
  bool shouldRepaint(_LoaderRingPainter oldDelegate) => primary != oldDelegate.primary || accent != oldDelegate.accent;
}

import 'package:flutter/material.dart';

/// Lightweight staggered entrance animation (fade + upward slide).
///
/// Wrap any widget with an increasing [delay] (commonly `index * 60ms`) to
/// produce a cascading reveal. Built on a single [AnimationController] so it is
/// cheap to use across a grid of cards.
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 450), this.offset = const Offset(0, 0.18), super.key});

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);

  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  late final Animation<Offset> _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

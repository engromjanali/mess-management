import 'dart:async';

import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/widgets/app_snackbar_content.dart';
import 'package:flutter/material.dart';

class AppDesktopToast extends StatefulWidget {
  const AppDesktopToast({required this.message, required this.icon, required this.color, required this.duration, required this.onDismiss, required this.onDispose, super.key});

  final String message;
  final IconData icon;
  final Color color;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback onDispose;
  static OverlayEntry? _entry;

  static void dismiss() {
    final entry = _entry;
    _entry = null;
    entry?.remove();
    entry?.dispose();
  }

  static void show(BuildContext context, {required String message, required IconData icon, required Color color, required Duration duration}) {
    dismiss();
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (context) => AppDesktopToast(
      message: message, icon: icon, color: color, duration: duration,
      onDismiss: () { if (identical(_entry, entry)) dismiss(); },
      onDispose: () { if (identical(_entry, entry)) _entry = null; },
    ));
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  State<AppDesktopToast> createState() => _AppDesktopToastState();
}

class _AppDesktopToastState extends State<AppDesktopToast> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _timer.cancel();
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final width = (media.size.width - media.padding.horizontal - 32).clamp(0.0, desktop ? 480.0 : 560.0);
    return Positioned(
      top: desktop ? media.padding.top + 16 : null,
      bottom: desktop ? null : media.viewInsets.bottom + media.viewPadding.bottom + 16,
      right: desktop ? media.padding.right + 16 : (media.size.width - width) / 2,
      width: width,
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: context.customThemeColors.surfaceColor,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: context.customThemeColors.borderColor)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: AppSnackbarContent(message: widget.message, icon: widget.icon, color: widget.color, onDismiss: widget.onDismiss),
          ),
        ),
      ),
    );
  }
}

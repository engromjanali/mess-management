import 'package:mess_pilot/config/theme/custom_theme_colors.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Accent used by [AppDialog] for its icon badge and primary action.
enum AppDialogTone { primary, info, success, warning, danger, neutral }

/// Visual treatment of an [AppDialogAction].
enum AppDialogActionStyle { primary, secondary, ghost, danger }

/// One button shown in the [AppDialog] footer.
class AppDialogAction {
  const AppDialogAction({required this.label, this.onPressed, this.icon, this.style = AppDialogActionStyle.primary, this.autofocus = false});

  final String label;
  final void Function(BuildContext context)? onPressed;
  final IconData? icon;
  final AppDialogActionStyle style;
  final bool autofocus;
}

/// The app-wide dialog shell.
///
/// Every dialog in the app should use this widget (through [showAppConfirmDialog]
/// or by building an [AppDialog] inside `showDialog`) so spacing, typography,
/// icons and actions look the same everywhere.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    this.message,
    this.icon,
    this.content,
    this.actions = const [],
    this.tone = AppDialogTone.primary,
    this.showCloseButton = true,
    this.maxWidth = 440,
    super.key,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? content;
  final List<AppDialogAction> actions;
  final AppDialogTone tone;
  final bool showCloseButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = _dialogColors(context);
    final media = MediaQuery.of(context);
    final accent = _accentColor(colors);
    final radius = BorderRadius.circular(Dimensions.radiusExtra2Large + 4);

    return Dialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeExtraLarge24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: colors.borderColor)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: media.size.height * 0.86),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeExtraLarge24,
                        showCloseButton ? Dimensions.paddingSizeExtraLarge24 + Dimensions.paddingSizeExtraLarge24 : Dimensions.paddingSizeExtraLarge24,
                        Dimensions.paddingSizeExtraLarge24,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (icon != null) ...[
                            Center(child: _DialogIconBadge(icon: icon!, accent: accent)),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                          ],
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: context.textTheme.titleLarge?.copyWith(fontSize: Dimensions.fontSizeOverLarge, fontWeight: AppTextStyles.bold, color: colors.textPrimaryColor, height: 1.25),
                          ),
                          if (message != null && message!.trim().isNotEmpty) ...[
                            const SizedBox(height: Dimensions.paddingSizeSmall + 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                              child: Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor, height: 1.5),
                              ),
                            ),
                          ],
                          if (content != null)
                            Padding(
                              padding: EdgeInsets.only(top: message == null ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeLarge),
                              child: content,
                            ),
                          if (actions.isEmpty) const SizedBox(height: Dimensions.paddingSizeExtraLarge24),
                        ],
                      ),
                    ),
                  ),
                ),
                if (actions.isNotEmpty) _DialogActions(actions: actions, accent: accent),
              ],
            ),
            if (showCloseButton) Positioned(top: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, child: _DialogCloseButton(onPressed: () => Navigator.of(context).maybePop())),
          ],
        ),
      ),
    );
  }

  Color _accentColor(CustomThemeColors colors) => switch (tone) {
    AppDialogTone.primary => colors.primaryColor,
    AppDialogTone.info => colors.infoColor,
    AppDialogTone.success => colors.successColor,
    AppDialogTone.warning => colors.warningColor,
    AppDialogTone.danger => colors.errorColor,
    AppDialogTone.neutral => colors.textSecondaryColor,
  };
}

/// Shows a confirmation dialog and resolves to `true` only when confirmed.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData? icon,
  AppDialogTone tone = AppDialogTone.primary,
  bool destructive = false,
  bool barrierDismissible = true,
  bool? showCloseButton,
  Widget? content,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppDialog(
      title: title,
      message: message,
      content: content,
      icon: icon ?? (destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
      tone: destructive ? AppDialogTone.danger : tone,
      showCloseButton: showCloseButton ?? barrierDismissible,
      actions: [
        AppDialogAction(
          label: cancelLabel ?? MaterialLocalizations.of(context).cancelButtonLabel,
          style: AppDialogActionStyle.secondary,
          onPressed: (dialogContext) => Navigator.of(dialogContext).pop(false),
        ),
        AppDialogAction(
          label: confirmLabel,
          style: destructive ? AppDialogActionStyle.danger : AppDialogActionStyle.primary,
          autofocus: !destructive,
          onPressed: (dialogContext) => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows an informational dialog with a single localized OK action.
Future<void> showAppAlertDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  AppDialogTone tone = AppDialogTone.info,
  String? okLabel,
  bool barrierDismissible = true,
  bool? showCloseButton,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppDialog(
      title: title,
      message: message,
      content: content,
      icon: icon ?? Icons.info_outline_rounded,
      tone: tone,
      showCloseButton: showCloseButton ?? barrierDismissible,
      actions: [
        AppDialogAction(
          label: okLabel ?? MaterialLocalizations.of(context).okButtonLabel,
          autofocus: true,
          onPressed: (dialogContext) => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

CustomThemeColors _dialogColors(BuildContext context) =>
    Theme.of(context).extension<CustomThemeColors>() ?? (Theme.of(context).brightness == Brightness.dark ? CustomThemeColors.dark() : CustomThemeColors.light());

class _DialogIconBadge extends StatelessWidget {
  const _DialogIconBadge({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge + 2),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.05)]),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: accent, size: Dimensions.iconSizeDefault + 4),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _dialogColors(context);
    return Tooltip(
      message: MaterialLocalizations.of(context).closeButtonTooltip,
      child: Material(
        color: colors.backgroundColor,
        shape: CircleBorder(side: BorderSide(color: colors.borderColor)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.close_rounded, size: Dimensions.iconSizeSmall + 3, color: colors.textSecondaryColor),
          ),
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.actions, required this.accent});

  final List<AppDialogAction> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final buttons = [for (final action in actions) _DialogActionButton(action: action, accent: accent)];
    final Widget content;
    if (buttons.length == 1) {
      content = SizedBox(width: double.infinity, child: buttons.first);
    } else if (buttons.length == 2) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: buttons.first), const SizedBox(width: Dimensions.paddingSizeDefault), Expanded(child: buttons.last)],
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buttons.length; index++) ...[
            SizedBox(width: double.infinity, child: buttons[index]),
            if (index != buttons.length - 1) const SizedBox(height: Dimensions.paddingSizeSmall + 2),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraLarge24, Dimensions.paddingSizeLarge, Dimensions.paddingSizeExtraLarge24, Dimensions.paddingSizeExtraLarge24),
      child: content,
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({required this.action, required this.accent});

  final AppDialogAction action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = _dialogColors(context);
    final labelStyle = AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, height: 1.2);
    final label = Text(action.label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: labelStyle);
    final child = action.icon == null
        ? label
        : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(action.icon, size: Dimensions.iconSizeSmall + 2), const SizedBox(width: Dimensions.paddingSizeSmall), Flexible(child: label)]);
    final onPressed = action.onPressed == null ? null : () => action.onPressed!(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge + 2));

    if (action.style == AppDialogActionStyle.primary || action.style == AppDialogActionStyle.danger) {
      final color = action.style == AppDialogActionStyle.danger ? colors.errorColor : accent;
      return Opacity(
        opacity: onPressed == null ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.18)!]),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge + 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: FilledButton(
            onPressed: onPressed,
            autofocus: action.autofocus,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
              shape: shape,
            ),
            child: child,
          ),
        ),
      );
    }

    if (action.style == AppDialogActionStyle.secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        autofocus: action.autofocus,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimaryColor,
          backgroundColor: colors.backgroundColor,
          side: BorderSide(color: colors.borderColor),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
          shape: shape,
        ),
        child: child,
      );
    }

    return TextButton(
      onPressed: onPressed,
      autofocus: action.autofocus,
      style: TextButton.styleFrom(
        foregroundColor: colors.textSecondaryColor,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
        shape: shape,
      ),
      child: child,
    );
  }
}

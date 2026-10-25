import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/errors/user_error_message.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.error, required this.onRetry, this.secondaryAction, super.key});

  final Object error;
  final VoidCallback onRetry;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final local = context.local;
    final message = userErrorMessage(error, local);
    final (title, icon) = message == local.connectionFailed
        ? (local.stateOfflineTitle, Icons.wifi_off_rounded)
        : message == local.requestTimedOut
        ? (local.stateTimeoutTitle, Icons.hourglass_empty_rounded)
        : message == local.serviceUnavailable
        ? (local.stateServiceTitle, Icons.cloud_off_rounded)
        : message == local.actionNotAllowed
        ? (local.stateAccessTitle, Icons.lock_outline_rounded)
        : message == local.signInAgain
        ? (local.stateSessionTitle, Icons.person_outline_rounded)
        : (local.stateErrorTitle, Icons.error_outline_rounded);
    return AppStateView(title: title, message: message, icon: icon, onAction: onRetry, actionLabel: local.tryAgain, secondaryAction: secondaryAction);
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({required this.title, required this.icon, this.message, super.key});

  final String title;
  final IconData icon;
  final String? message;

  @override
  Widget build(BuildContext context) => AppStateView(title: title, message: message ?? context.local.stateEmptyHint, icon: icon);
}

class AppStateView extends StatelessWidget {
  const AppStateView({required this.title, required this.message, required this.icon, this.onAction, this.actionLabel, this.actionIcon = Icons.refresh_rounded, this.secondaryAction, super.key});

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData actionIcon;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.borderColor.withValues(alpha: 0.65)),
              boxShadow: [BoxShadow(color: colors.shadowColor.withValues(alpha: 0.04), blurRadius: 32, offset: const Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 104,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.primaryColor.withValues(alpha: 0.10)))),
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primaryColor.withValues(alpha: 0.16), colors.primaryColor.withValues(alpha: 0.04)])),
                          child: Icon(icon, size: 36, color: colors.primaryColor),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: colors.surfaceColor, shape: BoxShape.circle, border: Border.all(color: colors.borderColor)),
                            child: Icon(onAction == null ? Icons.auto_awesome_rounded : Icons.refresh_rounded, size: 16, color: colors.secondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Semantics(header: true, child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: 22, color: colors.textPrimaryColor))),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: 14, height: 1.6, color: colors.textSecondaryColor)),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(backgroundColor: colors.primaryColor, foregroundColor: colors.surfaceColor, minimumSize: const Size(160, 48), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(actionIcon, size: 20), const SizedBox(width: 8), Flexible(child: Text(actionLabel!, textAlign: TextAlign.center))]),
                  ),
                ],
                if (secondaryAction != null) ...[const SizedBox(height: 12), secondaryAction!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

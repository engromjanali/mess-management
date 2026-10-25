import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/core/errors/user_error_message.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/widgets/app_snackbar_content.dart';
import 'package:clean_boilerplate/core/widgets/app_desktop_toast.dart';
import 'package:flutter/material.dart';

/// SnackBar status types
enum SnackBarStatus { error, success, alert, info }

/// Overlay extensions for snackbars, dialogs, and keyboard management
extension OverlayExtensions on BuildContext {
  /// Show custom styled snackbar/toast
  Future<void> _showCustomSnackBar(String? message, {SnackBarStatus status = SnackBarStatus.success, Duration duration = const Duration(seconds: 3)}) async {
    if (message == null || message.isEmpty) return;

    final (icon, color) = switch (status) {
      SnackBarStatus.error => (Icons.error_outline_rounded, customThemeColors.errorColor),
      SnackBarStatus.success => (Icons.check_circle_outline_rounded, customThemeColors.successColor),
      SnackBarStatus.info => (Icons.info_outline_rounded, customThemeColors.primaryColor),
      SnackBarStatus.alert => (Icons.warning_amber_rounded, customThemeColors.warningColor),
    };

    AppDesktopToast.dismiss();
    if (ResponsiveHelper.isDesktop(this)) {
      ScaffoldMessenger.of(this).hideCurrentSnackBar();
      AppDesktopToast.show(this, message: message, icon: icon, color: color, duration: duration);
      return;
    }

    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 4,
          duration: duration,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: customThemeColors.borderColor)),
          content: AppSnackbarContent(message: message, icon: icon, color: color),
          width: (screenWidth - 24).clamp(0.0, 560.0),
          behavior: SnackBarBehavior.floating,
          backgroundColor: customThemeColors.surfaceColor,
        ),
      );
  }

  /// Show error snackbar
  void showErrorSnackBar(Object? error, {Duration? duration}) {
    if (error == null || error is String && error.trim().isEmpty) return;
    _showCustomSnackBar(userErrorMessage(error, local), status: SnackBarStatus.error, duration: duration ?? const Duration(seconds: 6));
  }

  /// Show success snackbar
  void showSuccessSnackBar(String? message, {Duration? duration}) {
    _showCustomSnackBar(message, duration: duration ?? const Duration(seconds: 3));
  }

  /// Show info snackbar
  void showInfoSnackBar(String? message, {Duration? duration}) {
    _showCustomSnackBar(message, status: SnackBarStatus.info, duration: duration ?? const Duration(seconds: 3));
  }

  /// Show alert/warning snackbar
  void showAlertSnackBar(String? message, {Duration? duration}) {
    _showCustomSnackBar(message, status: SnackBarStatus.alert, duration: duration ?? const Duration(seconds: 3));
  }

  /// Dismiss keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }

  /// Request focus
  void requestFocus(FocusNode node) {
    FocusScope.of(this).requestFocus(node);
  }

  /// Show custom dialog
  Future<T?> showCustomDialog<T>({required Widget child, bool barrierDismissible = true}) {
    return showDialog<T>(context: this, barrierDismissible: barrierDismissible, builder: (_) => child);
  }

  /// Show bottom sheet
  Future<T?> showCustomBottomSheet<T>({required Widget child, bool isDismissible = true, bool enableDrag = true, Color? backgroundColor}) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtra2Large))),
      builder: (_) => child,
    );
  }

  /// Presents an entry form responsively.
  ///
  /// * **Tablet / desktop** → a centered, width-capped [Dialog].
  /// * **Phone** → a scrollable bottom sheet with a drag handle.
  ///
  /// [child] should be the bare form content — this method supplies the
  /// surrounding chrome (handle, padding, scrolling, keyboard inset).
  Future<T?> showAdaptiveSheet<T>({required Widget child, bool isDismissible = true, double maxWidth = 480}) {
    final isWide = ResponsiveHelper.isDesktop(this) || ResponsiveHelper.isTab(this);
    final background = theme.scaffoldBackgroundColor;

    if (isWide) {
      return showDialog<T>(
        context: this,
        barrierDismissible: isDismissible,
        builder: (ctx) => Dialog(
          backgroundColor: background,
          insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(ctx).size.height * 0.9),
            child: SingleChildScrollView(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: child),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtra2Large))),
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge + media.viewPadding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                    decoration: BoxDecoration(color: customThemeColors.dividerColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

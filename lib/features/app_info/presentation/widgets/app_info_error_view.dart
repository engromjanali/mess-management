import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:flutter/material.dart';

/// A safe, localized error state with a retry action.
class AppInfoErrorView extends StatelessWidget {
  const AppInfoErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(error: message, onRetry: onRetry);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/cancel_account_deletion_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/request_account_deletion_usecase.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';

/// Delete account: the user confirms with their password and the account is
/// scheduled for deletion 60 days later (the backend records the request);
/// they're signed out. Signing in before then shows the date and a
/// "Keep account" button that cancels it.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduledFor = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user.deletionScheduledFor, orElse: () => null);
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.deleteAccount)),
      body: MainPageBody(
        title: context.local.deleteAccount,
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: scheduledFor == null ? const _DeleteForm() : _ScheduledView(scheduledFor: scheduledFor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Long local date, e.g. "3 December 2026".
String _longDate(BuildContext context, DateTime date) => DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(date);

class _DeleteForm extends StatefulWidget {
  const _DeleteForm();

  @override
  State<_DeleteForm> createState() => _DeleteFormState();
}

class _DeleteFormState extends State<_DeleteForm> {
  /// Reason codes sent to the backend (readable in Django admin).
  static const _reasons = ['not_using', 'left_mess', 'privacy', 'other'];

  final _passwordController = TextEditingController();
  String? _reason;
  bool _understood = false;
  bool _obscure = true;
  bool _submitting = false;
  String? _passwordError;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final points = [
      (Icons.person_off_outlined, context.local.deleteAccountPointProfile),
      (Icons.groups_outlined, context.local.deleteAccountPointMemberships),
      (Icons.receipt_long_outlined, context.local.deleteAccountPointRecords),
      (Icons.logout_rounded, context.local.deleteAccountPointSignOut),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          tint: colors.errorColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(context.local.deleteAccountTitle, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(context.local.deleteAccountIntro, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.local.deleteAccountWhatHappens, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              for (final (icon, text) in points)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: Dimensions.iconSizeSmall, color: colors.errorColor),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(child: Text(text, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textPrimaryColor))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.local.deleteAccountReasonLabel, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeSmall,
                children: [
                  for (final reason in _reasons)
                    ChoiceChip(
                      label: Text(_reasonLabel(context, reason)),
                      selected: _reason == reason,
                      onSelected: _submitting ? null : (selected) => setState(() => _reason = selected ? reason : null),
                    ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              TextField(
                controller: _passwordController,
                enabled: !_submitting,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: context.local.password,
                  helperText: context.local.enterPasswordToConfirm,
                  errorText: _passwordError,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                ),
                onChanged: (_) => setState(() => _passwordError = null),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              CheckboxListTile(
                value: _understood,
                onChanged: _submitting ? null : (value) => setState(() => _understood = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(context.local.deleteAccountUnderstand, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textPrimaryColor)),
              ),
              if (_error != null) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(_error!, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.errorColor)),
              ],
              const SizedBox(height: Dimensions.paddingSizeDefault),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: colors.errorColor, minimumSize: const Size.fromHeight(Dimensions.buttonHeightDefault)),
                onPressed: _understood && !_submitting ? _submit : null,
                icon: _submitting ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.delete_forever_rounded),
                label: Text(context.local.deleteAccount),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = context.local.enterPasswordToConfirm);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _passwordError = null;
    });
    final result = await getIt<RequestAccountDeletionUseCase>()(RequestAccountDeletionParams(password: password, reason: _reason));
    if (!mounted) return;

    DateTime? scheduledFor;
    Failure? failure;
    result.when(success: (success) => scheduledFor = success.data.toLocal(), failure: (error) => failure = error.error as Failure);
    if (failure != null) {
      final passwordError = failure is ServerFailure ? (failure as ServerFailure).fieldErrors['password'] : null;
      setState(() {
        _submitting = false;
        _passwordError = passwordError;
        _error = passwordError == null ? failure!.message : null;
      });
      return;
    }
    await _showScheduledAndSignOut(scheduledFor!);
  }

  /// Confirms the date, then signs the user out like a real deletion would.
  Future<void> _showScheduledAndSignOut(DateTime scheduledFor) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.event_busy_rounded, color: context.customThemeColors.errorColor),
        title: Text(context.local.deletionScheduledTitle),
        content: Text(context.local.deletionScheduledMessage(_longDate(context, scheduledFor))),
        actions: [FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(context.local.done))],
      ),
    );
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthEvent.logoutRequested());
    context.go(AppRoutes.getLoginRoute());
  }

  String _reasonLabel(BuildContext context, String reason) => switch (reason) {
    'not_using' => context.local.deleteReasonNotUsing,
    'left_mess' => context.local.deleteReasonLeftMess,
    'privacy' => context.local.deleteReasonPrivacy,
    _ => context.local.deleteReasonOther,
  };
}

/// Deletion already scheduled: the date and a button to keep the account.
class _ScheduledView extends StatefulWidget {
  const _ScheduledView({required this.scheduledFor});

  final DateTime scheduledFor;

  @override
  State<_ScheduledView> createState() => _ScheduledViewState();
}

class _ScheduledViewState extends State<_ScheduledView> {
  bool _keeping = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return _Panel(
      tint: colors.warningColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.event_busy_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.warningColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(context.local.deletionScheduledBanner(_longDate(context, widget.scheduledFor)), style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(context.local.keepAccountHint, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeightDefault)),
            onPressed: _keeping ? null : _keep,
            icon: _keeping ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_user_outlined),
            label: Text(context.local.keepAccount),
          ),
        ],
      ),
    );
  }

  /// Cancels the deletion, then reloads the profile so every screen sees it.
  Future<void> _keep() async {
    setState(() => _keeping = true);
    final authBloc = context.read<AuthBloc>();
    final result = await getIt<CancelAccountDeletionUseCase>()(const NoParams());
    if (!mounted) return;
    String? error;
    result.when(success: (_) {}, failure: (failure) => error = failure.error.toString());
    if (error != null) {
      setState(() => _keeping = false);
      context.showErrorSnackBar(error);
      return;
    }
    final user = await getIt<GetCurrentUserUseCase>()(const NoParams());
    if (!mounted) return;
    user.when(success: (success) => success.data == null ? null : authBloc.add(AuthEvent.userUpdated(success.data!)), failure: (_) {});
    context.showSuccessSnackBar(context.local.deletionCancelled);
    context.go(AppRoutes.profile);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.tint});

  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: tint?.withValues(alpha: 0.06) ?? colors.surfaceColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: tint?.withValues(alpha: 0.35) ?? colors.borderColor),
      ),
      child: child,
    );
  }
}

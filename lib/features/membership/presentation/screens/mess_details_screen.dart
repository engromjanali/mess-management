import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MessDetailsScreen extends StatefulWidget {
  const MessDetailsScreen({super.key});

  @override
  State<MessDetailsScreen> createState() => _MessDetailsScreenState();
}

class _MessDetailsScreenState extends State<MessDetailsScreen> {
  late final MembershipApiService _service;
  Map<String, dynamic>? _mess;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = MembershipApiService(getIt<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final mess = await _service.getMessDetails();
      if (mounted) setState(() => _mess = mess);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load mess details.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave mess?'),
        content: const Text('You will lose access to this mess. Your previous records will remain in history.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Leave mess')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.leaveMess();
      if (mounted) context.go(AppRoutes.joinMess);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not leave the mess. Managers must transfer responsibility first.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final mess = _mess;
    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Mess')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : mess == null
              ? Center(child: Text('No active mess found.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                                decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), border: Border.all(color: colors.borderColor)),
                                child: Column(
                                  children: [
                                    CircleAvatar(radius: 34, backgroundColor: colors.primaryColor.withValues(alpha: 0.12), child: Icon(Icons.home_work_rounded, color: colors.primaryColor, size: Dimensions.iconSizeLarge)),
                                    const SizedBox(height: Dimensions.paddingSizeDefault),
                                    Text(mess['name'] as String? ?? '', textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                                    if ((mess['address'] as String? ?? '').isNotEmpty) Text(mess['address'] as String, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: Dimensions.spaceLarge),
                              _MessInfo(label: 'Current season', value: mess['season_name'] as String? ?? 'Not available'),
                              _MessInfo(label: 'Members', value: '${mess['member_count'] ?? 0}'),
                              _MessInfo(label: 'Manager', value: mess['manager_name'] as String? ?? 'Not assigned'),
                              _MessInfo(label: 'Acting manager', value: mess['act_manager_name'] as String? ?? 'Not assigned'),
                              _MessInfo(label: 'Email', value: (mess['email'] as String? ?? '').isEmpty ? 'Not provided' : mess['email'] as String),
                              _MessInfo(label: 'Phone', value: (mess['phone'] as String? ?? '').isEmpty ? 'Not provided' : mess['phone'] as String),
                              if (mess['can_edit'] == true) ...[
                                const SizedBox(height: Dimensions.paddingSizeDefault),
                                FilledButton.icon(onPressed: () async { await context.push(AppRoutes.editMess); if (context.mounted) await _load(); }, icon: const Icon(Icons.edit_outlined), label: const Text('Edit mess details')),
                              ],
                              if (mess['can_transfer'] == true) ...[
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                OutlinedButton.icon(onPressed: () async { await context.push(AppRoutes.messLeadership); if (context.mounted) await _load(); }, icon: const Icon(Icons.manage_accounts_outlined), label: const Text('Transfer leadership')),
                              ],
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              OutlinedButton.icon(onPressed: _leave, icon: Icon(Icons.logout_rounded, color: colors.errorColor), label: Text('Leave mess', style: TextStyle(color: colors.errorColor))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _MessInfo extends StatelessWidget {
  const _MessInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor))),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: AppTextStyles.sfProRoundedSemiBold)),
        ],
      ),
    );
  }
}

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
                              _MessInfo(label: 'Email', value: (mess['email'] as String? ?? '').isEmpty ? 'Not provided' : mess['email'] as String),
                              _MessInfo(label: 'Phone', value: (mess['phone'] as String? ?? '').isEmpty ? 'Not provided' : mess['phone'] as String),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 700;
                                  final width = wide ? (constraints.maxWidth - Dimensions.paddingSizeDefault) / 2 : constraints.maxWidth;
                                  return Wrap(
                                    spacing: Dimensions.paddingSizeDefault,
                                    runSpacing: Dimensions.paddingSizeDefault,
                                    children: [
                                      SizedBox(
                                        width: width,
                                        child: _LeadershipCard(
                                          title: 'Manager',
                                          name: mess['manager_name'] as String? ?? 'Not assigned',
                                          email: mess['manager_email'] as String? ?? '',
                                          phone: mess['manager_phone'] as String? ?? '',
                                          icon: Icons.admin_panel_settings_outlined,
                                        ),
                                      ),
                                      SizedBox(
                                        width: width,
                                        child: _LeadershipCard(
                                          title: 'Acting manager',
                                          name: mess['act_manager_name'] as String? ?? 'Not assigned',
                                          email: mess['act_manager_email'] as String? ?? '',
                                          phone: mess['act_manager_phone'] as String? ?? '',
                                          icon: Icons.supervisor_account_outlined,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: Dimensions.paddingSizeDefault),
                              _MessLocationCard(address: mess['address'] as String? ?? ''),
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

class _MessLocationCard extends StatelessWidget {
  const _MessLocationCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge), border: Border.all(color: colors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(Icons.location_on_outlined, color: colors.primaryColor),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: Text('Mess location', style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(address.isEmpty ? 'Address not provided' : address, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor, height: 1.4)),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Container(
            height: 180,
            decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Dimensions.radiusDefault), border: Border.all(color: colors.borderColor)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: colors.primaryColor),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text('Google Maps preview', style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text('Map integration is not implemented yet', textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Maps location is not implemented yet.'))),
              icon: const Icon(Icons.map_rounded),
              label: const Text('View on Google Maps'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadershipCard extends StatelessWidget {
  const _LeadershipCard({required this.title, required this.name, required this.email, required this.phone, required this.icon});

  final String title;
  final String name;
  final String email;
  final String phone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge), border: Border.all(color: colors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(icon, color: colors.primaryColor),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _LeadershipLine(icon: Icons.email_outlined, value: email.isEmpty ? 'Email not provided' : email),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          _LeadershipLine(icon: Icons.phone_outlined, value: phone.isEmpty ? 'Phone not provided' : phone),
        ],
      ),
    );
  }
}

class _LeadershipLine extends StatelessWidget {
  const _LeadershipLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      children: [
        Icon(icon, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))),
      ],
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

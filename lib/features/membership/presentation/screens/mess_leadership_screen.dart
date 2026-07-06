import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:flutter/material.dart';

class MessLeadershipScreen extends StatefulWidget {
  const MessLeadershipScreen({super.key});

  @override
  State<MessLeadershipScreen> createState() => _MessLeadershipScreenState();
}

class _MessLeadershipScreenState extends State<MessLeadershipScreen> {
  late final MembershipApiService _service;
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _mess;
  String? _selectedUserId;
  String _role = 'act_manager';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = MembershipApiService(getIt<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_service.getMessDetails(), _service.getManagerMembers()]);
      if (mounted) {
        setState(() {
          _mess = results[0] as Map<String, dynamic>;
          _members = results[1] as List<Map<String, dynamic>>;
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load mess members.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _transfer() async {
    final userId = _selectedUserId;
    if (userId == null || _saving) return;
    final member = _members.where((item) => item['user_id'] == userId).firstOrNull;
    final roleName = _role == 'manager' ? 'manager' : 'acting manager';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_role == 'manager' ? 'Transfer manager role?' : 'Assign acting manager?'),
        content: Text('${member?['name'] ?? 'This member'} will become the $roleName. ${_role == 'manager' ? 'You will no longer be the primary manager.' : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _service.transferMessLeadership(userId: userId, role: _role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${member?['name'] ?? 'Member'} is now the $roleName.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not transfer mess leadership.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Mess leadership')),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Current leadership', style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text('Manager: ${_mess?['manager_name'] ?? 'Not assigned'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('Acting manager: ${_mess?['act_manager_name'] ?? 'Not assigned'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: Dimensions.spaceLarge),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(labelText: 'Leadership role'),
                          items: const [DropdownMenuItem(value: 'act_manager', child: Text('Acting manager')), DropdownMenuItem(value: 'manager', child: Text('Primary manager'))],
                          onChanged: (value) => setState(() => _role = value ?? 'act_manager'),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUserId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Select active member'),
                          items: _members.map((member) => DropdownMenuItem<String>(value: member['user_id'] as String, child: Text('${member['name'] ?? 'Member'} · ${member['email'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setState(() => _selectedUserId = value),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text('Only active members of this mess can receive leadership.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall)),
                        const SizedBox(height: Dimensions.spaceLarge),
                        FilledButton.icon(onPressed: _selectedUserId == null || _saving ? null : _transfer, icon: _saving ? const SizedBox(width: Dimensions.iconSizeSmall, height: Dimensions.iconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.swap_horiz_rounded), label: const Text('Transfer leadership')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

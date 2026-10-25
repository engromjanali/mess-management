import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/features/membership/data/membership_api_service.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_page_body.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/membership/domain/entities/mess_details_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MessLeadershipScreen extends StatefulWidget {
  const MessLeadershipScreen({super.key});

  @override
  State<MessLeadershipScreen> createState() => _MessLeadershipScreenState();
}

class _MessLeadershipScreenState extends State<MessLeadershipScreen> {
  late final MembershipApiService _service;
  List<Map<String, dynamic>> _members = [];
  MessDetailsEntity? _mess;
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
      final mess = await _service.getMessDetails();
      final members = await _service.getManagerMembers();
      if (mounted) {
        setState(() {
          _mess = mess;
          _members = members;
        });
      }
    } catch (error) {
      if (mounted) context.showErrorSnackBar(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _transfer() async {
    final membershipId = int.tryParse(_selectedUserId ?? '');
    if (membershipId == null || _saving) return;
    final member = _members.where((item) => item['membership_id'] == membershipId).firstOrNull;
    final roleName = _role == 'manager' ? context.local.roleManager : context.local.roleActingManager;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_role == 'manager' ? context.local.uiTransferManagerRole : context.local.uiAssignActingManager),
        content: Text('${context.local.uiLeadershipConfirm(member?['name'] ?? context.local.uiThisMember, roleName)} ${_role == 'manager' ? context.local.uiYouWillNoLongerBeThePrimaryManager : ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.local.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(context.local.confirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      final transferOwnership = _role == 'manager';
      if (transferOwnership) {
        await _service.transferOwnership(membershipId);
      } else {
        await _service.makeActingManager(membershipId);
      }
      if (!mounted) return;
      context.showSuccessSnackBar(context.local.leadershipUpdated);
      if (transferOwnership) {
        // Refresh the role after ownership changes.
        await context.read<AuthBloc>().refreshProfile();
        if (!mounted) return;
        context.go(AppRoutes.home);
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.transferLeadership)),
      body: MainPageBody(
        title: context.local.transferLeadership,
        child: _loading
          ? const Center(child: AppLoader())
          : AppPageScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(context.local.uiCurrentLeadership, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text('${context.local.roleManager}: ${_mess?.manager?.name ?? context.local.notAssigned}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('${context.local.roleActingManager}: ${_mess?.actingManager?.name ?? context.local.notAssigned}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: Dimensions.spaceLarge),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: InputDecoration(labelText: context.local.uiLeadershipRole),
                          items: [DropdownMenuItem(value: 'act_manager', child: Text(context.local.roleActingManager)), DropdownMenuItem(value: 'manager', child: Text(context.local.uiPrimaryManager))],
                          onChanged: (value) => setState(() => _role = value ?? 'act_manager'),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUserId,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: context.local.uiSelectActiveMember),
                          // The primary manager can't hand leadership to themselves.
                          items: _members.where((member) => member['role'] != 'manager').map((member) => DropdownMenuItem<String>(value: '${member['membership_id']}', child: Text('${member['name'] ?? context.local.roleMember} · ${member['email'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setState(() => _selectedUserId = value),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(context.local.uiOnlyActiveMembersOfThisMessCanReceiveLeadership, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall)),
                        const SizedBox(height: Dimensions.spaceLarge),
                        FilledButton.icon(onPressed: _selectedUserId == null || _saving ? null : _transfer, icon: _saving ? const SizedBox(width: Dimensions.iconSizeSmall, height: Dimensions.iconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.swap_horiz_rounded), label: Text(context.local.transferLeadership)),
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

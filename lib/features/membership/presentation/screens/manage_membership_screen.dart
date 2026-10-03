import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/helpers/date_converter.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/code_picker_widget.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/membership_status_entity.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/managed_member_tile.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_item_tile.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/my_membership_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ManageMembershipScreen extends StatefulWidget {
  const ManageMembershipScreen({super.key});

  @override
  State<ManageMembershipScreen> createState() => _ManageMembershipScreenState();
}

class _ManageMembershipScreenState extends State<ManageMembershipScreen> {
  final _emailController = TextEditingController();
  final _memberFocusNode = FocusNode();
  final _searchController = TextEditingController();
  late final MembershipApiService _service;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> _members = [];
  String _statusFilter = 'all';
  String _sort = 'newest';
  _ManagementSection _section = _ManagementSection.memberships;
  bool _loading = true;

  /// The user's own side: memberships, invitations received, requests sent.
  MembershipStatusEntity? _status;

  /// The user-side item whose action (switch, accept, …) is running, if any.
  String? _busyItem;
  bool _findingMember = false;
  Map<String, dynamic>? _selectedMember;
  String _dialCode = '+880';

  /// The member whose action (disable, promote, …) is running, if any.
  int? _busyMembershipId;

  /// The mess side shows for the manager / acting manager of the current membership.
  bool get _canManage => const {'manager', 'acting_manager'}.contains(_status?.current?.role);

  bool get _isPhoneQuery {
    final query = _emailController.text.trim();
    return query.isNotEmpty && RegExp(r'^\d+$').hasMatch(query);
  }

  @override
  void initState() {
    super.initState();
    _service = MembershipApiService(getIt<ApiClient>());
    _emailController.addListener(_refreshMemberField);
    _searchController.addListener(_refreshFilters);
    _load();
  }

  @override
  void dispose() {
    _emailController.removeListener(_refreshMemberField);
    _emailController.dispose();
    _memberFocusNode.dispose();
    _searchController.removeListener(_refreshFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final status = await _service.getStatus();
      final manage = const {'manager', 'acting_manager'}.contains(status.current?.role);
      // Only the current mess's manager can read the mess side.
      final admin = manage ? await Future.wait([_service.getManagerRequests(), _service.getManagerInvites(), _service.getManagerMembers(includeDisabled: true)]) : null;
      if (mounted) {
        setState(() {
          _status = status;
          _requests = admin?[0] ?? [];
          _invitations = admin?[1] ?? [];
          _members = admin?[2] ?? [];
          if (!manage && _section.isMessSide) _section = _ManagementSection.memberships;
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Runs a user-side action keyed [key] (row spinner meanwhile) and reports
  /// [success]; on failure shows the backend's reason.
  Future<bool> _runUserAction(String key, Future<void> Function() action, String success) async {
    setState(() => _busyItem = key);
    try {
      await action();
      if (mounted) context.showSuccessSnackBar(success);
      return true;
    } catch (e) {
      if (mounted) context.showErrorSnackBar(_errorMessage(e));
      return false;
    } finally {
      if (mounted) setState(() => _busyItem = null);
    }
  }

  /// After the current membership changed every screen must show the new
  /// mess and season: match the role view to it and start again from home.
  void _openCurrentMembership(String role) {
    context.read<RoleCubit>().setRole(const {'manager', 'acting_manager'}.contains(role) ? UserRole.admin : UserRole.user);
    context.go(AppRoutes.home);
  }

  Future<void> _switchTo(MembershipSummaryEntity membership) async {
    final switched = await _runUserAction('switch:${membership.membershipId}', () => _service.switchMembership(membership.membershipId), context.local.switchedMembership(membership.messName, membership.seasonName));
    if (switched && mounted) _openCurrentMembership(membership.role);
  }

  Future<void> _acceptInvite(InviteSummaryEntity invite) async {
    // Joining makes the new membership current.
    final joined = await _runUserAction('invite:${invite.id}', () => _service.joinInvite(invite.inviteCode), context.local.joinedMess(invite.messName));
    if (joined && mounted) _openCurrentMembership('member');
  }

  Future<void> _declineInvite(InviteSummaryEntity invite) async {
    if (await _runUserAction('invite:${invite.id}', () => _service.declineInvite(invite.inviteCode), context.local.inviteDeclined)) await _load();
  }

  Future<void> _cancelRequest(JoinRequestSummaryEntity request) async {
    if (await _runUserAction('request:${request.id}', () => _service.cancelJoinRequest(request.id), context.local.joinRequestCancelled)) await _load();
  }

  Future<void> _findMember() async {
    final value = _emailController.text.trim();
    final query = _isPhoneQuery ? '$_dialCode$value' : value;
    if (query.isEmpty) return;
    setState(() {
      _findingMember = true;
      _selectedMember = null;
    });
    try {
      final member = await _service.findMember(query);
      if (mounted) setState(() => _selectedMember = member);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member not found. Use an exact email address or phone number.')));
    } finally {
      if (mounted) setState(() => _findingMember = false);
    }
  }

  Future<void> _invite() async {
    final member = _selectedMember;
    if (member == null || member['available'] != true) return;
    try {
      final invite = await _service.createInvite(member['id'] as String);
      _emailController.clear();
      setState(() => _selectedMember = null);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.mark_email_read_rounded, color: context.customThemeColors.successColor, size: Dimensions.iconSizeExtraLarge),
          title: const Text('Invitation sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invitation sent to ${member['name']}. Only this account can use it.'),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _CopyValue(label: 'Invitation ID', value: '#${invite['id']}'),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _CopyValue(label: 'Invitation code', value: invite['invite_code'] as String),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Done'))],
        ),
      );
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send this invitation. The member may already belong to a mess.')));
    }
  }

  void _refreshFilters() {
    if (mounted) setState(() {});
  }

  void _refreshMemberField() {
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> get _visibleInvitations {
    final query = _searchController.text.trim().toLowerCase();
    final items = _invitations.where((invite) {
      final statusMatches = _statusFilter == 'all' || invite['status'] == _statusFilter;
      final textMatches = query.isEmpty || (invite['user_name'] as String? ?? '').toLowerCase().contains(query) || (invite['user_email'] as String? ?? '').toLowerCase().contains(query);
      return statusMatches && textMatches;
    }).toList();
    items.sort((a, b) {
      if (_sort == 'name') return (a['user_name'] as String? ?? '').toLowerCase().compareTo((b['user_name'] as String? ?? '').toLowerCase());
      final aDate = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sort == 'oldest' ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });
    return items;
  }

  Future<void> _revoke(int inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel invitation?'),
        content: Text('Invitation #$inviteId will no longer be usable.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Cancel invitation')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.revokeInvite(inviteId);
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not revoke this invitation.')));
    }
  }

  Future<void> _decide(int requestId, bool accept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(accept ? 'Approve join request?' : 'Cancel join request?'),
        content: Text(accept ? 'This member will be added to your mess.' : 'This join request will be rejected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(accept ? 'Approve' : 'Cancel request')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.decideRequest(requestId, accept);
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update this join request.')));
    }
  }

  /// The actions the signed-in [myRole] may take on [member]; the backend
  /// enforces the same rules.
  List<MemberAction> _actionsFor(Map<String, dynamic> member, {required String? myRole, required bool isMe}) {
    if (isMe || myRole == null) return const [];
    final role = member['role'] as String? ?? 'member';
    if (role == 'manager') return const [];
    if (member['disabled'] == true) return const [MemberAction.enable];
    return [
      if (myRole == 'manager') ...[
        if (role == 'acting_manager') MemberAction.removeActingManager else MemberAction.makeActingManager,
        MemberAction.makePrimaryManager,
      ],
      MemberAction.disable,
    ];
  }

  Future<void> _onMemberAction(Map<String, dynamic> member, MemberAction action) async {
    final local = context.local;
    final name = member['name'] as String? ?? '';
    final membershipId = member['membership_id'] as int;
    final isActing = member['role'] == 'acting_manager';
    final currentActing = _members.where((m) => m['role'] == 'acting_manager').firstOrNull;

    if (action != MemberAction.enable) {
      final (title, body, confirmLabel) = switch (action) {
        MemberAction.disable => (local.disableMemberTitle(name), [local.disableMemberConfirm, if (isActing) local.disableActingManagerNote].join(' '), local.disable),
        MemberAction.makeActingManager => (
          local.makeActingManagerTitle(name),
          [local.makeActingManagerConfirm, if (currentActing != null) local.replaceActingManagerNote(currentActing['name'] as String? ?? '')].join(' '),
          local.confirm,
        ),
        MemberAction.removeActingManager => (local.removeActingManagerTitle(name), local.removeActingManagerConfirm, local.remove),
        MemberAction.makePrimaryManager => (local.transferOwnershipTitle(name), local.transferOwnershipConfirm, local.transfer),
        MemberAction.enable => ('', '', ''),
      };
      final destructive = action == MemberAction.disable || action == MemberAction.makePrimaryManager;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(local.cancel)),
            FilledButton(
              style: destructive ? FilledButton.styleFrom(backgroundColor: context.customThemeColors.errorColor) : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      if (!(confirmed ?? false) || !mounted) return;
    }

    setState(() => _busyMembershipId = membershipId);
    try {
      final success = switch (action) {
        MemberAction.disable => local.memberDisabledSuccess(name),
        MemberAction.enable => local.memberEnabledSuccess(name),
        MemberAction.makeActingManager => local.actingManagerAssigned(name),
        MemberAction.removeActingManager => local.actingManagerRemoved(name),
        MemberAction.makePrimaryManager => local.ownershipTransferred(name),
      };
      await switch (action) {
        MemberAction.disable => _service.disableMember(membershipId),
        MemberAction.enable => _service.enableMember(membershipId),
        MemberAction.makeActingManager => _service.makeActingManager(membershipId),
        MemberAction.removeActingManager => _service.removeActingManager(membershipId),
        MemberAction.makePrimaryManager => _service.transferOwnership(membershipId),
      };
      if (!mounted) return;
      context.showSuccessSnackBar(success);
      if (action == MemberAction.makePrimaryManager) {
        // No longer the manager: drop to the member view.
        context.read<RoleCubit>().setRole(UserRole.user);
        context.go(AppRoutes.home);
        return;
      }
      // Keep the row's spinner until the list shows the change.
      final members = await _service.getManagerMembers(includeDisabled: true);
      if (mounted) setState(() => _members = members);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _busyMembershipId = null);
    }
  }

  /// The backend's reason when there is one.
  String _errorMessage(Object error) => switch (error) {
    ServerException(:final message) || NoInternetException(:final message) || RequestTimeoutException(:final message) || UnauthorizedException(:final message) => message,
    _ => 'Something went wrong. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final myUserId = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user.id, orElse: () => null);
    final myRole = _status?.current?.role;
    final idle = _busyItem == null;
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(
        leading: const HomeBackButton(),
        title: Text(context.local.membership),
      ),
      body: MainPageBody(
        title: context.local.membership,
        child: ListView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ManagementMenu(
                    section: _section,
                    canManage: _canManage,
                    counts: {
                      _ManagementSection.memberships: _status?.memberships.length ?? 0,
                      _ManagementSection.invitations: _status?.invites.length ?? 0,
                      _ManagementSection.requests: _status?.pendingRequests.length ?? 0,
                      _ManagementSection.members: _members.length,
                      _ManagementSection.messRequests: _requests.length,
                    },
                    onChanged: (section) => setState(() => _section = section),
                  ),
                  const SizedBox(height: Dimensions.spaceLarge),
                  if (_section == _ManagementSection.memberships)
                    _ManagePanel(
                      title: context.local.myMemberships,
                      icon: Icons.badge_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_loading && _status == null)
                            const Center(child: CircularProgressIndicator.adaptive())
                          else if ((_status?.memberships ?? const []).isEmpty)
                            Text(context.local.noMembershipsYet, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
                          else
                            for (final membership in _status!.memberships)
                              Padding(
                                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                child: MyMembershipTile(
                                  membership: membership,
                                  busy: _busyItem == 'switch:${membership.membershipId}',
                                  onSwitch: idle ? () => _switchTo(membership) : null,
                                ),
                              ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton.icon(onPressed: () => context.push(AppRoutes.joinMess), icon: const Icon(Icons.group_add_rounded), label: Text(context.local.joinMess)),
                          ),
                        ],
                      ),
                    )
                  else if (_section == _ManagementSection.invitations)
                    _ManagePanel(
                      title: context.local.invitations,
                      icon: Icons.mark_email_unread_rounded,
                      child: (_status?.invites ?? const []).isEmpty
                          ? Text(context.local.noInvitationsForYou, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
                          : Column(
                              children: [
                                for (final invite in _status!.invites)
                                  MessItemTile(
                                    messName: invite.messName,
                                    subtitle: context.local.inviteCode(invite.inviteCode),
                                    busy: _busyItem == 'invite:${invite.id}',
                                    actions: [
                                      TextButton(onPressed: idle ? () => _declineInvite(invite) : null, child: Text(context.local.decline)),
                                      FilledButton(onPressed: idle ? () => _acceptInvite(invite) : null, child: Text(context.local.accept)),
                                    ],
                                  ),
                              ],
                            ),
                    )
                  else if (_section == _ManagementSection.requests)
                    _ManagePanel(
                      title: context.local.joinRequests,
                      icon: Icons.outgoing_mail,
                      child: (_status?.pendingRequests ?? const []).isEmpty
                          ? Text(context.local.noJoinRequestsSent, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
                          : Column(
                              children: [
                                for (final request in _status!.pendingRequests)
                                  MessItemTile(
                                    messName: request.messName,
                                    subtitle: context.local.waitingForApproval,
                                    busy: _busyItem == 'request:${request.id}',
                                    actions: [TextButton(onPressed: idle ? () => _cancelRequest(request) : null, child: Text(context.local.cancel))],
                                  ),
                              ],
                            ),
                    )
                  else if (_section == _ManagementSection.messInvitations) ...[
                    _ManagePanel(
                    title: 'Invite a member',
                    icon: Icons.person_add_alt_1_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final field = TextField(controller: _emailController, focusNode: _memberFocusNode, keyboardType: TextInputType.emailAddress, onSubmitted: (_) => _findMember(), decoration: InputDecoration(labelText: 'Member email or phone', hintText: 'Enter exact account details', prefixIcon: _isPhoneQuery ? Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall), child: CodePickerWidget(onChanged: (code) => _dialCode = code.dialCode ?? _dialCode, initialSelection: _dialCode, favorite: [_dialCode], showDropDownButton: true, showFlagMain: true, dialogBackgroundColor: context.theme.scaffoldBackgroundColor)) : null));
                            final button = FilledButton.icon(onPressed: _findingMember ? null : _findMember, icon: _findingMember ? const SizedBox(width: Dimensions.iconSizeSmall, height: Dimensions.iconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded), label: const Text('Find member'));
                            if (constraints.maxWidth >= 560) return Row(children: [Expanded(child: field), const SizedBox(width: Dimensions.paddingSizeDefault), button]);
                            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [field, const SizedBox(height: Dimensions.paddingSizeDefault), button]);
                          },
                        ),
                        if (_selectedMember != null) ...[
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          _MemberPreview(
                            member: _selectedMember!,
                            onCancel: () => setState(() {
                              _selectedMember = null;
                              _emailController.clear();
                            }),
                            onSend: _invite,
                          ),
                        ],
                      ],
                    ),
                    ),
                    const SizedBox(height: Dimensions.spaceLarge),
                    _ManagePanel(
                    title: 'Invitation list',
                    icon: Icons.mail_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final search = TextField(controller: _searchController, decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), labelText: 'Search invitations'));
                            final status = DropdownButtonFormField<String>(
                              initialValue: _statusFilter,
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: const [DropdownMenuItem(value: 'all', child: Text('All')), DropdownMenuItem(value: 'pending', child: Text('Pending')), DropdownMenuItem(value: 'accepted', child: Text('Accepted')), DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')), DropdownMenuItem(value: 'expired', child: Text('Expired'))],
                              onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                            );
                            final sort = DropdownButtonFormField<String>(
                              initialValue: _sort,
                              decoration: const InputDecoration(labelText: 'Sort by'),
                              items: const [DropdownMenuItem(value: 'newest', child: Text('Newest')), DropdownMenuItem(value: 'oldest', child: Text('Oldest')), DropdownMenuItem(value: 'name', child: Text('Name'))],
                              onChanged: (value) => setState(() => _sort = value ?? 'newest'),
                            );
                            if (constraints.maxWidth >= 680) return Row(children: [Expanded(flex: 2, child: search), const SizedBox(width: Dimensions.paddingSizeDefault), Expanded(child: status), const SizedBox(width: Dimensions.paddingSizeDefault), Expanded(child: sort)]);
                            return Column(children: [search, const SizedBox(height: Dimensions.paddingSizeDefault), Row(children: [Expanded(child: status), const SizedBox(width: Dimensions.paddingSizeDefault), Expanded(child: sort)])]);
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        if (_loading)
                          const Center(child: CircularProgressIndicator.adaptive())
                        else if (_visibleInvitations.isEmpty)
                          Text('No invitations match these filters.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
                        else
                          for (final invite in _visibleInvitations) _InvitationTile(invite: invite, onRevoke: () => _revoke(invite['id'] as int)),
                      ],
                    ),
                    ),
                  ] else if (_section == _ManagementSection.messRequests)
                    _ManagePanel(
                    title: 'Pending join requests',
                    icon: Icons.group_add_outlined,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator.adaptive())
                        : _requests.isEmpty
                            ? Text('No pending requests.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
                            : Column(
                                children: [
                                  for (final request in _requests)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(request['user_name'] as String? ?? 'Member', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text(request['user_email'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      trailing: Wrap(
                                        spacing: Dimensions.paddingSizeExtraSmall,
                                        children: [
                                          IconButton(tooltip: 'Reject', onPressed: () => _decide(request['id'] as int, false), icon: Icon(Icons.close_rounded, color: colors.errorColor)),
                                          IconButton(tooltip: 'Accept', onPressed: () => _decide(request['id'] as int, true), icon: Icon(Icons.check_rounded, color: colors.successColor)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                    )
                  else
                    _ManagePanel(
                      title: 'Existing members',
                      icon: Icons.groups_rounded,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator.adaptive())
                          : _members.isEmpty
                              ? Text('No active members found.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
                              : Column(
                                  children: [
                                    for (var i = 0; i < _members.length; i++) ...[
                                      if (i > 0) Divider(height: 1, color: colors.dividerColor.withValues(alpha: 0.3)),
                                      Builder(
                                        builder: (context) {
                                          final member = _members[i];
                                          final isMe = member['id'] == myUserId;
                                          return ManagedMemberTile(
                                            name: member['name'] as String? ?? '',
                                            email: member['email'] as String? ?? '',
                                            phone: member['phone'] as String? ?? '',
                                            role: member['role'] as String? ?? 'member',
                                            disabled: member['disabled'] == true,
                                            isMe: isMe,
                                            actions: _actionsFor(member, myRole: myRole, isMe: isMe),
                                            busy: _busyMembershipId == member['membership_id'],
                                            // One action at a time.
                                            onAction: _busyMembershipId == null ? (action) => _onMemberAction(member, action) : null,
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                    ),
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

/// User side first (everyone), then the mess side (manager / acting manager).
enum _ManagementSection {
  memberships,
  invitations,
  requests,
  members,
  messInvitations,
  messRequests;

  bool get isMessSide => index >= _ManagementSection.members.index;

  String label(BuildContext context) => switch (this) {
    _ManagementSection.memberships => context.local.myMemberships,
    _ManagementSection.invitations => context.local.invitations,
    _ManagementSection.requests => context.local.joinRequests,
    _ManagementSection.members => context.local.members,
    _ManagementSection.messInvitations => context.local.messInvitations,
    _ManagementSection.messRequests => context.local.messJoinRequests,
  };
}

class _ManagementMenu extends StatelessWidget {
  const _ManagementMenu({required this.section, required this.canManage, required this.counts, required this.onChanged});

  final _ManagementSection section;
  final bool canManage;

  /// Shown as "Label (n)" for the sections that have one.
  final Map<_ManagementSection, int> counts;
  final ValueChanged<_ManagementSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final sections = _ManagementSection.values.where((s) => canManage || !s.isMessSide);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in sections) ...[
                if (item != sections.first) const SizedBox(width: Dimensions.paddingSizeDefault),
                _ManagementMenuItem(
                  label: counts[item] == null ? item.label(context) : '${item.label(context)} (${counts[item]})',
                  selected: section == item,
                  onTap: () => onChanged(item),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagementMenuItem extends StatelessWidget {
  const _ManagementMenuItem({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: selected ? colors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
          child: Text(label, maxLines: 1, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: selected ? Theme.of(context).colorScheme.onPrimary : colors.textPrimaryColor)),
        ),
      ),
    );
  }
}

class _ManagePanel extends StatelessWidget {
  const _ManagePanel({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), border: Border.all(color: colors.borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Icon(icon, color: colors.primaryColor), const SizedBox(width: Dimensions.paddingSizeSmall), Text(title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge))]), const SizedBox(height: Dimensions.paddingSizeLarge), child]),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({required this.invite, required this.onRevoke});

  final Map<String, dynamic> invite;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final invitationStatus = invite['status'] as String? ?? 'pending';
    final status = invitationStatus.isEmpty ? 'pending' : invitationStatus;
    final statusColor = switch (status) { 'accepted' => colors.successColor, 'expired' => colors.errorColor, _ => colors.warningColor };
    final expireAt = DateTime.tryParse(invite['expire_at'] as String? ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(border: Border.all(color: colors.borderColor), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: statusColor.withValues(alpha: 0.12), child: Icon(Icons.person_outline_rounded, color: statusColor)),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite['user_name'] as String? ?? 'Member', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold),
                Text(invite['user_email'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall)),
                Text('#${invite['id']} | ${expireAt == null ? 'No expiry date' : DateConverter.orderDateTime(expireAt.toLocal())}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall)),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
            child: Text(status[0].toUpperCase() + status.substring(1), style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: statusColor, fontSize: Dimensions.fontSizeSmall)),
          ),
          if (status == 'pending') IconButton(tooltip: 'Cancel invitation', onPressed: onRevoke, icon: Icon(Icons.cancel_outlined, color: colors.errorColor)),
        ],
      ),
    );
  }
}

class _MemberPreview extends StatelessWidget {
  const _MemberPreview({required this.member, required this.onCancel, required this.onSend});

  final Map<String, dynamic> member;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final available = member['available'] == true;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Dimensions.radiusLarge), border: Border.all(color: colors.primaryColor.withValues(alpha: 0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 26, backgroundColor: colors.primaryColor.withValues(alpha: 0.15), child: Icon(Icons.person_rounded, color: colors.primaryColor)),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'] as String? ?? 'Member', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                    Text(member['email'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
                    if ((member['phone'] as String? ?? '').isNotEmpty) Text(member['phone'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(available ? 'Available to invite' : 'Already connected to ${member['current_mess'] ?? 'another mess'}', style: AppTextStyles.sfProRoundedMedium.copyWith(color: available ? colors.successColor : colors.errorColor)),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: [
              OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
              FilledButton.icon(onPressed: available ? onSend : null, icon: const Icon(Icons.send_rounded), label: const Text('Send invitation')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyValue extends StatelessWidget {
  const _CopyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(color: colors.backgroundColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault), border: Border.all(color: colors.borderColor)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeExtraSmall)), SelectableText(value, maxLines: 1, style: AppTextStyles.sfProRoundedSemiBold)])),
          IconButton(
            tooltip: 'Copy $label',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

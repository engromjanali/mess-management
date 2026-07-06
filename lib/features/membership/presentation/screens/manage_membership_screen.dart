import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/date_converter.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/code_picker_widget.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  _ManagementSection _section = _ManagementSection.members;
  bool _loading = true;
  bool _findingMember = false;
  Map<String, dynamic>? _selectedMember;
  String _dialCode = '+880';

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
      final results = await Future.wait([_service.getManagerRequests(), _service.getManagerInvites(), _service.getManagerMembers()]);
      if (mounted) {
        setState(() {
          _requests = results[0];
          _invitations = results[1];
          _members = results[2];
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load join requests.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
        title: const Text('Manage members'),
      ),
      body: ListView(
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
                    requestCount: _requests.length,
                    memberCount: _members.length,
                    onChanged: (section) => setState(() => _section = section),
                  ),
                  const SizedBox(height: Dimensions.spaceLarge),
                  if (_section == _ManagementSection.invitations) ...[
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
                  ] else if (_section == _ManagementSection.requests)
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
                                    for (final member in _members)
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(child: Text((member['name'] as String? ?? '').trim().isEmpty ? 'M' : (member['name'] as String? ?? '').trim()[0].toUpperCase())),
                                        title: Text(member['name'] as String? ?? 'Member', maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(member['email'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if ((member['phone'] as String? ?? '').isNotEmpty) Text(member['phone'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                        trailing: Text((member['role'] as String? ?? '').isEmpty ? 'Member' : (member['role'] as String)[0].toUpperCase() + (member['role'] as String).substring(1), style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.primaryColor)),
                                      ),
                                  ],
                                ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ManagementSection { members, invitations, requests }

class _ManagementMenu extends StatelessWidget {
  const _ManagementMenu({required this.section, required this.requestCount, required this.memberCount, required this.onChanged});

  final _ManagementSection section;
  final int requestCount;
  final int memberCount;
  final ValueChanged<_ManagementSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ManagementMenuItem(label: 'Members ($memberCount)', selected: section == _ManagementSection.members, onTap: () => onChanged(_ManagementSection.members)),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              _ManagementMenuItem(label: 'Invitations', selected: section == _ManagementSection.invitations, onTap: () => onChanged(_ManagementSection.invitations)),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              _ManagementMenuItem(label: 'Join requests ($requestCount)', selected: section == _ManagementSection.requests, onTap: () => onChanged(_ManagementSection.requests)),
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

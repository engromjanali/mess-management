import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/membership_status_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MembershipGate extends StatelessWidget {
  const MembershipGate({required this.connectedChild, super.key});

  final Widget connectedChild;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MembershipCubit, MembershipState>(
      listener: (context, state) {
        if (state is! MembershipLoaded) return;
        final location = GoRouterState.of(context).uri.path;
        if (state.status.current == null && !location.startsWith(AppRoutes.joinMess)) context.go(AppRoutes.joinMessRequests);
        if (state.status.current != null && location.startsWith(AppRoutes.joinMess)) context.go(AppRoutes.home);
      },
      child: BlocBuilder<MembershipCubit, MembershipState>(
        builder: (context, state) {
          return switch (state) {
            MembershipLoading() => const Scaffold(body: Center(child: CircularProgressIndicator.adaptive())),
            MembershipError(:final message) => _MembershipError(message: message),
            MembershipLoaded(:final status) => status.current != null ? connectedChild : _NoCurrentMess(status: status),
          };
        },
      ),
    );
  }
}

class _MembershipError extends StatelessWidget {
  const _MembershipError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: Dimensions.iconSizeExtraLarge, color: context.customThemeColors.errorColor),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              FilledButton.icon(onPressed: () => context.read<MembershipCubit>().load(), icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoCurrentMess extends StatefulWidget {
  const _NoCurrentMess({required this.status});

  final MembershipStatusEntity status;

  @override
  State<_NoCurrentMess> createState() => _NoCurrentMessState();
}

class _NoCurrentMessState extends State<_NoCurrentMess> {
  final _inviteController = TextEditingController();
  final _messNameController = TextEditingController();
  final _messAddressController = TextEditingController();
  final _seasonNameController = TextEditingController();
  final _messSearchController = TextEditingController();
  MessPageEntity? _messPage;
  bool _loadingMesses = false;
  String? _messError;
  bool _didLoadMesses = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadMesses) return;
    _didLoadMesses = true;
    _loadMesses();
  }

  Future<void> _loadMesses({int page = 1}) async {
    if (_loadingMesses) return;
    setState(() {
      _loadingMesses = true;
      _messError = null;
    });
    try {
      final result = await context.read<MembershipCubit>().getAvailableMesses(page: page, limit: AppConstants.paginationLimitSmall, search: _messSearchController.text);
      if (!mounted) return;
      setState(() => _messPage = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _messError = 'Could not load messes. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingMesses = false);
    }
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _messNameController.dispose();
    _messAddressController.dispose();
    _seasonNameController.dispose();
    _messSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    final colors = context.customThemeColors;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      appBar: AppBar(title: const Text('Mess Manager')),
      body: RefreshIndicator(
        onRefresh: () => context.read<MembershipCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [colors.primaryDarkColor, colors.primaryColor]),
                        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.home_work_outlined, color: Colors.white, size: 56),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          Text('Welcome, ${user?.name ?? 'Member'}', textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraOverLarge)),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text('You are not connected to an active mess yet. Join with an invite or send a request to a mess manager.', textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceLarge),
                    _JoinMessMenu(location: location),
                    const SizedBox(height: Dimensions.spaceLarge),
                    if (location == AppRoutes.joinMessInvites)
                      _InviteCard(controller: _inviteController, invites: widget.status.invites)
                    else if (location == AppRoutes.createMess)
                      _CreateMessCard(nameController: _messNameController, addressController: _messAddressController, seasonController: _seasonNameController)
                    else
                      _AvailableMessCard(messPage: _messPage, pendingRequests: widget.status.pendingRequests, searchController: _messSearchController, loading: _loadingMesses, error: _messError, onSearch: () => _loadMesses(), onPageChanged: (page) => _loadMesses(page: page)),
                    if (widget.status.history.isNotEmpty) ...[
                      const SizedBox(height: Dimensions.spaceLarge),
                      Text('Previous messes', style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      for (final membership in widget.status.history) ...[
                        _HistoryCard(membership: membership),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ],
                    ],
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

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.controller, required this.invites});

  final TextEditingController controller;
  final List<InviteSummaryEntity> invites;

  Future<void> _join(BuildContext context, String code, {String? messName}) async {
    final inviteCode = code.trim();
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an invite code first.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join mess?'),
        content: Text(messName == null ? 'Are you sure you want to use this invitation and join the mess?' : 'Are you sure you want to join $messName?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Join')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) await context.read<MembershipCubit>().joinInvite(inviteCode);
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: Icons.mark_email_read_outlined,
      title: 'Join with invite',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Invite code', hintText: 'Enter your invite code')),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          FilledButton.icon(onPressed: () => _join(context, controller.text), icon: const Icon(Icons.login_rounded), label: const Text('Join mess')),
          if (invites.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text('Invites for you', style: AppTextStyles.sfProRoundedSemiBold),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            for (final invite in invites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invite.messName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Invitation #${invite.id} · Mess #${invite.messId} · ${invite.status[0].toUpperCase()}${invite.status.substring(1)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: invite.status == 'pending' ? TextButton(onPressed: () => _join(context, invite.inviteCode, messName: invite.messName), child: const Text('Accept')) : null,
              ),
          ],
        ],
      ),
    );
  }
}

class _JoinMessMenu extends StatelessWidget {
  const _JoinMessMenu({required this.location});

  final String location;

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
              _JoinMessMenuItem(label: 'Invites', route: AppRoutes.joinMessInvites, selected: location == AppRoutes.joinMessInvites),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              _JoinMessMenuItem(label: 'Join requests', route: AppRoutes.joinMessRequests, selected: location == AppRoutes.joinMessRequests || location == AppRoutes.joinMess),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              _JoinMessMenuItem(label: 'Create mess', route: AppRoutes.createMess, selected: location == AppRoutes.createMess),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinMessMenuItem extends StatelessWidget {
  const _JoinMessMenuItem({required this.label, required this.route, required this.selected});

  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: selected ? colors.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
          child: Text(label, maxLines: 1, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: selected ? Theme.of(context).colorScheme.onPrimary : colors.textPrimaryColor)),
        ),
      ),
    );
  }
}

class _CreateMessCard extends StatelessWidget {
  const _CreateMessCard({required this.nameController, required this.addressController, required this.seasonController});

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController seasonController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceLarge),
      child: _Panel(
        icon: Icons.add_business_rounded,
        title: 'Create a new mess',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Mess name')),
              TextField(controller: seasonController, decoration: const InputDecoration(labelText: 'First season name', hintText: 'Example: July 2026')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address (optional)')),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (constraints.maxWidth >= 700)
                  Row(children: [for (var i = 0; i < fields.length; i++) ...[Expanded(child: fields[i]), if (i < fields.length - 1) const SizedBox(width: Dimensions.paddingSizeDefault)]])
                else
                  for (var i = 0; i < fields.length; i++) ...[fields[i], if (i < fields.length - 1) const SizedBox(height: Dimensions.paddingSizeDefault)],
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => context.read<MembershipCubit>().createMess(name: nameController.text, address: addressController.text, seasonName: seasonController.text),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create mess'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvailableMessCard extends StatelessWidget {
  const _AvailableMessCard({required this.messPage, required this.pendingRequests, required this.searchController, required this.loading, required this.error, required this.onSearch, required this.onPageChanged});

  final MessPageEntity? messPage;
  final List<JoinRequestSummaryEntity> pendingRequests;
  final TextEditingController searchController;
  final bool loading;
  final String? error;
  final VoidCallback onSearch;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pendingIds = pendingRequests.map((request) => request.messId).toSet();
    return _Panel(
      icon: Icons.groups_outlined,
      title: 'Request to join',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: searchController, textInputAction: TextInputAction.search, onSubmitted: (_) => onSearch(), decoration: InputDecoration(labelText: 'Find a mess', hintText: 'Search by mess name or ID', suffixIcon: IconButton(onPressed: loading ? null : onSearch, icon: const Icon(Icons.search_rounded)))),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (loading)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (error != null)
            Column(children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: Dimensions.paddingSizeDefault), OutlinedButton.icon(onPressed: onSearch, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))])
          else if (messPage == null || messPage!.messes.isEmpty)
            const Text('No mess found.', textAlign: TextAlign.center)
          else ...[
            for (final mess in messPage!.messes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.home_work_outlined)),
                    title: Text(mess.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(mess.address.isEmpty ? 'ID: ${mess.id}' : 'ID: ${mess.id} · ${mess.address}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: pendingIds.contains(mess.id) ? const Chip(label: Text('Pending')) : TextButton(onPressed: () => context.read<MembershipCubit>().requestJoin(mess.id), child: const Text('Request')),
                  ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Row(
              children: [
                Expanded(child: Text('${messPage!.total} messes · Page ${messPage!.currentPage} of ${messPage!.lastPage}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(onPressed: messPage!.currentPage > 1 ? () => onPageChanged(messPage!.currentPage - 1) : null, tooltip: 'Previous page', icon: const Icon(Icons.chevron_left_rounded)),
                IconButton(onPressed: messPage!.currentPage < messPage!.lastPage ? () => onPageChanged(messPage!.currentPage + 1) : null, tooltip: 'Next page', icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), border: Border.all(color: colors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Icon(icon, color: colors.primaryColor), const SizedBox(width: Dimensions.paddingSizeSmall), Expanded(child: Text(title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge)))]),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          child,
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.membership});

  final MembershipSummaryEntity membership;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge), border: Border.all(color: colors.borderColor)),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colors.primaryColor),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(membership.messName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold), Text('${membership.seasonName} · ${membership.status ?? 'previous'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall))])),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(DashboardFormatters.taka(membership.totalDeposit), style: AppTextStyles.sfProRoundedSemiBold), Text('${DashboardFormatters.number(membership.totalMeal)} meals', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall))]),
        ],
      ),
    );
  }
}

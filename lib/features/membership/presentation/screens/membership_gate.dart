import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_formatters.dart';
import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:clean_boilerplate/core/widgets/app_loader.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/profile_menu.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/membership_status_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MembershipGate extends StatefulWidget {
  const MembershipGate({required this.connectedChild, this.allowConnected = false, this.loadingChild, super.key});

  final Widget connectedChild;
  final Widget? loadingChild;

  /// Join screen mode: a user may belong to several messes, so connected users
  /// also see the join / create UI and go home only once their current
  /// membership changes (they created a mess or accepted an invite).
  final bool allowConnected;

  @override
  State<MembershipGate> createState() => _MembershipGateState();
}

class _MembershipGateState extends State<MembershipGate> {
  /// The current membership last seen, to notice when it changes.
  String? _knownCurrentId;
  bool _seenStatus = false;

  /// A user without a current membership must join or create a mess first. `status.current` is resolved by the
  /// same backend rule as the user's `activeMessId`, but stays fresh after joining, creating, leaving or switching.
  bool _hasMess(MembershipStatusEntity status) {
    final current = status.current;
    return current != null && (current.isManager || current.isMember || current.isActingManager);
  }

  Future<void> _onStatus(BuildContext context, MembershipStatusEntity status) async {
    final currentId = status.current == null ? null : '${status.current!.messId}:${status.current!.seasonId}';
    final changed = _seenStatus && currentId != _knownCurrentId;
    _seenStatus = true;
    _knownCurrentId = currentId;

    final user = context.read<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    if (changed || user?.activeMessId != status.current?.messId || user?.role != (status.current?.role ?? 'member')) {
      try {
        await context.read<AuthBloc>().refreshProfile();
      } catch (error) {
        if (context.mounted) context.showErrorSnackBar(error);
        return;
      }
      if (!context.mounted || _knownCurrentId != currentId) return;
    }

    final onJoinScreen = GoRouterState.of(context).uri.path.startsWith(AppRoutes.joinMess);
    final hasMess = _hasMess(status);
    if (!hasMess && !onJoinScreen) context.go(AppRoutes.joinMessRequests);
    if (hasMess && onJoinScreen && (!widget.allowConnected || changed)) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MembershipCubit, MembershipState>(
      listener: (context, state) {
        if (state is MembershipLoaded) _onStatus(context, state.status);
      },
      child: BlocBuilder<MembershipCubit, MembershipState>(
        builder: (context, state) {
          return switch (state) {
            MembershipLoading() => widget.loadingChild ?? const Scaffold(body: Center(child: AppLoader())),
            MembershipError(:final message) => _MembershipError(message: message),
            MembershipLoaded(:final status) =>
              _hasMess(status) && !widget.allowConnected ? widget.connectedChild : _NoCurrentMess(status: status, connected: _hasMess(status)),
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
    return Scaffold(body: AppErrorState(error: message, onRetry: () => context.read<MembershipCubit>().load()));
  }
}

class _NoCurrentMess extends StatefulWidget {
  const _NoCurrentMess({required this.status, this.connected = false});

  final MembershipStatusEntity status;

  /// Already in a mess and joining or creating another one.
  final bool connected;

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
      setState(() => _messError = context.local.uiCouldNotLoadMessesPleaseTryAgain);
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
      appBar: AppBar(
        leading: widget.connected ? const HomeBackButton() : null,
        title: const Text('Mess Pilot'),
        actions: [
          IconButton(onPressed: () => confirmSignOut(context), icon: const Icon(Icons.logout_rounded), tooltip: context.local.logout),
        ],
      ),
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
                          Text(context.local.welcome(user?.name ?? context.local.roleMember), textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraOverLarge)),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(widget.connected ? context.local.joinAnotherMessSubtitle : context.local.uiYouAreNotConnectedToAnActiveMessYetJoinWithAnInviteOrSendARequestToAMessManager, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
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
                      Text(context.local.uiPreviousMesses, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
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
      context.showErrorSnackBar(context.local.inviteCodeRequired);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.local.uiJoinMess),
        content: Text(messName == null ? context.local.uiAreYouSureYouWantToUseThisInvitationAndJoinTheMess : context.local.uiJoinNamedMess(messName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.local.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(context.local.uiJoin)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) await context.read<MembershipCubit>().joinInvite(inviteCode);
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      icon: Icons.mark_email_read_outlined,
      title: context.local.uiJoinWithInvite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: context.local.uiInviteCode, hintText: context.local.uiEnterYourInviteCode)),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          FilledButton.icon(onPressed: () => _join(context, controller.text), icon: const Icon(Icons.login_rounded), label: Text(context.local.uiJoinMessText)),
          if (invites.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(context.local.uiInvitesForYou, style: AppTextStyles.sfProRoundedSemiBold),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            for (final invite in invites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(invite.messName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(context.local.uiInvitationSummary(invite.id, invite.messId, MessFormatters.status(context, invite.status)), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: invite.status == 'pending' ? TextButton(onPressed: () => _join(context, invite.inviteCode, messName: invite.messName), child: Text(context.local.accept)) : null,
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
              _JoinMessMenuItem(label: context.local.uiInvites, route: AppRoutes.joinMessInvites, selected: location == AppRoutes.joinMessInvites),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              _JoinMessMenuItem(label: context.local.joinRequests, route: AppRoutes.joinMessRequests, selected: location == AppRoutes.joinMessRequests || location == AppRoutes.joinMess),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              _JoinMessMenuItem(label: context.local.uiCreateMess, route: AppRoutes.createMess, selected: location == AppRoutes.createMess),
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
        title: context.local.uiCreateANewMess,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              TextField(controller: nameController, decoration: InputDecoration(labelText: context.local.messName)),
              TextField(controller: seasonController, decoration: InputDecoration(labelText: context.local.uiFirstSeasonName, hintText: context.local.uiExampleJuly2026)),
              TextField(controller: addressController, decoration: InputDecoration(labelText: context.local.addressOptional)),
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
                    label: Text(context.local.uiCreateMess),
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
      title: context.local.uiRequestToJoin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: searchController, textInputAction: TextInputAction.search, onSubmitted: (_) => onSearch(), decoration: InputDecoration(labelText: context.local.uiFindAMess, hintText: context.local.uiSearchByMessNameOrId, suffixIcon: IconButton(onPressed: loading ? null : onSearch, icon: const Icon(Icons.search_rounded)))),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (loading)
            const Center(child: AppLoader())
          else if (error != null)
            AppErrorState(error: error!, onRetry: onSearch)
          else if (messPage == null || messPage!.messes.isEmpty)
            AppEmptyState(title: context.local.noMatchingRecords, icon: Icons.search_off_rounded)
          else ...[
            for (final mess in messPage!.messes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.home_work_outlined)),
                    title: Text(mess.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(mess.address.isEmpty ? context.local.uiMessId(mess.id) : '${context.local.uiMessId(mess.id)} · ${mess.address}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: pendingIds.contains(mess.id) ? Chip(label: Text(context.local.statusPending)) : TextButton(onPressed: () => context.read<MembershipCubit>().requestJoin(mess.id), child: Text(context.local.uiRequest)),
                  ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Row(
              children: [
                Expanded(child: Text(context.local.uiMessPagination(messPage!.total, messPage!.currentPage, messPage!.lastPage), maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(onPressed: messPage!.currentPage > 1 ? () => onPageChanged(messPage!.currentPage - 1) : null, tooltip: context.local.uiPreviousPage, icon: const Icon(Icons.chevron_left_rounded)),
                IconButton(onPressed: messPage!.currentPage < messPage!.lastPage ? () => onPageChanged(messPage!.currentPage + 1) : null, tooltip: context.local.uiNextPage, icon: const Icon(Icons.chevron_right_rounded)),
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(membership.messName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold), Text('${membership.seasonName} · ${MessFormatters.status(context, membership.status ?? 'inactive')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall))])),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(DashboardFormatters.taka(membership.totalDeposit), style: AppTextStyles.sfProRoundedSemiBold), Text(context.local.uiMealCountLabel(DashboardFormatters.number(membership.totalMeal)), style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall))]),
        ],
      ),
    );
  }
}

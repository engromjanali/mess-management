import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/errors/user_error_message.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/core/widgets/web_page_title_bar.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/opinion/data/opinion_api_service.dart';
import 'package:clean_boilerplate/features/opinion/domain/entities/opinion_entity.dart';

class OpinionScreen extends StatefulWidget {
  const OpinionScreen({super.key});

  @override
  State<OpinionScreen> createState() => _OpinionScreenState();
}

class _OpinionScreenState extends State<OpinionScreen> {
  final _messageController = TextEditingController();
  late final _api = OpinionApiService(getIt<ApiClient>());
  List<OpinionPeriodEntity> _periods = [];
  Map<String, List<AnonymousOpinionEntity>> _opinions = {};
  final Map<String, int> _messagePages = {};
  Map<String, int?> _nextMessagePages = {};
  int _pages = 1;
  int? _nextPage;
  bool _canManage = false;
  bool _canCreate = false;
  bool _loading = true;
  bool _refreshing = false;
  bool _busy = false;
  Object? _error;
  CancelToken? _cancel;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing || _busy) return;
    final version = ++_requestVersion;
    final cancel = CancelToken();
    _cancel?.cancel();
    _cancel = cancel;
    setState(() => _refreshing = true);
    try {
      final periods = <OpinionPeriodEntity>[];
      OpinionOverview? last;
      for (var page = 1; page <= _pages; page++) {
        last = await _api.getOverview(page: page, cancelToken: cancel);
        if (!mounted || version != _requestVersion) return;
        periods.addAll(last.periods);
        if (last.nextPage == null) { _pages = page; break; }
      }
      final opinions = <String, List<AnonymousOpinionEntity>>{};
      final nextMessages = <String, int?>{};
      for (final period in periods) {
        final messages = [...period.opinions];
        var next = period.hasMoreOpinions ? 2 : null;
        for (var page = 2; page <= (_messagePages[period.id] ?? 1) && next != null; page++) {
          final result = await _api.getMessages(period.id, page: page, cancelToken: cancel);
          messages.addAll(result.opinions);
          next = result.nextPage;
        }
        opinions[period.id] = messages;
        nextMessages[period.id] = next;
      }
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _periods = periods;
        _opinions = opinions;
        _nextMessagePages = nextMessages;
        _nextPage = last!.nextPage;
        _canManage = last.canManage;
        _canCreate = last.canCreate;
        _error = null;
      });
    } catch (error) {
      if (mounted && version == _requestVersion && !cancel.isCancelled) {
        setState(() => _error = error);
        if (!silent && _periods.isNotEmpty) context.showErrorSnackBar(userErrorMessage(error, context.local));
      }
    } finally {
      if (mounted && version == _requestVersion) setState(() { _loading = false; _refreshing = false; });
    }
  }

  void _resetAndLoad() {
    _requestVersion++;
    _cancel?.cancel();
    setState(() {
      _periods = [];
      _opinions = {};
      _messagePages.clear();
      _nextMessagePages = {};
      _pages = 1;
      _canManage = false;
      _canCreate = false;
      _loading = true;
      _refreshing = false;
      _busy = false;
      _messageController.clear();
    });
    _load();
  }

  Future<bool> _mutate(Future<void> Function() action, {String? success}) async {
    if (_busy) return false;
    if (_refreshing) {
      _requestVersion++;
      _cancel?.cancel();
      _refreshing = false;
    }
    final version = _requestVersion;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted || version != _requestVersion) return false;
      setState(() => _busy = false);
      await _load();
      if (!mounted || _requestVersion != version + 1) return false;
      if (mounted && success != null) context.showSuccessSnackBar(success);
      return true;
    } catch (error) {
      if (mounted && version == _requestVersion) context.showErrorSnackBar(userErrorMessage(error, context.local));
      return false;
    } finally {
      if (mounted && version == _requestVersion) setState(() => _busy = false);
    }
  }

  Future<void> _loadMoreOpinions(OpinionPeriodEntity period) async {
    final page = _nextMessagePages[period.id];
    if (page == null || _busy || _refreshing) return;
    final version = _requestVersion;
    setState(() => _busy = true);
    try {
      final result = await _api.getMessages(period.id, page: page);
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _opinions[period.id] = {for (final opinion in [...?_opinions[period.id], ...result.opinions]) opinion.id: opinion}.values.toList();
        _messagePages[period.id] = page;
        _nextMessagePages[period.id] = result.nextPage;
      });
    } catch (error) {
      if (mounted && version == _requestVersion) context.showErrorSnackBar(userErrorMessage(error, context.local));
    } finally {
      if (mounted && version == _requestVersion) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    _cancel?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final isAdmin = context.watch<RoleCubit>().state.isAdmin && _canManage;
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    final content = _loading ? const Center(child: CircularProgressIndicator.adaptive()) : _error != null && _periods.isEmpty
        ? Center(child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(userErrorMessage(_error!, context.local), textAlign: TextAlign.center), TextButton.icon(onPressed: () => _load(), icon: const Icon(Icons.refresh_rounded), label: Text(context.local.tryAgain))])))
        : RefreshIndicator(onRefresh: () => _load(), child: _OpinionBody(
      periods: _periods,
      isAdmin: isAdmin,
      messageController: _messageController,
      opinionsForPeriod: (periodId) => _opinions[periodId] ?? const [],
      onSubmit: _submitOpinion,
      onToggleSending: _toggleSending,
      onChangeEndDate: _changeEndDate,
      onChangeVisibility: (period, visibility) => _mutate(() => _api.setVisibility(periodId: period.id, visibility: visibility)),
      onPublish: (period) => _mutate(() => _api.setVisibility(periodId: period.id, visibility: period.visibility == OpinionVisibility.realtime ? OpinionVisibility.afterPublish : OpinionVisibility.realtime)),
      busy: _busy,
      hasMoreOpinions: (periodId) => _nextMessagePages[periodId] != null,
      onLoadMoreOpinions: _loadMoreOpinions,
      onLoadMorePeriods: _nextPage == null ? null : () { _pages++; _load(); },
    ));

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.maybeWhen(authenticated: (user) => (user.id, user.activeMessId, user.currentSeason?.id), orElse: () => null) != current.maybeWhen(authenticated: (user) => (user.id, user.activeMessId, user.currentSeason?.id), orElse: () => null),
      listener: (context, state) => _resetAndLoad(),
      child: Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: const Text('Anonymous opinions'), actions: [IconButton(tooltip: context.local.refresh, onPressed: _busy || _refreshing ? null : () => _load(), icon: const Icon(Icons.refresh_rounded))]),
      floatingActionButton: isAdmin && _canCreate ? FloatingActionButton.extended(onPressed: _busy || _refreshing ? null : _createPeriod, icon: const Icon(Icons.add_rounded), label: const Text('Open period')) : null,
      body: showWebAppBar
          ? Builder(
              builder: (context) => Column(
                children: [
                  DashboardTopBar(
                    userName: user?.name ?? 'User',
                    onProfileTap: () => Scaffold.of(context).openEndDrawer(),
                    navItems: [
                      DashboardNavItem(label: 'Home', icon: Icons.home_rounded, onTap: () => context.go(AppRoutes.home)),
                      DashboardNavItem(label: 'Meals', icon: Icons.restaurant_rounded, onTap: () => context.go(AppRoutes.meals)),
                      DashboardNavItem(label: 'Deposits', icon: Icons.account_balance_wallet_rounded, onTap: () => context.go(AppRoutes.deposits)),
                      DashboardNavItem(label: 'Bazar', icon: Icons.shopping_cart_rounded, onTap: () => context.go(AppRoutes.costs)),
                    ],
                  ),
                  Stack(children: [const WebPageTitleBar(title: 'Anonymous opinions'), Positioned(top: 4, right: Dimensions.paddingSizeSmall, child: IconButton(tooltip: context.local.refresh, onPressed: _busy || _refreshing ? null : () => _load(), icon: const Icon(Icons.refresh_rounded)))]),
                  Expanded(child: content),
                ],
              ),
            )
          : content,
    ),
    );
  }

  Future<void> _submitOpinion(OpinionPeriodEntity period) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      context.showErrorSnackBar(context.local.opinionMessageRequired);
      return;
    }
    if (!period.canWrite || !period.isActiveAt(DateTime.now())) {
      context.showErrorSnackBar(context.local.opinionPeriodClosed);
      return;
    }
    if (await _mutate(() => _api.submitOpinion(periodId: period.id, message: message), success: context.local.opinionSubmitted) && mounted) _messageController.clear();
  }

  void _toggleSending(OpinionPeriodEntity period) {
    _mutate(() => _api.setMessageSending(periodId: period.id, enabled: !period.acceptingMessages), success: period.acceptingMessages ? context.local.opinionSendingPaused : context.local.opinionSendingEnabled);
  }

  Future<void> _changeEndDate(OpinionPeriodEntity period) async {
    final selected = await showDatePicker(context: context, initialDate: period.endDate, firstDate: period.startDate, lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (selected == null || !mounted) return;
    await _mutate(() => _api.updateEndDate(periodId: period.id, endDate: selected));
  }

  Future<void> _createPeriod() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    var startDate = DateTime.now();
    var endDate = DateTime.now().add(const Duration(days: 7));
    var visibility = OpinionVisibility.afterPublish;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Open opinion period'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, maxLength: 120, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(controller: detailsController, maxLength: 1000, maxLines: 4, decoration: const InputDecoration(labelText: 'Details')),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  DropdownButtonFormField<OpinionVisibility>(
                    initialValue: visibility,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: context.local.opinionVisibility),
                    items: [
                      DropdownMenuItem(value: OpinionVisibility.realtime, child: Text(context.local.opinionPublic, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: OpinionVisibility.afterPublish, child: Text(context.local.opinionPrivate, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (value) { if (value != null) setDialogState(() => visibility = value); },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _DateButton(
                    label: 'Start date',
                    date: startDate,
                    onTap: () async {
                      final selected = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
                      if (selected != null) setDialogState(() => startDate = selected);
                    },
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _DateButton(
                    label: 'End date',
                    date: endDate,
                    onTap: () async {
                      final selected = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime.now().add(const Duration(days: 3650)));
                      if (selected != null) setDialogState(() => endDate = selected);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty || detailsController.text.trim().isEmpty || endDate.isBefore(startDate)) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );

    if (mounted && (created ?? false)) {
      await _mutate(() => _api.createPeriod(title: titleController.text.trim(), details: detailsController.text.trim(), startDate: startDate, endDate: endDate, visibility: visibility));
    }
    titleController.dispose();
    detailsController.dispose();
  }
}

class _OpinionBody extends StatelessWidget {
  const _OpinionBody({required this.periods, required this.isAdmin, required this.messageController, required this.opinionsForPeriod, required this.onSubmit, required this.onToggleSending, required this.onChangeEndDate, required this.onChangeVisibility, required this.onPublish, required this.busy, required this.hasMoreOpinions, required this.onLoadMoreOpinions, required this.onLoadMorePeriods});

  final List<OpinionPeriodEntity> periods;
  final bool isAdmin;
  final TextEditingController messageController;
  final List<AnonymousOpinionEntity> Function(String periodId) opinionsForPeriod;
  final ValueChanged<OpinionPeriodEntity> onSubmit;
  final ValueChanged<OpinionPeriodEntity> onToggleSending;
  final ValueChanged<OpinionPeriodEntity> onChangeEndDate;
  final void Function(OpinionPeriodEntity period, OpinionVisibility visibility) onChangeVisibility;
  final ValueChanged<OpinionPeriodEntity> onPublish;
  final bool busy;
  final bool Function(String periodId) hasMoreOpinions;
  final ValueChanged<OpinionPeriodEntity> onLoadMoreOpinions;
  final VoidCallback? onLoadMorePeriods;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewportConstraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Column(
            mainAxisAlignment: ResponsiveHelper.isDesktop(context) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: periods.isEmpty
                        ? const _EmptyOpinionView()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                decoration: BoxDecoration(color: context.customThemeColors.primaryColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.shield_outlined, color: context.customThemeColors.primaryColor),
                                    const SizedBox(width: Dimensions.paddingSizeDefault),
                                    Expanded(child: Text('Share freely. Messages are stored without member identity and cannot be edited or deleted.', style: AppTextStyles.sfProRoundedMedium.copyWith(color: context.customThemeColors.textPrimaryColor, height: 1.4))),
                                  ],
                                ),
                              ),
                              for (final period in periods)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                                  child: _PeriodCard(
                                    period: period,
                                    isAdmin: isAdmin,
                                    messageController: messageController,
                                    opinions: isAdmin || period.visibility == OpinionVisibility.realtime ? opinionsForPeriod(period.id) : const [],
                                    onSubmit: () => onSubmit(period),
                                    onToggleSending: () => onToggleSending(period),
                                    onChangeEndDate: () => onChangeEndDate(period),
                                    onChangeVisibility: (visibility) => onChangeVisibility(period, visibility),
                                    onPublish: () => onPublish(period),
                                    busy: busy,
                                    hasMoreOpinions: hasMoreOpinions(period.id),
                                    onLoadMoreOpinions: () => onLoadMoreOpinions(period),
                                  ),
                                ),
                              if (onLoadMorePeriods != null)
                                TextButton.icon(onPressed: busy ? null : onLoadMorePeriods, icon: const Icon(Icons.expand_more_rounded), label: Text(context.local.opinionLoadMore)),
                            ],
                          ),
                  ),
                ),
              ),
              if (ResponsiveHelper.isDesktop(context)) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.isAdmin, required this.messageController, required this.opinions, required this.onSubmit, required this.onToggleSending, required this.onChangeEndDate, required this.onChangeVisibility, required this.onPublish, required this.busy, required this.hasMoreOpinions, required this.onLoadMoreOpinions});

  final OpinionPeriodEntity period;
  final bool isAdmin;
  final TextEditingController messageController;
  final List<AnonymousOpinionEntity> opinions;
  final VoidCallback onSubmit;
  final VoidCallback onToggleSending;
  final VoidCallback onChangeEndDate;
  final ValueChanged<OpinionVisibility> onChangeVisibility;
  final VoidCallback onPublish;
  final bool busy;
  final bool hasMoreOpinions;
  final VoidCallback onLoadMoreOpinions;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final active = period.isActiveAt(DateTime.now());
    final inDateRange = period.isWithinDateRangeAt(DateTime.now());
    final status = !inDateRange ? 'Closed' : period.acceptingMessages ? 'Open' : 'Paused';
    final opinionColors = [colors.primaryColor, colors.infoColor];
    final managerButtonStyle = OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall), iconSize: 18);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.cardBackgroundColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge), border: Border.all(color: colors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: Dimensions.paddingSizeSmall,
            children: [
              Text(period.title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
              Chip(label: Text(status), avatar: Icon(active ? Icons.lock_open_rounded : period.acceptingMessages ? Icons.lock_outline_rounded : Icons.pause_circle_outline_rounded, size: Dimensions.iconSizeSmall)),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(period.details, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, height: 1.4)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(period.seasonName, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.primaryColor)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text('${_date(period.startDate)} – ${_date(period.endDate)}  •  Period ID: ${period.id}', style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
          if (isAdmin) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              children: [
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onToggleSending, icon: Icon(period.acceptingMessages ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(period.acceptingMessages ? 'Pause messages' : 'Enable messages')),
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onChangeEndDate, icon: const Icon(Icons.event_rounded), label: const Text('Change end date')),
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onPublish, icon: Icon(period.visibility == OpinionVisibility.realtime ? Icons.public_rounded : Icons.lock_outline_rounded), label: Text(period.visibility == OpinionVisibility.realtime ? context.local.opinionPublic : context.local.opinionPrivate)),
              ],
            ),
          ],
          if (active && period.canWrite) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            TextField(controller: messageController, enabled: !busy, maxLength: 2000, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Your anonymous opinion', hintText: 'No identity is stored with this message')),
            Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: busy ? null : onSubmit, icon: const Icon(Icons.send_rounded), label: const Text('Submit anonymously'))),
          ] else if (active) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(context.local.opinionCurrentSeasonOnly, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
          ],
          if (isAdmin || period.visibility == OpinionVisibility.realtime) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text('Anonymous messages (${isAdmin || period.visibility == OpinionVisibility.realtime ? period.opinionCount : opinions.length})', style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (opinions.isEmpty)
              Text('No messages submitted in this period.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
            else
              for (final (index, opinion) in opinions.indexed)
                Container(
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(opinionColors[index % opinionColors.length].withValues(alpha: 0.12), colors.surfaceColor),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(color: opinionColors[index % opinionColors.length].withValues(alpha: 0.3)),
                  ),
                  child: Text(opinion.message, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textPrimaryColor, height: 1.4)),
                ),
            if (hasMoreOpinions)
              TextButton.icon(onPressed: busy ? null : onLoadMoreOpinions, icon: const Icon(Icons.expand_more_rounded), label: Text(context.local.opinionLoadMore)),
          ] else ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(context.local.opinionPrivate, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
          ],
        ],
      ),
    );
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.calendar_month_rounded), label: Text('$label: ${date.day}/${date.month}/${date.year}'));
  }
}

class _EmptyOpinionView extends StatelessWidget {
  const _EmptyOpinionView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 64, color: context.customThemeColors.textHintColor),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          const Text('No opinion period is open yet', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

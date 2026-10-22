import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:clean_boilerplate/core/widgets/app_loader.dart';
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
import 'package:clean_boilerplate/core/widgets/pill_tab_bar.dart';
import 'package:clean_boilerplate/core/widgets/segmented_tab_bar.dart';
import 'package:clean_boilerplate/core/widgets/web_page_title_bar.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/opinion/data/opinion_api_service.dart';
import 'package:clean_boilerplate/features/opinion/domain/entities/opinion_entity.dart';

class OpinionScreen extends StatefulWidget {
  const OpinionScreen({this.showCreateTab = false, super.key});

  final bool showCreateTab;

  @override
  State<OpinionScreen> createState() => _OpinionScreenState();
}

enum _OpinionPageTab { opinions, create }

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
  bool _submitAnonymously = true;
  late _OpinionPageTab _tab;
  Object? _error;
  CancelToken? _cancel;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _tab = widget.showCreateTab ? _OpinionPageTab.create : _OpinionPageTab.opinions;
    _load();
  }

  @override
  void didUpdateWidget(covariant OpinionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showCreateTab != widget.showCreateTab) _tab = widget.showCreateTab ? _OpinionPageTab.create : _OpinionPageTab.opinions;
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
    final opinionContent = _loading ? const Center(child: AppLoader()) : _error != null && _periods.isEmpty
        ? AppErrorState(error: _error!, onRetry: () => _load())
        : RefreshIndicator(onRefresh: () => _load(), child: _OpinionBody(
      periods: _periods,
      isAdmin: isAdmin,
      messageController: _messageController,
      submitAnonymously: _submitAnonymously,
      onSubmissionTypeChanged: (value) => setState(() => _submitAnonymously = value),
      opinionsForPeriod: (periodId) => _opinions[periodId] ?? const [],
      onSubmit: _submitOpinion,
      onToggleSending: _toggleSending,
      onToggleNamedOpinions: (period) => _mutate(() => _api.setSubmissionMode(periodId: period.id, mode: switch (period.submissionMode) { OpinionSubmissionMode.anonymousOnly => OpinionSubmissionMode.namedOnly, OpinionSubmissionMode.namedOnly => OpinionSubmissionMode.all, OpinionSubmissionMode.all => OpinionSubmissionMode.anonymousOnly })),
      onChangeEndDate: _changeEndDate,
      onChangeVisibility: (period, visibility) => _mutate(() => _api.setVisibility(periodId: period.id, visibility: visibility)),
      onPublish: (period) => _mutate(() => _api.setVisibility(periodId: period.id, visibility: period.visibility == OpinionVisibility.realtime ? OpinionVisibility.afterPublish : OpinionVisibility.realtime)),
      busy: _busy,
      hasMoreOpinions: (periodId) => _nextMessagePages[periodId] != null,
      onLoadMoreOpinions: _loadMoreOpinions,
      onLoadMorePeriods: _nextPage == null ? null : () { _pages++; _load(); },
    ));
    final content = isAdmin && !_loading
        ? Column(children: [
            Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth), child: Padding(padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0), child: SegmentedTabBar<_OpinionPageTab>(tabs: [PillTab(value: _OpinionPageTab.opinions, label: context.local.opinionMessages), PillTab(value: _OpinionPageTab.create, label: context.local.create)], selected: _tab, onChanged: (value) => context.go(value == _OpinionPageTab.create ? AppRoutes.createOpinionPeriod : AppRoutes.opinions))))),
            Expanded(child: _tab == _OpinionPageTab.opinions ? opinionContent : OpinionPeriodFormScreen(embedded: true, onSubmitted: _createPeriodResult)),
          ])
        : opinionContent;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.maybeWhen(authenticated: (user) => (user.id, user.activeMessId, user.currentSeason?.id), orElse: () => null) != current.maybeWhen(authenticated: (user) => (user.id, user.activeMessId, user.currentSeason?.id), orElse: () => null),
      listener: (context, state) => _resetAndLoad(),
      child: Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.shareYourOpinions), actions: [IconButton(tooltip: context.local.refresh, onPressed: _busy || _refreshing ? null : () => _load(), icon: const Icon(Icons.refresh_rounded))]),
      floatingActionButton: isAdmin && _canCreate && _tab == _OpinionPageTab.opinions ? FloatingActionButton.extended(onPressed: _busy || _refreshing ? null : () => context.go(AppRoutes.createOpinionPeriod), icon: const Icon(Icons.add_rounded), label: Text(context.local.uiOpenPeriod)) : null,
      body: showWebAppBar
          ? Builder(
              builder: (context) => Column(
                children: [
                  const DashboardTopBar(),
                  Stack(children: [WebPageTitleBar(title: context.local.shareYourOpinions), Positioned(top: 4, right: Dimensions.paddingSizeSmall, child: IconButton(tooltip: context.local.refresh, onPressed: _busy || _refreshing ? null : () => _load(), icon: const Icon(Icons.refresh_rounded)))]),
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
    final anonymous = period.submissionMode == OpinionSubmissionMode.anonymousOnly || period.submissionMode == OpinionSubmissionMode.all && _submitAnonymously;
    if (await _mutate(() => _api.submitOpinion(periodId: period.id, message: message, anonymous: anonymous), success: anonymous ? context.local.opinionSubmitted : context.local.opinionSubmittedNamed) && mounted) _messageController.clear();
  }

  void _toggleSending(OpinionPeriodEntity period) {
    _mutate(() => _api.setMessageSending(periodId: period.id, enabled: !period.acceptingMessages), success: period.acceptingMessages ? context.local.opinionSendingPaused : context.local.opinionSendingEnabled);
  }

  Future<void> _changeEndDate(OpinionPeriodEntity period) async {
    final selected = await showDatePicker(context: context, initialDate: period.endDate, firstDate: period.startDate, lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (selected == null || !mounted) return;
    await _mutate(() => _api.updateEndDate(periodId: period.id, endDate: selected));
  }

  Future<void> _createPeriodResult(OpinionPeriodFormResult result) async {
    if (await _mutate(() => _api.createPeriod(title: result.title, details: result.details, startDate: result.startDate, endDate: result.endDate, visibility: result.visibility, submissionMode: result.submissionMode)) && mounted) context.go(AppRoutes.opinions);
  }
}

class OpinionPeriodFormResult {
  const OpinionPeriodFormResult({required this.title, required this.details, required this.startDate, required this.endDate, required this.visibility, required this.submissionMode});

  final String title;
  final String details;
  final DateTime startDate;
  final DateTime endDate;
  final OpinionVisibility visibility;
  final OpinionSubmissionMode submissionMode;
}

class OpinionPeriodFormScreen extends StatefulWidget {
  const OpinionPeriodFormScreen({this.embedded = false, this.onSubmitted, super.key});

  final bool embedded;
  final Future<void> Function(OpinionPeriodFormResult result)? onSubmitted;

  @override
  State<OpinionPeriodFormScreen> createState() => _OpinionPeriodFormScreenState();
}

class _OpinionPeriodFormScreenState extends State<OpinionPeriodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  OpinionVisibility _visibility = OpinionVisibility.afterPublish;
  OpinionSubmissionMode _submissionMode = OpinionSubmissionMode.anonymousOnly;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
              child: Row(children: [Icon(Icons.forum_rounded, color: colors.primaryColor), const SizedBox(width: Dimensions.paddingSizeDefault), Expanded(child: Text(context.local.uiCreateAPeriodWhereMembersCanShareTheirOpinions, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textPrimaryColor, height: 1.4)))]),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            TextFormField(controller: _titleController, maxLength: 120, textInputAction: TextInputAction.next, decoration: InputDecoration(labelText: context.local.noticeTitle, prefixIcon: Icon(Icons.title_rounded)), validator: (value) => value == null || value.trim().isEmpty ? context.local.uiTitleIsRequired : null),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextFormField(controller: _detailsController, maxLength: 1000, minLines: 4, maxLines: 7, decoration: InputDecoration(labelText: context.local.uiDetails, alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded)), validator: (value) => value == null || value.trim().isEmpty ? context.local.uiDetailsAreRequired : null),
            const SizedBox(height: Dimensions.paddingSizeSmall),
              DropdownButtonFormField<OpinionVisibility>(
                initialValue: _visibility,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.local.opinionVisibility, prefixIcon: const Icon(Icons.visibility_outlined)),
                items: [
                  DropdownMenuItem(value: OpinionVisibility.realtime, child: Text(context.local.opinionPublic, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: OpinionVisibility.afterPublish, child: Text(context.local.opinionPrivate, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) { if (value != null) setState(() => _visibility = value); },
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text(context.local.uiAllowedIdentity, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _SubmissionModeCheckTile(title: context.local.uiNameHidden, subtitle: context.local.uiMembersSubmitAnonymously, value: OpinionSubmissionMode.anonymousOnly, selected: _submissionMode, onChanged: (value) => setState(() => _submissionMode = value)),
              _SubmissionModeCheckTile(title: context.local.uiNameRevealed, subtitle: context.local.uiEveryOpinionShowsTheMemberIdentity, value: OpinionSubmissionMode.namedOnly, selected: _submissionMode, onChanged: (value) => setState(() => _submissionMode = value)),
              _SubmissionModeCheckTile(title: context.local.filterAll, subtitle: context.local.uiMembersChooseAnonymousOrNamed, value: OpinionSubmissionMode.all, selected: _submissionMode, onChanged: (value) => setState(() => _submissionMode = value)),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              LayoutBuilder(builder: (context, constraints) {
                final dateButtons = [
                  _DateButton(label: context.local.seasonStartDate, date: _startDate, onTap: _selectStartDate),
                  _DateButton(label: context.local.seasonEndDate, date: _endDate, onTap: _selectEndDate),
                ];
                if (constraints.maxWidth < 520) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [dateButtons.first, const SizedBox(height: Dimensions.paddingSizeSmall), dateButtons.last]);
                return Row(children: [Expanded(child: dateButtons.first), const SizedBox(width: Dimensions.paddingSizeDefault), Expanded(child: dateButtons.last)]);
              }),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            FilledButton.icon(onPressed: _submitting ? null : _submit, icon: const Icon(Icons.add_circle_outline_rounded), label: Text(context.local.uiOpenPeriod)),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge32),
          ]),
        ),
      ),
    );

    if (widget.embedded) return SingleChildScrollView(child: Column(children: [Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: form), if (showWebAppBar) const AppFooter()]));

    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const BackButton(), title: Text(context.local.uiOpenOpinionPeriod)),
      body: showWebAppBar
          ? Builder(builder: (context) => Column(children: [
              const MainTopBar(),
              WebPageTitleBar(title: context.local.uiOpenOpinionPeriod),
              Expanded(child: SingleChildScrollView(child: Column(children: [Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: form), const AppFooter()]))),
            ]))
          : SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: form)),
    );
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (selected == null || !mounted) return;
    setState(() {
      _startDate = selected;
      if (_endDate.isBefore(selected)) _endDate = selected;
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(context: context, initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate, firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (selected != null && mounted) setState(() => _endDate = selected);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = OpinionPeriodFormResult(title: _titleController.text.trim(), details: _detailsController.text.trim(), startDate: _startDate, endDate: _endDate, visibility: _visibility, submissionMode: _submissionMode);
    if (widget.onSubmitted == null) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => _submitting = true);
    await widget.onSubmitted!(result);
    if (mounted) setState(() => _submitting = false);
  }
}

class _SubmissionModeCheckTile extends StatelessWidget {
  const _SubmissionModeCheckTile({required this.title, required this.subtitle, required this.value, required this.selected, required this.onChanged});

  final String title;
  final String subtitle;
  final OpinionSubmissionMode value;
  final OpinionSubmissionMode selected;
  final ValueChanged<OpinionSubmissionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(value: selected == value, onChanged: (_) => onChanged(value), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, title: Text(title), subtitle: Text(subtitle), dense: true);
  }
}

class _OpinionBody extends StatelessWidget {
  const _OpinionBody({required this.periods, required this.isAdmin, required this.messageController, required this.submitAnonymously, required this.onSubmissionTypeChanged, required this.opinionsForPeriod, required this.onSubmit, required this.onToggleSending, required this.onToggleNamedOpinions, required this.onChangeEndDate, required this.onChangeVisibility, required this.onPublish, required this.busy, required this.hasMoreOpinions, required this.onLoadMoreOpinions, required this.onLoadMorePeriods});

  final List<OpinionPeriodEntity> periods;
  final bool isAdmin;
  final TextEditingController messageController;
  final bool submitAnonymously;
  final ValueChanged<bool> onSubmissionTypeChanged;
  final List<AnonymousOpinionEntity> Function(String periodId) opinionsForPeriod;
  final ValueChanged<OpinionPeriodEntity> onSubmit;
  final ValueChanged<OpinionPeriodEntity> onToggleSending;
  final ValueChanged<OpinionPeriodEntity> onToggleNamedOpinions;
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
                                    Expanded(child: Text(context.local.shareYourOpinions, style: AppTextStyles.sfProRoundedMedium.copyWith(color: context.customThemeColors.textPrimaryColor, height: 1.4))),
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
                                    submitAnonymously: submitAnonymously,
                                    onSubmissionTypeChanged: onSubmissionTypeChanged,
                                    opinions: isAdmin || period.visibility == OpinionVisibility.realtime ? opinionsForPeriod(period.id) : const [],
                                    onSubmit: () => onSubmit(period),
                                    onToggleSending: () => onToggleSending(period),
                                    onToggleNamedOpinions: () => onToggleNamedOpinions(period),
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
  const _PeriodCard({required this.period, required this.isAdmin, required this.messageController, required this.submitAnonymously, required this.onSubmissionTypeChanged, required this.opinions, required this.onSubmit, required this.onToggleSending, required this.onToggleNamedOpinions, required this.onChangeEndDate, required this.onChangeVisibility, required this.onPublish, required this.busy, required this.hasMoreOpinions, required this.onLoadMoreOpinions});

  final OpinionPeriodEntity period;
  final bool isAdmin;
  final TextEditingController messageController;
  final bool submitAnonymously;
  final ValueChanged<bool> onSubmissionTypeChanged;
  final List<AnonymousOpinionEntity> opinions;
  final VoidCallback onSubmit;
  final VoidCallback onToggleSending;
  final VoidCallback onToggleNamedOpinions;
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
    final status = !inDateRange ? context.local.uiClosed : period.acceptingMessages ? context.local.uiOpen : context.local.uiPaused;
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
          Text(context.local.uiPeriodDates(_date(period.startDate), _date(period.endDate), period.id), style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
          if (isAdmin) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              children: [
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onToggleSending, icon: Icon(period.acceptingMessages ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(period.acceptingMessages ? context.local.uiPauseMessages : context.local.uiEnableMessages)),
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onToggleNamedOpinions, icon: Icon(period.submissionMode == OpinionSubmissionMode.anonymousOnly ? Icons.visibility_off_outlined : period.submissionMode == OpinionSubmissionMode.namedOnly ? Icons.person_rounded : Icons.people_alt_outlined), label: Text(period.submissionMode == OpinionSubmissionMode.anonymousOnly ? context.local.uiNameHidden : period.submissionMode == OpinionSubmissionMode.namedOnly ? context.local.uiNameRevealed : context.local.uiAllIdentityModes)),
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onChangeEndDate, icon: const Icon(Icons.event_rounded), label: Text(context.local.uiChangeEndDate)),
                OutlinedButton.icon(style: managerButtonStyle, onPressed: busy ? null : onPublish, icon: Icon(period.visibility == OpinionVisibility.realtime ? Icons.public_rounded : Icons.lock_outline_rounded), label: Text(period.visibility == OpinionVisibility.realtime ? context.local.opinionPublic : context.local.opinionPrivate)),
              ],
            ),
          ],
          if (active && period.canWrite) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault), border: Border.all(color: colors.borderColor)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (period.submissionMode == OpinionSubmissionMode.all)
                  SwitchListTile.adaptive(value: !submitAnonymously, onChanged: busy ? null : (shareName) => onSubmissionTypeChanged(!shareName), contentPadding: EdgeInsets.zero, secondary: Icon(submitAnonymously ? Icons.visibility_off_outlined : Icons.person_outline_rounded), title: Text(submitAnonymously ? context.local.opinionAnonymous : context.local.opinionNamed), subtitle: Text(submitAnonymously ? context.local.opinionAnonymousHint : context.local.opinionNamedHint, maxLines: 2, overflow: TextOverflow.ellipsis))
                else
                  Row(children: [Icon(period.submissionMode == OpinionSubmissionMode.namedOnly ? Icons.person_outline_rounded : Icons.visibility_off_outlined, size: Dimensions.iconSizeSmall), const SizedBox(width: Dimensions.paddingSizeSmall), Expanded(child: Text(period.submissionMode == OpinionSubmissionMode.namedOnly ? context.local.uiYourNameWillBeRevealed : context.local.opinionAnonymousOnly, maxLines: 1, overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                TextField(controller: messageController, enabled: !busy, maxLength: 2000, minLines: 3, maxLines: 6, decoration: InputDecoration(labelText: context.local.opinionMessageHint, hintText: period.submissionMode == OpinionSubmissionMode.anonymousOnly || period.submissionMode == OpinionSubmissionMode.all && submitAnonymously ? context.local.opinionAnonymousHint : context.local.opinionNamedHint, alignLabelWithHint: true)),
                Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: busy ? null : onSubmit, icon: const Icon(Icons.send_rounded), label: Text(context.local.submitOpinion))),
              ]),
            ),
          ] else if (active) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text(context.local.opinionCurrentSeasonOnly, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
          ],
          if (isAdmin || period.visibility == OpinionVisibility.realtime) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text('${context.local.opinionMessages} (${isAdmin || period.visibility == OpinionVisibility.realtime ? period.opinionCount : opinions.length})', style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (opinions.isEmpty)
              Text(context.local.uiNoMessagesSubmittedInThisPeriod, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
            else
              for (final (index, opinion) in opinions.indexed)
                _OpinionCard(opinion: opinion, accentColor: opinionColors[index % opinionColors.length]),
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

class _OpinionCard extends StatelessWidget {
  const _OpinionCard({required this.opinion, required this.accentColor});

  final AnonymousOpinionEntity opinion;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final photoUrl = opinion.authorPhotoUrl?.trim() ?? '';
    final fallback = Icon(opinion.isAnonymous ? Icons.visibility_off_rounded : Icons.person_rounded, color: accentColor);

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(color: Color.alphaBlend(accentColor.withValues(alpha: 0.08), colors.surfaceColor), borderRadius: BorderRadius.circular(Dimensions.radiusDefault), border: Border.all(color: accentColor.withValues(alpha: 0.24))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: accentColor.withValues(alpha: 0.14),
          child: opinion.isAnonymous || photoUrl.isEmpty ? fallback : ClipOval(child: Image.network(photoUrl, width: 44, height: 44, fit: BoxFit.cover, cacheWidth: 132, cacheHeight: 132, errorBuilder: (_, _, _) => fallback)),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(opinion.isAnonymous ? context.local.opinionAnonymous : opinion.authorName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor))),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Icon(opinion.isAnonymous ? Icons.shield_outlined : Icons.public_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
            ]),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(opinion.message, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textPrimaryColor, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(onPressed: onTap, icon: const Icon(Icons.calendar_month_rounded), label: Text('$label: ${MaterialLocalizations.of(context).formatMediumDate(date)}'));
  }
}

class _EmptyOpinionView extends StatelessWidget {
  const _EmptyOpinionView();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(title: context.local.stateNoOpinionPeriod, icon: Icons.forum_outlined);
  }
}

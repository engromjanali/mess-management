import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/opinion/data/opinion_store.dart';
import 'package:clean_boilerplate/features/opinion/domain/entities/opinion_entity.dart';

class OpinionScreen extends StatefulWidget {
  const OpinionScreen({super.key});

  @override
  State<OpinionScreen> createState() => _OpinionScreenState();
}

class _OpinionScreenState extends State<OpinionScreen> {
  static const String _messId = 'current-mess';
  final _messageController = TextEditingController();
  final _store = OpinionStore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final isAdmin = context.watch<RoleCubit>().state.isAdmin;
    final periods = _store.periodsForMess(_messId);
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    final content = _OpinionBody(
      periods: periods,
      isAdmin: isAdmin,
      messageController: _messageController,
      opinionsForPeriod: _store.opinionsForPeriod,
      onSubmit: _submitOpinion,
      onToggleSending: _toggleSending,
      onChangeEndDate: _changeEndDate,
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: const Text('Anonymous opinions')),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(onPressed: _createPeriod, icon: const Icon(Icons.add_rounded), label: const Text('Open period')) : null,
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
                  Expanded(child: content),
                ],
              ),
            )
          : content,
    );
  }

  void _submitOpinion(OpinionPeriodEntity period) {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write your opinion first')));
      return;
    }
    if (!period.isActiveAt(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This opinion period is closed')));
      return;
    }
    _store.submitOpinion(periodId: period.id, message: message);
    _messageController.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opinion submitted anonymously')));
  }

  void _toggleSending(OpinionPeriodEntity period) {
    _store.setMessageSending(periodId: period.id, enabled: !period.acceptingMessages);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(period.acceptingMessages ? 'Message sending paused' : 'Message sending enabled')));
  }

  Future<void> _changeEndDate(OpinionPeriodEntity period) async {
    final selected = await showDatePicker(context: context, initialDate: period.endDate, firstDate: period.startDate, lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (selected == null) return;
    _store.updateEndDate(periodId: period.id, endDate: selected);
    if (mounted) setState(() {});
  }

  Future<void> _createPeriod() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    var startDate = DateTime.now();
    var endDate = DateTime.now().add(const Duration(days: 7));

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

    if (created ?? false) {
      _store.createPeriod(messId: _messId, title: titleController.text.trim(), details: detailsController.text.trim(), startDate: startDate, endDate: endDate);
      if (mounted) setState(() {});
    }
    titleController.dispose();
    detailsController.dispose();
  }
}

class _OpinionBody extends StatelessWidget {
  const _OpinionBody({required this.periods, required this.isAdmin, required this.messageController, required this.opinionsForPeriod, required this.onSubmit, required this.onToggleSending, required this.onChangeEndDate});

  final List<OpinionPeriodEntity> periods;
  final bool isAdmin;
  final TextEditingController messageController;
  final List<AnonymousOpinionEntity> Function(String periodId) opinionsForPeriod;
  final ValueChanged<OpinionPeriodEntity> onSubmit;
  final ValueChanged<OpinionPeriodEntity> onToggleSending;
  final ValueChanged<OpinionPeriodEntity> onChangeEndDate;

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
                                    opinions: opinionsForPeriod(period.id),
                                    onSubmit: () => onSubmit(period),
                                    onToggleSending: () => onToggleSending(period),
                                    onChangeEndDate: () => onChangeEndDate(period),
                                  ),
                                ),
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
  const _PeriodCard({required this.period, required this.isAdmin, required this.messageController, required this.opinions, required this.onSubmit, required this.onToggleSending, required this.onChangeEndDate});

  final OpinionPeriodEntity period;
  final bool isAdmin;
  final TextEditingController messageController;
  final List<AnonymousOpinionEntity> opinions;
  final VoidCallback onSubmit;
  final VoidCallback onToggleSending;
  final VoidCallback onChangeEndDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final active = period.isActiveAt(DateTime.now());
    final inDateRange = period.isWithinDateRangeAt(DateTime.now());
    final status = !inDateRange ? 'Closed' : period.acceptingMessages ? 'Open' : 'Paused';

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
          Text('${_date(period.startDate)} – ${_date(period.endDate)}  •  Period ID: ${period.id}', style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
          if (isAdmin) ...[
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              children: [
                OutlinedButton.icon(onPressed: onToggleSending, icon: Icon(period.acceptingMessages ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(period.acceptingMessages ? 'Pause messages' : 'Enable messages')),
                OutlinedButton.icon(onPressed: onChangeEndDate, icon: const Icon(Icons.event_rounded), label: const Text('Change end date')),
              ],
            ),
          ],
          if (active) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            TextField(controller: messageController, maxLength: 2000, maxLines: 5, decoration: const InputDecoration(labelText: 'Your anonymous opinion', hintText: 'No identity is stored with this message')),
            Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.send_rounded), label: const Text('Submit anonymously'))),
          ],
          if (isAdmin) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text('Anonymous messages (${opinions.length})', style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (opinions.isEmpty)
              Text('No messages submitted in this period.', style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))
            else
              for (final opinion in opinions)
                Container(
                  margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                  child: Text(opinion.message, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textPrimaryColor)),
                ),
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

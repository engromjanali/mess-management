import 'package:mess_pilot/config/util/dimensions.dart';
import 'dart:async';

import 'package:mess_pilot/core/notifications/notification_unread_service.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({this.noticeId, super.key});

  final String? noticeId;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _items = [];
  final _cancelToken = CancelToken();
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a', 'en');
  bool _loading = true;
  bool _failed = false;
  int? _next;
  int? _opening;
  static const _endpoint = '/api/v1/user/notifications';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    setState(() { _loading = true; _failed = false; });
    try {
      final query = <String, dynamic>{if (more && _next != null) 'before': _next, if (widget.noticeId != null) 'notice_id': widget.noticeId};
      final response = await getIt<ApiClient>().get<Map<String, dynamic>>(_endpoint, queryParameters: query, options: Options(extra: {'sensitive': true}), cancelToken: _cancelToken);
      if (!mounted) return;
      final items = (response.data?['data'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        if (!more) _items.clear();
        _items.addAll(items);
        _next = response.data?['next'] as int?;
        _loading = false;
      });
      if (!more && widget.noticeId != null && _items.isNotEmpty) await _open(_items.first);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    if (_opening != null) return;
    setState(() => _opening = item['id'] as int);
    try {
      final response = await getIt<ApiClient>().post<Map<String, dynamic>>('$_endpoint/${item['id']}/open', options: Options(extra: {'sensitive': true}), cancelToken: _cancelToken);
      if (!mounted) return;
      final data = response.data!;
      setState(() { item['read'] = true; _opening = null; });
      unawaited(NotificationUnreadService.instance.refresh());
      if (data['status'] == 'ready') {
        final route = data['route'];
        if (route is String && RegExp(r'^/notices/[1-9][0-9]*$').hasMatch(route)) await context.push(route);
      } else {
        final changeSeason = data['status'] == 'change_season';
        await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
          icon: Icon(changeSeason ? Icons.swap_horiz_rounded : Icons.lock_outline_rounded, color: context.colorScheme.primary),
          title: Text(context.local.uiNotifications),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title'] as String? ?? '', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(data['description'] as String? ?? ''),
            const SizedBox(height: 20),
            Text(changeSeason ? context.local.notificationChangeSeason : context.local.notificationAccessUnavailable, style: TextStyle(color: context.colorScheme.error)),
            if (data['season_name'] != null) ...[const SizedBox(height: 12), Text(context.local.seasonName(data['season_name'] as String))],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.local.cancel)),
            if (changeSeason) FilledButton(onPressed: () { Navigator.pop(dialogContext); context.push(AppRoutes.manageMembership); }, child: Text(context.local.notificationChooseSeason)),
          ],
        ));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.local.notificationLoadFailed)));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  Widget _notificationCard(BuildContext context, Map<String, dynamic> item) {
    final colors = context.colorScheme;
    return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: item['read'] == true ? colors.outlineVariant.withValues(alpha: 0.45) : colors.primary)),
            child: InkWell(onTap: _opening == null ? () => _open(item) : null, child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(backgroundColor: colors.primaryContainer, foregroundColor: colors.primary, child: _opening == item['id'] ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.campaign_outlined)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(item['title'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleMedium?.copyWith(fontWeight: item['read'] == true ? FontWeight.w500 : FontWeight.bold))),
                ]),
                const SizedBox(height: 6),
                Text(item['description'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 6, children: [
                    if (item['season_name'] != null) Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.event_repeat_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Flexible(child: Text(item['season_name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelMedium?.copyWith(color: colors.primary))),
                    ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.schedule_rounded, size: 14, color: colors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(child: Text(_dateFormat.format(DateTime.parse(item['created_at'] as String).toLocal()), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelSmall)),
                    ]),
                  ]),
                ),
              ])),
            ]))),
          );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final columns = showWebAppBar ? 2 : 1;
    final content = RefreshIndicator(onRefresh: _load, child: AppPageScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        maxWidth: Dimensions.webMaxWidth - 32,
        children: [
          for (var row = 0; row < (_items.length + columns - 1) ~/ columns; row++) Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: 16),
                  Expanded(child: row * columns + column < _items.length ? _notificationCard(context, _items[row * columns + column]) : const SizedBox.shrink()),
                ],
              ]),
            ),
          if (_items.isEmpty && !_loading && !_failed) Padding(padding: const EdgeInsets.symmetric(vertical: 56), child: Column(children: [Icon(Icons.mark_email_read_outlined, size: 56, color: colors.primary), const SizedBox(height: 16), Text(context.local.notificationEmpty, textAlign: TextAlign.center)])),
          if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_failed) Column(children: [Text(context.local.notificationLoadFailed, textAlign: TextAlign.center), TextButton(onPressed: () => _load(more: _items.isNotEmpty), child: Text(context.local.tryAgain))]),
          if (!_loading && !_failed && _next != null) TextButton(onPressed: () => _load(more: true), child: Text(context.local.notificationLoadMore)),
        ],
      ));
    return Scaffold(
      appBar: showWebAppBar ? null : AppBar(title: Text(context.local.uiNotifications)),
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      body: showWebAppBar
          ? Column(children: [
              const DashboardTopBar(),
              WebPageTitleBar(title: context.local.uiNotifications),
              Expanded(child: content),
            ])
          : content,
    );
  }
}

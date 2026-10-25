import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/notifications/notification_unread_service.dart';

class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({this.color, super.key});

  final Color? color;

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationUnreadService.instance.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) NotificationUnreadService.instance.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: NotificationUnreadService.instance,
    builder: (context, unread, child) => IconButton(
      tooltip: unread ? '${context.local.uiNotifications} · ${context.local.notificationUnread}' : context.local.uiNotifications,
      onPressed: () async {
        await context.push(AppRoutes.notifications);
        await NotificationUnreadService.instance.refresh();
      },
      icon: Badge(
        isLabelVisible: unread,
        backgroundColor: Colors.red,
        smallSize: 8,
        child: Icon(Icons.notifications_outlined, color: widget.color),
      ),
    ),
  );
}

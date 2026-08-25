import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
import 'package:telecom_dashboard/presentation/providers/notifications_provider.dart';

/// Mock notification model.
class PushNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type; // info, warning, promo

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = 'info',
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<PushNotification> _notifications = [
    PushNotification(
      id: 'n1',
      title: 'Скоро списание',
      body: 'Через 3 дня будет списана оплата за тариф «Интернет 100 Мбит/с» в размере 590,00 ₽.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: 'warning',
    ),
    PushNotification(
      id: 'n2',
      title: 'Акция «Приведи друга»',
      body: 'Получите 300 ₽ бонусом за каждого приглашённого абонента!',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
      type: 'promo',
    ),
    PushNotification(
      id: 'n3',
      title: 'Технические работы завершены',
      body: 'Все услуги работают в штатном режиме.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      type: 'info',
    ),
    PushNotification(
      id: 'n4',
      title: 'Баланс пополнён',
      body: 'Ваш баланс пополнён на 1 000,00 ₽.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
      type: 'info',
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      _notifications.setAll(
        0,
        _notifications.map((n) => PushNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          isRead: true,
          type: n.type,
        )).toList(),
      );
    });
    ref.read(unreadNotificationsProvider.notifier).state = 0;
  }

  void _markRead(int index) {
    setState(() {
      _notifications[index] = PushNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        createdAt: _notifications[index].createdAt,
        isRead: true,
        type: _notifications[index].type,
      );
    });
    final remaining = _notifications.where((n) => !n.isRead).length;
    ref.read(unreadNotificationsProvider.notifier).state = remaining;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBackButton: true, title: 'Уведомления'),
            if (_unreadCount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 8),
                  child: TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      'Прочитать все',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.orange500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: AppTheme.screenPadding.copyWith(bottom: 32),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return _NotificationTile(
                    notification: n,
                    onTap: () => _markRead(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PushNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (notification.type) {
      'warning' => AppTheme.warning,
      'promo' => AppTheme.orange500,
      _ => AppTheme.info,
    };
    final icon = switch (notification.type) {
      'warning' => Icons.warning_amber_rounded,
      'promo' => Icons.local_offer_rounded,
      _ => Icons.info_outline_rounded,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.cardRadius,
      child: Container(
        padding: AppTheme.cardPaddingSmall,
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.white,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
          border: notification.isRead
              ? null
              : Border(left: BorderSide(color: AppTheme.orange500, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.orange500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDate(notification.createdAt),
                    style: AppTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

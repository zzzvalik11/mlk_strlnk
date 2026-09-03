import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Глобальное количество непрочитанных уведомлений.
/// Экран уведомлений обновляет его через [unreadNotificationsProvider].
final unreadNotificationsProvider =
    StateProvider<int>((ref) => 2); // mock: 2 непрочитанных по умолчанию

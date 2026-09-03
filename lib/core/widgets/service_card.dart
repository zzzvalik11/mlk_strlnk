import 'package:flutter/material.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/domain/entities/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasWarning =
        service.warningMessage != null && service.warningMessage!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.cardRadius,
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: AppTheme.orange50,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: service.iconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            service.iconUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.public,
                              color: AppTheme.orange500,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          _categoryIcon(service.category),
                          color: AppTheme.orange500,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                // Name + category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: AppTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(service.category, style: AppTheme.bodySmall),
                    ],
                  ),
                ),
                // Warning badge
                if (hasWarning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.error,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.warningMessage!,
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Cost row
            Row(
              children: [
                Text(
                  CurrencyFormatter.formatCurrency(service.cost),
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.gray900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (service.billingCycle != null) ...[
                  const SizedBox(width: 8),
                  Text('/ ${service.billingCycle}', style: AppTheme.bodySmall),
                ],
                const Spacer(),
                // Status indicator
                _StatusChip(status: service.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'интернет':
      case 'internet':
        return Icons.public;
      case 'тв':
      case 'iptv':
        return Icons.tv;
      case 'телефония':
      case 'phone':
        return Icons.phone;
      default:
        return Icons.devices;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final ServiceStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: AppTheme.labelSmall.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (status) {
      case ServiceStatus.active:
        return AppTheme.success.withOpacity(0.12);
      case ServiceStatus.expired:
        return AppTheme.error.withOpacity(0.12);
      case ServiceStatus.paused:
        return AppTheme.warning.withOpacity(0.12);
      case ServiceStatus.error:
        return AppTheme.error.withOpacity(0.12);
    }
  }

  Color get _textColor {
    switch (status) {
      case ServiceStatus.active:
        return AppTheme.success;
      case ServiceStatus.expired:
        return AppTheme.error;
      case ServiceStatus.paused:
        return AppTheme.warning;
      case ServiceStatus.error:
        return AppTheme.error;
    }
  }

  String get _label {
    switch (status) {
      case ServiceStatus.active:
        return 'Активна';
      case ServiceStatus.expired:
        return 'Истекла';
      case ServiceStatus.paused:
        return 'Приост.';
      case ServiceStatus.error:
        return 'Ошибка';
    }
  }
}

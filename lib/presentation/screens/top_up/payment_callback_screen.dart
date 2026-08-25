import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/domain/entities/payment_result.dart';

/// Экран результата платежа.
/// Открывается по deep link (starlink://payment/callback?...) или
/// после перехвата callback URL в WebView.
class PaymentCallbackScreen extends StatelessWidget {
  /// Query-параметры callback (status, result_code, rrn, approval_code, message).
  final Map<String, String> queryParams;

  const PaymentCallbackScreen({super.key, required this.queryParams});

  bool get _isSuccess {
    final status = queryParams['status'];
    return status == 'OK' || status == 'APPROVED';
  }

  String get _statusMessage {
    if (_isSuccess) return 'Оплата проведена успешно';
    final msg = queryParams['message'];
    if (msg != null && msg.isNotEmpty) return msg;
    final code = queryParams['result_code'];
    if (code != null) return 'Ошибка оплаты (код: $code)';
    return 'Оплата не удалась';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.orange50,
      appBar: AppBar(
        backgroundColor: AppTheme.orange50,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: _isSuccess ? AppTheme.success : AppTheme.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSuccess ? 'Успешно' : 'Ошибка',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
                textAlign: TextAlign.center,
              ),
              // Детали транзакции при успехе
              if (_isSuccess) ...[
                const SizedBox(height: 24),
                _DetailRow(
                  label: 'RRN',
                  value: queryParams['rrn'],
                ),
                _DetailRow(
                  label: 'Код авторизации',
                  value: queryParams['approval_code'],
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go(Routes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.orange500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.orange200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'На главную',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка с деталями транзакции (label: value).
class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.gray400)),
          const SizedBox(width: 8),
          Text(
            value!,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

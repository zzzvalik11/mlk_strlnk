import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/currency_formatter.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
import 'package:telecom_dashboard/domain/entities/payment_link.dart';
import 'package:telecom_dashboard/presentation/screens/top_up/top_up_view_model.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({super.key});

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topUpState = ref.watch(topUpViewModelProvider);

    // Слушаем: если получена ссылка — открываем платёжную форму / QR
    ref.listen<TopUpState>(topUpViewModelProvider, (prev, next) {
      final link = next.paymentLink;
      if (link == null) return;

      // Dart 3 pattern matching вместо link.when() —
      // freezed 4.0 генерирует некорректную сигнатуру when для sealed unions.
      switch (link) {
        case CardPaymentLink(:final clientHandlerUrl):
          // Открываем WebView с платёжной формой РСБ
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PaymentWebView(url: clientHandlerUrl),
            ),
          ).then((_) {
            // После закрытия WebView — сброс и обновление баланса
            ref.read(topUpViewModelProvider.notifier).onPaymentReturn();
          });
        case SbpPaymentLink(:final qrcodeLink, :final qrUrl):
          // Открываем QR-экран
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _SbpQrScreen(
                qrcodeLink: qrcodeLink,
                qrUrl: qrUrl,
              ),
            ),
          ).then((_) {
            ref.read(topUpViewModelProvider.notifier).onPaymentReturn();
          });
      }
    });

    final effectiveAmount = ref.read(topUpViewModelProvider.notifier).effectiveAmount;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBackButton: true, title: 'Пополнить баланс'),
            Expanded(
              child: SingleChildScrollView(
                padding: AppTheme.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Быстрые суммы ──────────────
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: TopUpNotifier.quickAmounts.map((amount) {
                        final isSelected = topUpState.selectedAmount == amount;
                        return _QuickAmountButton(
                          amount: amount,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(topUpViewModelProvider.notifier)
                                .selectQuickAmount(amount);
                            _customAmountController.clear();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // ─── Своя сумма ───────────────────
                    Text('Или введите свою сумму', style: AppTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        ref
                            .read(topUpViewModelProvider.notifier)
                            .updateCustomAmount(value);
                      },
                      decoration: InputDecoration(
                        hintText: '0,00',
                        suffixText: '₽',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: AppTheme.inputRadius,
                          borderSide: BorderSide(color: AppTheme.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppTheme.inputRadius,
                          borderSide: BorderSide(color: AppTheme.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppTheme.inputRadius,
                          borderSide: BorderSide(
                            color: AppTheme.orange500,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // ─── Итого ───────────────────────────
                    if (effectiveAmount != null && effectiveAmount > 0) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppTheme.cardRadius,
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Итого:',
                              style: AppTheme.titleMedium
                                  .copyWith(color: AppTheme.gray600),
                            ),
                            Text(
                              CurrencyFormatter.formatCurrency(effectiveAmount),
                              style: AppTheme.headlineSmall.copyWith(
                                color: AppTheme.gray900,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // ─── Ошибка ───────────────────────────
                    if (topUpState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          topUpState.error!,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    // ─── Кнопка «Оплатить» ───────────────────
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (effectiveAmount == null ||
                                effectiveAmount <= 0 ||
                                topUpState.isSubmitting)
                            ? null
                            : () => _showPaymentMethods(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.orange500,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.orange200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: topUpState.isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Оплатить',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Показать bottom sheet с выбором метода оплаты.
  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentMethodSheet(),
    );
  }
}

// ─── Кнопка быстрой суммы ──────────────────────────────────

class _QuickAmountButton extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _formatAmount(amount);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.buttonRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppTheme.buttonRadius,
            color: isSelected ? AppTheme.orange500 : Colors.white,
            border: Border.all(
              color: isSelected ? AppTheme.orange500 : AppTheme.gray200,
            ),
            boxShadow: isSelected ? null : AppTheme.cardShadow,
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ₽',
            style: AppTheme.titleMedium.copyWith(
              color: isSelected ? Colors.white : AppTheme.gray900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}

// ─── Bottom sheet с методами оплаты ──────────────────────

class _PaymentMethodSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Способ оплаты',
              style: AppTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Карта
            _PaymentMethodTile(
              icon: Icons.credit_card_rounded,
              title: 'Банковская карта',
              subtitle: 'Visa, Mastercard, МИР · РСБ',
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(topUpViewModelProvider.notifier)
                    .setPaymentMethod(PaymentMethod.card);
                ref.read(topUpViewModelProvider.notifier).requestPayLink();
              },
            ),
            const SizedBox(height: 8),
            // СБП
            _PaymentMethodTile(
              icon: Icons.qr_code_2_rounded,
              title: 'СБП',
              subtitle: 'Система быстрых платежей · QR-код',
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(topUpViewModelProvider.notifier)
                    .setPaymentMethod(PaymentMethod.sbp);
                ref.read(topUpViewModelProvider.notifier).requestPayLink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Плитка метода оплаты ──────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.cardRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.orange500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.orange500, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WebView для платёжной формы РСБ ─────────────────────

/// Полноэкранный WebView для оплаты картой через РСБ ECOMM.
/// Перехватывает callback URL по завершении 3DS / оплаты
/// и перенаправляет на экран результата.
class _PaymentWebView extends StatefulWidget {
  final String url;
  const _PaymentWebView({required this.url});

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            // прогресс загрузки (0–100)
          },
          onPageFinished: (_) {
            if (mounted && _isLoading) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (navigation) {
            final uri = navigation.url;
            // Перехватываем callback URL от РСБ
            if (_isCallbackUrl(uri)) {
              _handleCallback(uri);
              return NavigationDecision.prevent;
            }
            // Перехватываем deep link (starlink://...)
            if (uri.startsWith('${AppConstants.deepLinkScheme}://')) {
              _handleDeepLink(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Проверяет, является ли URL callback-ом от платёжной системы.
  bool _isCallbackUrl(String url) {
    final uri = Uri.parse(url);
    // Сопоставляем по хосту из AppConstants
    if (uri.host == AppConstants.paymentCallbackHost) return true;
    // Fallback: любой URL с нашим scheme
    if (url.startsWith('${AppConstants.deepLinkScheme}://')) return true;
    return false;
  }

  /// Обрабатывает callback: извлекает query-параметры и переходит на экран результата.
  void _handleCallback(String url) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    if (mounted) {
      Navigator.of(context).pop();
      context.go(
        '${Routes.paymentCallback}?${uri.query}',
      );
    }
  }

  /// Обрабатывает deep link (starlink://payment/callback?...).
  void _handleDeepLink(String url) {
    _handleCallback(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата картой'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.orange500,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Экран QR-кода для СБП ───────────────────────────────

class _SbpQrScreen extends StatelessWidget {
  final String qrcodeLink;
  final String? qrUrl;
  const _SbpQrScreen({required this.qrcodeLink, this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата через СБП'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Заглушка QR-кода
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gray300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'QR-код\n(требуется пакет qr_flutter)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // TODO: заменить на QrImageView при подключении qr_flutter
              ),
              const SizedBox(height: 24),
              Text(
                'Откройте банковское приложение\nи отсканируйте QR-код',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
              ),
              const SizedBox(height: 16),
              if (qrUrl != null)
                TextButton(
                  onPressed: () {
                    // TODO: открыть qrUrl в браузере
                  },
                  child: const Text('Открыть в браузере'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

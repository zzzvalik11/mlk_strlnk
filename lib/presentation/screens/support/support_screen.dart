import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/validators.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/screens/support/support_view_model.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  final _pinFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _messageFocusNode = FocusNode();

  String? _pinError;
  String? _emailError;
  String? _phoneError;
  String? _messageError;
  bool _phoneFormatted = false;

  @override
  void dispose() {
    _pinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _pinFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _pinError = null;
      _emailError = null;
      _phoneError = null;
      _messageError = null;
    });
  }

  void _onSubmit() {
    _clearErrors();
    setState(() {
      _pinError = Validators.validatePin(_pinController.text);
      _emailError = Validators.validateEmail(_emailController.text);
      _phoneError = Validators.validatePhone(_phoneController.text);
      if (_messageController.text.trim().isEmpty) {
        _messageError = 'Введите сообщение';
      }
    });
    if (_pinError != null || _emailError != null ||
        _phoneError != null || _messageError != null) return;

    ref.read(supportViewModelProvider.notifier).submitTicket(
      pin: _pinController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      message: _messageController.text,
    );
  }

  void _onPhoneChanged(String value) {
    if (value.length == 1 && value == '+') return;
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    String formatted;
    if (digits.startsWith('8') && digits.length > 1) {
      formatted = '+7${digits.substring(1)}';
    } else if (digits.startsWith('7')) {
      formatted = '+$digits';
    } else if (digits.isNotEmpty) {
      formatted = '+7$digits';
    } else {
      formatted = '';
    }
    if (formatted != value && formatted.isNotEmpty) {
      _phoneController.text = formatted;
      _phoneController.selection = TextSelection.collapsed(
        offset: formatted.length,
      );
    }
    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportViewModelProvider);
    final isSubmitting = state is SupportFormSubmitting;
    final isAuthenticated = ref.watch(authProvider).valueOrNull != null;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            if (isAuthenticated)
              const AppHeader(showBackButton: true, title: 'Поддержка'),
            Expanded(
              child: SingleChildScrollView(
                padding: AppTheme.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text('Поддержка', style: AppTheme.headlineLarge),
                      const SizedBox(height: 24),
                      if (state is SupportFormSuccess)
                        _buildSuccessState(state.ticket.id)
                      else ...[
                        // ─── ПИН ─────────────────
                        _buildLabel('ПИН-код'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_pinError != null) setState(() => _pinError = null);
                            ref.read(supportViewModelProvider.notifier).reset();
                          },
                          onSubmitted: (_) => _emailFocusNode.requestFocus(),
                          decoration: _inputDecoration(
                            hintText: '039103',
                            prefixIcon: Icons.dialpad_rounded,
                            errorText: _pinError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ─── E-mail ───────────────
                        _buildLabel('E-mail'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          onChanged: (_) {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                          onSubmitted: (_) => _phoneFocusNode.requestFocus(),
                          decoration: _inputDecoration(
                            hintText: 'example@mail.ru',
                            prefixIcon: Icons.mail_outline_rounded,
                            errorText: _emailError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ─── Телефон ──────────────
                        _buildLabel('Телефон'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onChanged: _onPhoneChanged,
                          onSubmitted: (_) => _messageFocusNode.requestFocus(),
                          decoration: _inputDecoration(
                            hintText: '+79001234567',
                            prefixIcon: Icons.phone_outline_rounded,
                            errorText: _phoneError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ─── Сообщение ────────────
                        _buildLabel('Сообщение для оператора'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 5,
                          minLines: 3,
                          onChanged: (_) {
                            if (_messageError != null) setState(() => _messageError = null);
                          },
                          decoration: _inputDecoration(
                            hintText: 'Опишите проблему или вопрос',
                            prefixIcon: Icons.chat_bubble_outline_rounded,
                            errorText: _messageError,
                          ),
                        ),
                        // Error
                        if (state is SupportFormError)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              (state as SupportFormError).message,
                              style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Submit
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orange500,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.orange200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Отправить',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      // ─── FAQ ────────────────────────
                      Text('Частые вопросы', style: AppTheme.titleMedium),
                      const SizedBox(height: 8),
                      const _FaqItem(
                        question: 'Как пополнить баланс?',
                        answer: 'Перейдите на главный экран и нажмите кнопку «Пополнить». Выберите удобную сумму или введите свою. Оплата производится мгновенно.',
                      ),
                      const _FaqItem(
                        question: 'Забыл пароль',
                        answer: 'Обратитесь в поддержку через форму выше или позвоните по телефону горячей линии для восстановления доступа к аккаунту.',
                      ),
                      const _FaqItem(
                        question: 'Как изменить тариф?',
                        answer: 'Откройте раздел «Активные услуги» на главном экране. Выберите услугу, которую хотите изменить, и следуйте инструкциям.',
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: '',
      prefixIcon: Icon(prefixIcon, color: AppTheme.gray500),
      errorText: errorText,
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
        borderSide: BorderSide(color: AppTheme.orange500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppTheme.inputRadius,
        borderSide: BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppTheme.inputRadius,
        borderSide: BorderSide(color: AppTheme.error, width: 2),
      ),
    );
  }

  Widget _buildSuccessState(String ticketId) {
    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.success),
          const SizedBox(height: 16),
          Text('Обращение отправлено', style: AppTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Номер: $ticketId',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: 8),
          Text(
            'Мы ответим вам в ближайшее время',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              ref.read(supportViewModelProvider.notifier).reset();
              _pinController.clear();
              _emailController.clear();
              _phoneController.clear();
              _messageController.clear();
            },
            child: Text(
              'Отправить ещё',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.orange500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── FAQ Item ────────────────────────────────────────────

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          question,
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.expand_more_rounded, color: AppTheme.gray400, size: 20),
        children: [
          Text(answer, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}

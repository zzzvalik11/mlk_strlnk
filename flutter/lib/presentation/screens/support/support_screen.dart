import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/presentation/screens/support/support_view_model.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    ref.read(supportViewModelProvider.notifier).submitTicket(
      subject: _subjectController.text,
      description: _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportViewModelProvider);
    final isSubmitting = state is SupportFormSubmitting;

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // ─── Title ──────────────────────
              Text(
                'Поддержка',
                style: AppTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              // ─── Form or Success ────────────
              if (state is SupportFormSuccess)
                _buildSuccessState(state.ticket.id)
              else ...[
                // Subject
                Text(
                  'Тема обращения',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Опишите кратко',
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
                      borderSide:
                          BorderSide(color: AppTheme.orange500, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'Описание',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Подробно опишите проблему или вопрос',
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
                      borderSide:
                          BorderSide(color: AppTheme.orange500, width: 2),
                    ),
                  ),
                ),
                // Error
                if (state is SupportFormError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      (state as SupportFormError).message,
                      style:
                          AppTheme.bodySmall.copyWith(color: AppTheme.error),
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
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
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
              Text(
                'Частые вопросы',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _FaqItem(
                question: 'Как пополнить баланс?',
                answer:
                    'Перейдите на главный экран и нажмите кнопку «Пополнить». Выберите удобную сумму или введите свою. Оплата производится мгновенно.',
              ),
              _FaqItem(
                question: 'Забыл пароль',
                answer:
                    'Обратитесь в поддержку через форму выше или позвоните по телефону горячей линии для восстановления доступа к аккаунту.',
              ),
              _FaqItem(
                question: 'Как изменить тариф?',
                answer:
                    'Откройте раздел «Активные услуги» на главном экране. Выберите услугу, которую хотите изменить, и следуйте инструкциям.',
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
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
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: AppTheme.success,
          ),
          const SizedBox(height: 16),
          Text(
            'Обращение отправлено',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Номер: $ticketId',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.gray500,
            ),
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
              _subjectController.clear();
              _descriptionController.clear();
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
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.expand_more_rounded,
          color: AppTheme.gray400,
          size: 20,
        ),
        children: [
          Text(
            answer,
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

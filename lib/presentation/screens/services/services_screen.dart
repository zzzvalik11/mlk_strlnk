import 'package:flutter/material.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';

/// Mock service plans for demonstration.
class ServicePlan {
  final String id;
  final String name;
  final String category;
  final double cost;
  final String description;
  final bool isMain;
  final List<String> features;

  const ServicePlan({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    required this.description,
    required this.isMain,
    required this.features,
  });
}

class ServicesScreen extends StatefulWidget {
  final String? currentServiceId;

  const ServicesScreen({super.key, this.currentServiceId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _mainPlans = [
    ServicePlan(
      id: 'svc-1',
      name: '100/100 30 day',
      category: 'Интернет',
      cost: 225,
      description: '100 Мбит/с — 100 Мбит/с, 30 дней',
      isMain: true,
      features: ['Скорость до 100 Мбит/с', 'Объём 100 ГБ', 'Действие 30 дней'],
    ),
    ServicePlan(
      id: 'svc-2',
      name: '200/200 30 day',
      category: 'Интернет',
      cost: 350,
      description: '200 Мбит/с — 200 Мбит/с, 30 дней',
      isMain: true,
      features: ['Скорость до 200 Мбит/с', 'Объём 200 ГБ', 'Действие 30 дней'],
    ),
    ServicePlan(
      id: 'svc-3',
      name: '500/500 30 day',
      category: 'Интернет',
      cost: 550,
      description: '500 Мбит/с — 500 Мбит/с, 30 дней',
      isMain: true,
      features: ['Скорость до 500 Мбит/с', 'Безлимитный объём', 'Действие 30 дней', 'Приоритетная поддержка'],
    ),
  ];

  static const _additionalPlans = [
    ServicePlan(
      id: 'add-1',
      name: 'IPTV Базовый',
      category: 'ТВ',
      cost: 150,
      description: '100+ каналов',
      isMain: false,
      features: ['100+ телеканалов', 'HD-качество', 'Архив 7 дней'],
    ),
    ServicePlan(
      id: 'add-2',
      name: 'IPTV Расширенный',
      category: 'ТВ',
      cost: 250,
      description: '200+ каналов',
      isMain: false,
      features: ['200+ телеканалов', 'Full HD-качество', 'Архив 14 дней', 'Запись передач'],
    ),
    ServicePlan(
      id: 'add-3',
      name: 'Облачная АТС',
      category: 'Телефония',
      cost: 199,
      description: 'Виртуальная АТС',
      isMain: false,
      features: ['Виртуальный номер', 'До 5 сотрудников', 'Голосовая почта', 'Переадресация'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.orange50,
      appBar: AppBar(
        title: const Text('Услуги и тарифы'),
        backgroundColor: AppTheme.orange50,
        foregroundColor: AppTheme.gray900,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.orange500,
          unselectedLabelColor: AppTheme.gray500,
          indicatorColor: AppTheme.orange500,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Основные'),
            Tab(text: 'Дополнительные'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanList(_mainPlans),
          _buildPlanList(_additionalPlans),
        ],
      ),
    );
  }

  Widget _buildPlanList(List<ServicePlan> plans) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isCurrent = plan.id == widget.currentServiceId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isCurrent ? null : () => _showChangeDialog(context, plan),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.orange500.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrent
                      ? Border.all(color: AppTheme.orange500, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    plan.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.gray900,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.orange500,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Активен',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.description,
                                style: const TextStyle(fontSize: 14, color: AppTheme.gray500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${plan.cost.toInt()} ₽',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const Text(
                              '/ мес',
                              style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...plan.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.success),
                            const SizedBox(width: 8),
                            Text(f, style: const TextStyle(fontSize: 14, color: AppTheme.gray700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangeDialog(BuildContext context, ServicePlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Сменить тариф?'),
        content: Text('Вы уверены, что хотите перейти на «${plan.name}» (${plan.cost.toInt()} ₽/мес)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Заявка на смену тарифа «${plan.name}» отправлена'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.orange500),
            child: const Text('Подтвердить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

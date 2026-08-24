import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/routes.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/empty_state.dart';
import 'package:telecom_dashboard/core/widgets/error_state.dart';
import 'package:telecom_dashboard/core/widgets/loading_spinner.dart';
import 'package:telecom_dashboard/domain/entities/news_item.dart';
import 'package:telecom_dashboard/presentation/screens/news/news_view_model.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsListViewModelProvider.notifier).loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsListViewModelProvider);

    return RefreshIndicator(
      color: AppTheme.orange500,
      onRefresh: () => ref.read(newsListViewModelProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Новости', style: AppTheme.headlineLarge),
            ),
            const SizedBox(height: 16),
            switch (state) {
              NewsListLoading() => const SizedBox(height: 300, child: Center(child: LoadingSpinner())),
              NewsListError(:final message) => SizedBox(
                height: 300,
                child: ErrorState(message: message, onRetry: () => ref.read(newsListViewModelProvider.notifier).refresh()),
              ),
              NewsListEmpty() => const SizedBox(
                height: 300,
                child: EmptyState(icon: Icons.article_outlined, message: 'Нет новостей', subtitle: 'Здесь появятся новости и обновления'),
              ),
              NewsListLoaded(:final items, :final hasMore) => Column(
                children: [
                  for (int i = 0; i < items.length; i++)
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: i < items.length - 1 ? 10 : 0),
                      child: _NewsListItem(
                        item: items[i],
                        onTap: () => context.push('${Routes.news}/${items[i].id}'),
                      ),
                    ),
                  if (hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: TextButton(
                          onPressed: () => ref.read(newsListViewModelProvider.notifier).loadMore(),
                          child: const Text('Загрузить ещё'),
                        ),
                      ),
                    ),
                ],
              ),
              NewsListInitial() => const SizedBox(height: 300, child: Center(child: LoadingSpinner())),
            },
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─── News List Item ───────────────────────────────────

class _NewsListItem extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;

  const _NewsListItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.cardRadius,
      child: Container(
        padding: AppTheme.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
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
              child: const Icon(Icons.article_rounded, color: AppTheme.orange500, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(DateFormatter.formatDate(item.publishedAt), style: AppTheme.labelSmall),
                      if (item.readCount != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.visibility_outlined, size: 12, color: AppTheme.gray400),
                        const SizedBox(width: 2),
                        Text('${item.readCount}', style: AppTheme.labelSmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.gray400, size: 20),
          ],
        ),
      ),
    );
  }
}

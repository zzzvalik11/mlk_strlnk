import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/core/widgets/app_header.dart';
import 'package:telecom_dashboard/core/utils/date_formatter.dart';
import 'package:telecom_dashboard/core/widgets/error_state.dart';
import 'package:telecom_dashboard/core/widgets/loading_spinner.dart';
import 'package:telecom_dashboard/presentation/providers/news_provider.dart';

class NewsDetailScreen extends ConsumerWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(newsDetailProvider(newsId));

    return Scaffold(
      backgroundColor: AppTheme.orange50,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(showBackButton: true, title: 'Новость'),
            Expanded(
              child: detailAsync.when(
                loading: () => const LoadingSpinner(),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(newsDetailProvider(newsId)),
                ),
                data: (news) => SingleChildScrollView(
                  padding: AppTheme.screenPadding,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Title ─────────────────────
                        Text(news.title, style: AppTheme.headlineMedium),
                        const SizedBox(height: 8),
                        // ─── Date + Read Count ──────────
                        Row(
                          children: [
                            Text(
                              DateFormatter.formatDateTime(news.publishedAt),
                              style: AppTheme.bodySmall,
                            ),
                            if (news.readCount != null) ...[
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: AppTheme.gray400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${news.readCount} просмотров',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ─── Tags ────────────────────────
                        if (news.tags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: news.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange500.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.orange500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 20),
                        // ─── Image ───────────────────────
                        if (news.imageUrl != null)
                          ClipRRect(
                            borderRadius: AppTheme.cardRadius,
                            child: Image.network(
                              news.imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        if (news.imageUrl != null) const SizedBox(height: 20),
                        // ─── Summary / Body ─────────────
                        Text(
                          news.summary,
                          style: AppTheme.bodyLarge.copyWith(
                            height: 1.7,
                            color: AppTheme.gray700,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

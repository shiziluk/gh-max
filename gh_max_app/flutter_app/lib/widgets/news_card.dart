// 新闻情绪卡片组件

import 'package:flutter/material.dart';
import '../models/news_data.dart';
import '../utils/theme.dart';

class NewsCard extends StatelessWidget {
  final NewsSentiment newsSentiment;

  const NewsCard({super.key, required this.newsSentiment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.newspaper, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      '消息面情绪',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildSentimentBadge(),
              ],
            ),

            const SizedBox(height: 16),

            // 情绪统计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '利多',
                  newsSentiment.bullCount,
                  AppTheme.bullColor,
                ),
                _buildStatItem(
                  '中性',
                  newsSentiment.neutralCount,
                  AppTheme.neutralColor,
                ),
                _buildStatItem(
                  '利空',
                  newsSentiment.bearCount,
                  AppTheme.bearColor,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 情绪比例条
            _buildSentimentBar(),

            const SizedBox(height: 16),

            // 最新新闻列表
            if (newsSentiment.news.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '最新消息',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...newsSentiment.news.take(5).map((news) => _buildNewsItem(news)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(newsSentiment.sentimentColor).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            newsSentiment.sentimentScore > 55
                ? Icons.trending_up
                : newsSentiment.sentimentScore < 45
                    ? Icons.trending_down
                    : Icons.trending_flat,
            size: 16,
            color: Color(newsSentiment.sentimentColor),
          ),
          const SizedBox(width: 4),
          Text(
            '${newsSentiment.sentimentScore.toStringAsFixed(0)}分',
            style: TextStyle(
              color: Color(newsSentiment.sentimentColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentBar() {
    final total = newsSentiment.totalNews > 0
        ? newsSentiment.totalNews
        : 1;

    final bullPct = newsSentiment.bullCount / total;
    final neutralPct = newsSentiment.neutralCount / total;
    final bearPct = newsSentiment.bearCount / total;

    return Container(
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: (bullPct * 100).round().clamp(1, 100),
            child: Container(color: AppTheme.bullColor),
          ),
          Expanded(
            flex: (neutralPct * 100).round().clamp(1, 100),
            child: Container(color: AppTheme.neutralColor),
          ),
          Expanded(
            flex: (bearPct * 100).round().clamp(1, 100),
            child: Container(color: AppTheme.bearColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(NewsItem news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Color(news.sentimentColor),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(news.sentimentColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  news.sentiment,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(news.sentimentColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            news.content,
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

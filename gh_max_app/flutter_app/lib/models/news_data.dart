// 新闻情绪数据模型

class NewsSentiment {
  final int bullCount;
  final int bearCount;
  final int neutralCount;
  final int totalNews;
  final double sentimentScore;
  final String overall;
  final List<NewsItem> news;

  NewsSentiment({
    required this.bullCount,
    required this.bearCount,
    required this.neutralCount,
    required this.totalNews,
    required this.sentimentScore,
    required this.overall,
    this.news = const [],
  });

  factory NewsSentiment.fromJson(Map<String, dynamic> json) {
    return NewsSentiment(
      bullCount: (json['bull_count'] ?? 0).toInt(),
      bearCount: (json['bear_count'] ?? 0).toInt(),
      neutralCount: (json['neutral_count'] ?? 0).toInt(),
      totalNews: (json['total_news'] ?? 0).toInt(),
      sentimentScore: (json['sentiment_score'] ?? 50).toDouble(),
      overall: json['overall'] ?? '中性',
      news: (json['news'] as List<dynamic>?)
          ?.map((e) => NewsItem.fromJson(e))
          .toList() ?? [],
    );
  }

  // 获取情绪颜色
  int get sentimentColor {
    if (sentimentScore >= 60) return 0xFF4CAF50; // 偏多 - 绿色
    if (sentimentScore >= 40) return 0xFFFFC107; // 中性 - 黄色
    return 0xFFF44336; // 偏空 - 红色
  }
}

class NewsItem {
  final String content;
  final String sentiment;

  NewsItem({
    required this.content,
    required this.sentiment,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      content: json['content'] ?? '',
      sentiment: json['sentiment'] ?? '中性',
    );
  }

  int get sentimentColor {
    switch (sentiment) {
      case '利多':
        return 0xFF4CAF50;
      case '利空':
        return 0xFFF44336;
      default:
        return 0xFF9E9E9E;
    }
  }
}

// 评分数据模型

class ScoreResult {
  final double totalScore;
  final String trend;
  final String action;
  final Map<String, ScoreItem> scores;
  final List<String> techSignals;
  final TradePositions? positions;
  final String timestamp;

  ScoreResult({
    required this.totalScore,
    required this.trend,
    required this.action,
    required this.scores,
    this.techSignals = const [],
    this.positions,
    required this.timestamp,
  });

  factory ScoreResult.fromJson(Map<String, dynamic> json) {
    Map<String, ScoreItem> scoreMap = {};
    if (json['scores'] != null) {
      (json['scores'] as Map<String, dynamic>).forEach((key, value) {
        scoreMap[key] = ScoreItem.fromJson(value);
      });
    }

    return ScoreResult(
      totalScore: (json['total_score'] ?? 50).toDouble(),
      trend: json['trend'] ?? '未知',
      action: json['action'] ?? '',
      scores: scoreMap,
      techSignals: (json['tech_signals'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      positions: json['positions'] != null
          ? TradePositions.fromJson(json['positions'])
          : null,
      timestamp: json['timestamp'] ?? '',
    );
  }

  // 获取趋势颜色
  int get trendColor {
    if (totalScore >= 60) return 0xFF4CAF50; // 强势多头 - 绿色
    if (totalScore >= 50) return 0xFF8BC34A; // 偏多 - 浅绿
    if (totalScore >= 40) return 0xFFFFC107; // 中性 - 黄色
    if (totalScore >= 30) return 0xFFFF9800; // 偏空 - 橙色
    return 0xFFF44336; // 强势空头 - 红色
  }

  // 获取趋势图标
  String get trendIcon {
    if (totalScore >= 60) return '↑↑';
    if (totalScore >= 50) return '↑';
    if (totalScore >= 40) return '↔';
    if (totalScore >= 30) return '↓';
    return '↓↓';
  }
}

class ScoreItem {
  final String name;
  final double score;
  final int weight;

  ScoreItem({
    required this.name,
    required this.score,
    required this.weight,
  });

  factory ScoreItem.fromJson(Map<String, dynamic> json) {
    return ScoreItem(
      name: json['name'] ?? '',
      score: (json['score'] ?? 50).toDouble(),
      weight: (json['weight'] ?? 0).toInt(),
    );
  }

  // 判断分数方向
  String get direction {
    if (score >= 60) return '利多';
    if (score >= 40) return '中性';
    return '利空';
  }

  // 获取分数颜色
  int get color {
    if (score >= 60) return 0xFF4CAF50;
    if (score >= 40) return 0xFFFFC107;
    return 0xFFF44336;
  }
}

class TradePositions {
  final double? entryStrong;
  final double? entryWeak;
  final double? entry;
  final double support;
  final double resistance;
  final double? stopLoss;
  final double? takeProfit;

  TradePositions({
    this.entryStrong,
    this.entryWeak,
    this.entry,
    required this.support,
    required this.resistance,
    this.stopLoss,
    this.takeProfit,
  });

  factory TradePositions.fromJson(Map<String, dynamic> json) {
    return TradePositions(
      entryStrong: json['entry_strong']?.toDouble(),
      entryWeak: json['entry_weak']?.toDouble(),
      entry: json['entry']?.toDouble(),
      support: (json['support'] ?? 0).toDouble(),
      resistance: (json['resistance'] ?? 0).toDouble(),
      stopLoss: json['stop_loss']?.toDouble(),
      takeProfit: json['take_profit']?.toDouble(),
    );
  }
}

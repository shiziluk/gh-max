// 技术指标数据模型

class TechnicalIndicators {
  final TechnicalCurrent? current;
  final Map<String, Divergence>? divergences;
  final List<Pattern> patterns;
  final String trend;

  TechnicalIndicators({
    this.current,
    this.divergences,
    this.patterns = const [],
    this.trend = '未知',
  });

  factory TechnicalIndicators.fromJson(Map<String, dynamic> json) {
    Map<String, Divergence>? divMap;
    if (json['divergences'] != null) {
      divMap = {};
      (json['divergences'] as Map<String, dynamic>).forEach((key, value) {
        divMap![key] = Divergence.fromJson(value);
      });
    }

    return TechnicalIndicators(
      current: json['current'] != null 
          ? TechnicalCurrent.fromJson(json['current']) 
          : null,
      divergences: divMap,
      patterns: (json['patterns'] as List<dynamic>?)
          ?.map((e) => Pattern.fromJson(e))
          .toList() ?? [],
      trend: json['trend'] ?? '未知',
    );
  }
}

class TechnicalCurrent {
  final double close;
  final double? ma5;
  final double? ma10;
  final double? ma20;
  final double? ma60;
  final double dif;
  final double dea;
  final double macd;
  final double rsi;
  final double k;
  final double d;
  final double j;
  final double? bbUpper;
  final double? bbMiddle;
  final double? bbLower;

  TechnicalCurrent({
    required this.close,
    this.ma5,
    this.ma10,
    this.ma20,
    this.ma60,
    required this.dif,
    required this.dea,
    required this.macd,
    required this.rsi,
    required this.k,
    required this.d,
    required this.j,
    this.bbUpper,
    this.bbMiddle,
    this.bbLower,
  });

  factory TechnicalCurrent.fromJson(Map<String, dynamic> json) {
    return TechnicalCurrent(
      close: (json['close'] ?? 0).toDouble(),
      ma5: json['ma5']?.toDouble(),
      ma10: json['ma10']?.toDouble(),
      ma20: json['ma20']?.toDouble(),
      ma60: json['ma60']?.toDouble(),
      dif: (json['dif'] ?? 0).toDouble(),
      dea: (json['dea'] ?? 0).toDouble(),
      macd: (json['macd'] ?? 0).toDouble(),
      rsi: (json['rsi'] ?? 50).toDouble(),
      k: (json['k'] ?? 50).toDouble(),
      d: (json['d'] ?? 50).toDouble(),
      j: (json['j'] ?? 50).toDouble(),
      bbUpper: json['bb_upper']?.toDouble(),
      bbMiddle: json['bb_middle']?.toDouble(),
      bbLower: json['bb_lower']?.toDouble(),
    );
  }
}

class Divergence {
  final String type;
  final String signal;
  final int strength;

  Divergence({
    required this.type,
    required this.signal,
    required this.strength,
  });

  factory Divergence.fromJson(Map<String, dynamic> json) {
    return Divergence(
      type: json['type'] ?? '无背离',
      signal: json['signal'] ?? '无信号',
      strength: (json['strength'] ?? 0).toInt(),
    );
  }

  bool get hasDivergence => type != '无背离' && type != '数据不足';
}

class Pattern {
  final String name;
  final String signal;
  final int strength;
  final String description;

  Pattern({
    required this.name,
    required this.signal,
    required this.strength,
    required this.description,
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      name: json['name'] ?? '',
      signal: json['signal'] ?? '中性',
      strength: (json['strength'] ?? 0).toInt(),
      description: json['description'] ?? '',
    );
  }
}

// 市场数据模型

class GoldPrice {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePct;
  final double open;
  final double high;
  final double low;
  final String time;

  GoldPrice({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePct,
    required this.open,
    required this.high,
    required this.low,
    required this.time,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      symbol: json['symbol'] ?? 'XAUUSD',
      name: json['name'] ?? '现货黄金',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePct: (json['change_pct'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'price': price,
    'change': change,
    'change_pct': changePct,
    'open': open,
    'high': high,
    'low': low,
    'time': time,
  };
}

class DxyIndex {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePct;

  DxyIndex({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePct,
  });

  factory DxyIndex.fromJson(Map<String, dynamic> json) {
    return DxyIndex(
      symbol: json['symbol'] ?? 'DXY',
      name: json['name'] ?? '美元指数',
      price: (json['price'] ?? 100).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePct: (json['change_pct'] ?? 0).toDouble(),
    );
  }
}

class BondData {
  final String name;
  final double value;
  final double change;

  BondData({
    required this.name,
    required this.value,
    required this.change,
  });

  factory BondData.fromJson(Map<String, dynamic> json) {
    return BondData(
      name: json['name'] ?? '美国10年期国债',
      value: (json['value'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
    );
  }
}

class VixData {
  final String name;
  final double value;

  VixData({
    required this.name,
    required this.value,
  });

  factory VixData.fromJson(Map<String, dynamic> json) {
    return VixData(
      name: json['name'] ?? 'VIX恐慌指数',
      value: (json['value'] ?? 20).toDouble(),
    );
  }
}

class MarketData {
  final GoldPrice? gold;
  final DxyIndex? dxy;
  final BondData? bond10y;
  final VixData? vix;
  final String timestamp;

  MarketData({
    this.gold,
    this.dxy,
    this.bond10y,
    this.vix,
    required this.timestamp,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      gold: json['gold'] != null ? GoldPrice.fromJson(json['gold']) : null,
      dxy: json['dxy'] != null ? DxyIndex.fromJson(json['dxy']) : null,
      bond10y: json['bond_10y'] != null ? BondData.fromJson(json['bond_10y']) : null,
      vix: json['vix'] != null ? VixData.fromJson(json['vix']) : null,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

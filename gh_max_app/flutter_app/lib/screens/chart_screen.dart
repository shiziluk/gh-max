// 图表页面 - 独立页面，包含K线图和技术指标图表

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _priceHistory = [];
  List<dynamic> _scoreHistory = [];
  bool _isLoading = true;
  String _selectedPeriod = '1D';
  String _selectedSource = 'jinshi';

  final List<String> _periods = ['1D', '1W', '1M', '3M', '1Y'];
  final List<String> _sources = ['akshare', 'jinshi'];
  final List<String> _sourceLabels = ['AkShare', '金十数据'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 调试日志
    debugPrint('📊 [图表页面] _loadData 开始');
    debugPrint('📊 [图表页面] _selectedSource = $_selectedSource');
    debugPrint('📊 [图表页面] _selectedPeriod = $_selectedPeriod');

    final days = _getDaysFromPeriod(_selectedPeriod);
    final priceData = await ApiService.getMarketHistory(days: days, source: _selectedSource);
    final scoreData = await ApiService.getScoreHistory(days: days);

    // 调试日志
    debugPrint('📊 [图表页面] priceData 长度 = ${priceData?.length ?? 0}');
    debugPrint('📊 [图表页面] 应显示货币符号 = ${_selectedSource == 'jinshi' ? '¥' : '\$'}');

    setState(() {
      // 反转数据，使最新数据显示在图表右侧（符合人类阅读习惯）
      _priceHistory = (priceData ?? []).reversed.toList();
      _scoreHistory = (scoreData ?? []).reversed.toList();
      _isLoading = false;
    });
  }

  int _getDaysFromPeriod(String period) {
    switch (period) {
      case '1D':
        return 3;
      case '1W':
        return 7;
      case '1M':
        return 30;
      case '3M':
        return 90;
      case '1Y':
        return 365;
      default:
        return 7;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.show_chart, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 8),
            const Text('图表分析'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '行情图表'),
            Tab(text: '评分走势'),
          ],
        ),
        actions: [
          _buildSourceSelector(),
          _buildPeriodSelector(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPriceChart(),
                _buildScoreChart(),
              ],
            ),
    );
  }

  Widget _buildSourceSelector() {
    return ToggleButtons(
      isSelected: _sources.map((source) => _selectedSource == source).toList(),
      onPressed: (index) {
        setState(() => _selectedSource = _sources[index]);
        _loadData();
      },
      selectedColor: Colors.white,
      color: Colors.grey,
      fillColor: AppTheme.primaryColor,
      borderColor: AppTheme.primaryColor.withOpacity(0.5),
      borderWidth: 1,
      borderRadius: BorderRadius.circular(8),
      children: _sourceLabels.map((label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(label),
      )).toList(),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: _periods.map((period) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: _selectedPeriod == period
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.transparent,
              foregroundColor: _selectedPeriod == period
                  ? AppTheme.primaryColor
                  : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() => _selectedPeriod = period);
              _loadData();
            },
            child: Text(period),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceChart() {
    if (_priceHistory.isEmpty) {
      return _buildEmptyState('暂无行情数据');
    }

    // 调试信息
    debugPrint('图表页面 _selectedSource = $_selectedSource');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 最新价格
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('现货黄金'),
                        Text(
                          _priceHistory.isNotEmpty
                              ? '${_selectedSource == 'jinshi' ? '¥' : '\$'}${(_priceHistory.first['gold_price'] ?? 0).toStringAsFixed(2)}'
                              : '--',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getPriceChangeColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 图表
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        _priceLineChartData(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 统计信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('开盘', _priceHistory.isNotEmpty
                            ? (_priceHistory.last['gold_open'] ?? 0).toStringAsFixed(2)
                            : '--'),
                        _buildStatItem('最高', _getHighPrice().toStringAsFixed(2)),
                        _buildStatItem('最低', _getLowPrice().toStringAsFixed(2)),
                        _buildStatItem('涨跌', _getPriceChange().toStringAsFixed(2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 美元指数图表
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('美元指数'),
                        Text(
                          _priceHistory.isNotEmpty
                              ? '${(_priceHistory.last['dxy_price'] ?? 0).toStringAsFixed(2)}'
                              : '--',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        _usdLineChartData(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChart() {
    if (_scoreHistory.isEmpty) {
      return _buildEmptyState('暂无评分数据');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GH-Max 综合评分走势'),
                        Text(
                          _scoreHistory.isNotEmpty
                              ? '${(_scoreHistory.first['total_score'] ?? 50).toStringAsFixed(1)}'
                              : '--',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(_scoreHistory.isNotEmpty
                                ? (_scoreHistory.first['total_score'] ?? 50).toDouble()
                                : 50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        _scoreLineChartData(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 子维度评分
                    if (_scoreHistory.isNotEmpty)
                      _buildSubScores(_scoreHistory.first),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubScores(Map<String, dynamic> latestScore) {
    final subScores = [
      {'name': '宏观数据', 'key': 'macro_score', 'color': Colors.blue},
      {'name': '消息面', 'key': 'news_score', 'color': Colors.green},
      {'name': '技术面', 'key': 'technical_score', 'color': Colors.orange},
      {'name': '美元指数', 'key': 'usd_score', 'color': Colors.purple},
      {'name': '美债利率', 'key': 'bond_score', 'color': Colors.cyan},
    ];

    return Column(
      children: subScores.map((item) {
        final score = (latestScore[item['key']] ?? 50).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name'] as String),
                  Text('${score.toStringAsFixed(1)}'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  LineChartData _priceLineChartData() {
    if (_priceHistory.isEmpty) {
      return LineChartData();
    }

    List<FlSpot> spots = [];
    double minPrice = double.maxFinite;
    double maxPrice = double.minPositive;

    for (int i = 0; i < _priceHistory.length; i++) {
      final price = (_priceHistory[i]['gold_price'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      if (price < minPrice) minPrice = price;
      if (price > maxPrice) maxPrice = price;
    }

    final range = maxPrice - minPrice;
    if (range == 0 || spots.length < 2) {
      return LineChartData(lineBarsData: [
        LineChartBarData(spots: spots, isCurved: true, barWidth: 2, color: AppTheme.primaryColor)
      ]);
    }
    minPrice -= range * 0.1;
    maxPrice += range * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: range / 5,
        verticalInterval: (_priceHistory.length / 5).ceil().toDouble(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[800],
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[800],
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (_priceHistory.length / 4).ceil().toDouble(),
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _priceHistory.length) {
                final timestamp = _priceHistory[index]['timestamp'] ?? '';
                return Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(fontSize: 11),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: range / 4,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[800]!),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: _getPriceChangeColor(),
          barWidth: 2,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            color: _getPriceChangeColor().withOpacity(0.1),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3,
              color: _getPriceChangeColor(),
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: (_priceHistory.length - 1).toDouble(),
      minY: minPrice,
      maxY: maxPrice,
    );
  }

  LineChartData _usdLineChartData() {
    // 检查是否有美元指数数据（支持 dxy_price 字段）
    bool hasUsdData = _priceHistory.any((item) => 
        item['dxy_price'] != null && item['dxy_price'] != 0
    );
    
    if (!hasUsdData) {
      return LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[800]!),
        ),
        lineBarsData: [],
        minX: 0,
        maxX: 10,
        minY: 90,  // 美元指数通常在90-110之间
        maxY: 110,
      );
    }

    // 过滤出有美元指数数据的条目
    final validData = _priceHistory.where((item) {
      final usdVal = item['dxy_price'];
      return usdVal != null && usdVal != 0;
    }).toList();

    List<FlSpot> spots = [];
    double minVal = double.maxFinite;
    double maxVal = double.minPositive;

    for (int i = 0; i < validData.length; i++) {
      final value = (validData[i]['dxy_price'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
      if (value < minVal) minVal = value;
      if (value > maxVal) maxVal = value;
    }

    final range = maxVal - minVal;
    minVal -= range * 0.1;
    maxVal += range * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: range / 3,
        verticalInterval: (validData.length / 3).ceil().toDouble(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[800],
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[800],
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (validData.length / 4).ceil().toDouble(),
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < validData.length) {
                final timestamp = validData[index]['timestamp'] ?? '';
                return Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(fontSize: 11),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: range / 4,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[800]!),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: Colors.purple,
          barWidth: 2,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.purple.withOpacity(0.1),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3,
              color: Colors.purple,
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: (validData.length - 1).toDouble(),
      minY: minVal,
      maxY: maxVal,
    );
  }

  String _formatTimestamp(String timestamp) {
    if (timestamp.length >= 19) {
      // 格式化为: YYYY-MM-DD HH:MM
      return '${timestamp.substring(5, 10)} ${timestamp.substring(11, 16)}';
    } else if (timestamp.length >= 10) {
      return timestamp.substring(5, 10);
    }
    return timestamp;
  }

  LineChartData _scoreLineChartData() {
    if (_scoreHistory.isEmpty) {
      return LineChartData();
    }

    List<FlSpot> spots = [];

    for (int i = 0; i < _scoreHistory.length; i++) {
      final score = (_scoreHistory[i]['total_score'] ?? 50).toDouble();
      spots.add(FlSpot(i.toDouble(), score));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: (_scoreHistory.length / 5).ceil().toDouble(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: value == 50 ? Colors.grey[600] : Colors.grey[800],
          strokeWidth: value == 50 ? 2 : 1,
          dashArray: value == 50 ? [5, 5] : null,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[800],
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (_scoreHistory.length / 4).ceil().toDouble(),
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < _scoreHistory.length) {
                final timestamp = _scoreHistory[index]['timestamp'] ?? '';
                return Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(fontSize: 11),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[800]!),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppTheme.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: _getScoreColor(spot.y),
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
        ),
      ],
      minX: 0,
      maxX: (_scoreHistory.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('刷新')),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  double _getHighPrice() {
    double high = double.minPositive;
    for (var item in _priceHistory) {
      final price = (item['gold_price'] ?? 0).toDouble();
      if (price > high) high = price;
    }
    return high;
  }

  double _getLowPrice() {
    double low = double.maxFinite;
    for (var item in _priceHistory) {
      final price = (item['gold_price'] ?? 0).toDouble();
      if (price < low) low = price;
    }
    return low;
  }

  double _getPriceChange() {
    if (_priceHistory.length < 2) return 0;
    final first = (_priceHistory.first['gold_price'] ?? 0).toDouble();
    final last = (_priceHistory.last['gold_price'] ?? 0).toDouble();
    return first - last;
  }

  Color _getPriceChangeColor() {
    final change = _getPriceChange();
    if (change > 0) return AppTheme.bullColor;
    if (change < 0) return AppTheme.bearColor;
    return Colors.grey;
  }

  Color _getScoreColor(double score) {
    if (score >= 60) return AppTheme.bullColor;
    if (score >= 40) return AppTheme.neutralColor;
    return AppTheme.bearColor;
  }
}
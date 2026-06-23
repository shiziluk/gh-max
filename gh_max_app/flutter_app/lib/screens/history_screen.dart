// 历史数据页面

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _scoreHistory = [];
  List<dynamic> _marketHistory = [];
  bool _isLoading = true;
  int _selectedDays = 7;
  String _selectedSource = 'jinshi';
  final List<String> _sources = ['akshare', 'jinshi'];
  final List<String> _sourceLabels = ['AkShare', '金十数据'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final scoreData = await ApiService.getScoreHistory(days: _selectedDays);
    final marketData = await ApiService.getMarketHistory(days: _selectedDays, source: _selectedSource);

    setState(() {
      _scoreHistory = scoreData ?? [];
      _marketHistory = marketData ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史数据'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '评分走势'),
            Tab(text: '行情记录'),
            Tab(text: '统计分析'),
          ],
        ),
        actions: [
          ToggleButtons(
            isSelected: _sources.map((source) => _selectedSource == source).toList(),
            onPressed: (index) {
              setState(() => _selectedSource = _sources[index]);
              _loadHistory();
            },
            selectedColor: Colors.white,
            color: Colors.grey,
            fillColor: Color(0xFF00D4AA),
            borderColor: Color(0xFF00D4AA).withOpacity(0.5),
            borderWidth: 1,
            borderRadius: BorderRadius.circular(8),
            children: _sourceLabels.map((label) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(label),
            )).toList(),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('最近7天')),
              const PopupMenuItem(value: 14, child: Text('最近14天')),
              const PopupMenuItem(value: 30, child: Text('最近30天')),
              const PopupMenuItem(value: 90, child: Text('最近90天')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScoreHistory(),
                _buildMarketHistory(),
                _buildStatistics(),
              ],
            ),
    );
  }

  Widget _buildScoreHistory() {
    if (_scoreHistory.isEmpty) {
      return _buildEmptyState('暂无评分历史');
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scoreHistory.length,
        itemBuilder: (context, index) {
          final item = _scoreHistory[index];
          final score = (item['total_score'] ?? 50).toDouble();
          final trend = item['trend'] ?? '未知';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                ),
              ),
              title: Text(trend),
              subtitle: Text(
                item['timestamp'] ?? '',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Icon(
                _getTrendIcon(trend),
                color: _getScoreColor(score),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketHistory() {
    if (_marketHistory.isEmpty) {
      return _buildEmptyState('暂无行情记录');
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _marketHistory.length,
        itemBuilder: (context, index) {
          final item = _marketHistory[index];
          final price = (item['gold_price'] ?? 0).toDouble();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['timestamp'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['trend'] ?? '',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.currency_bitcoin,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedSource == 'jinshi' ? '¥' : '\$'}${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '评分: ${(item['total_score'] ?? 0).toStringAsFixed(1)}',
                        style: TextStyle(
                          color: _getScoreColor((item['total_score'] ?? 50).toDouble()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics() {
    if (_scoreHistory.isEmpty) {
      return _buildEmptyState('暂无统计数据');
    }

    // 计算统计
    double avgScore = 0;
    double maxScore = 0;
    double minScore = 100;
    Map<String, int> trendCount = {};

    for (var item in _scoreHistory) {
      final score = (item['total_score'] ?? 50).toDouble();
      avgScore += score;
      if (score > maxScore) maxScore = score;
      if (score < minScore) minScore = score;

      final trend = item['trend'] ?? '未知';
      trendCount[trend] = (trendCount[trend] ?? 0) + 1;
    }

    avgScore = _scoreHistory.isNotEmpty ? avgScore / _scoreHistory.length : 0;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '评分统计 (最近$_selectedDays天)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('平均', avgScore.toStringAsFixed(1), Colors.blue),
                        _buildStatBox('最高', maxScore.toStringAsFixed(1), AppTheme.bullColor),
                        _buildStatBox('最低', minScore.toStringAsFixed(1), AppTheme.bearColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '共 ${_scoreHistory.length} 条记录',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 趋势分布
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '趋势分布',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...trendCount.entries.map((entry) {
                      final pct = _scoreHistory.isNotEmpty
                          ? entry.value / _scoreHistory.length
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text('${entry.value}次'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTrendColor(entry.key),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistory,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 60) return AppTheme.bullColor;
    if (score >= 40) return AppTheme.neutralColor;
    return AppTheme.bearColor;
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case '强势多头':
        return const Color(0xFF00C853);
      case '偏多震荡':
        return AppTheme.bullColor;
      case '中性震荡':
        return AppTheme.neutralColor;
      case '偏空震荡':
        return AppTheme.bearColor;
      case '强势空头':
        return const Color(0xFFD50000);
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case '强势多头':
        return Icons.arrow_upward;
      case '偏多震荡':
        return Icons.trending_up;
      case '中性震荡':
        return Icons.trending_flat;
      case '偏空震荡':
        return Icons.trending_down;
      case '强势空头':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }
}

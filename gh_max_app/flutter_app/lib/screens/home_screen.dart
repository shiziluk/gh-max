// 首页 - 主仪表盘

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/market_data.dart';
import '../models/technical_data.dart';
import '../models/score_data.dart';
import '../models/news_data.dart';
import '../utils/theme.dart';
import '../widgets/score_card.dart';
import '../widgets/market_card.dart';
import '../widgets/technical_card.dart';
import '../widgets/news_card.dart';

enum DataSource {
  akshare,
  jinshi,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  DataSource _selectedDataSource = DataSource.jinshi;

  MarketData? _marketData;
  TechnicalIndicators? _technicalData;
  ScoreResult? _scoreResult;
  NewsSentiment? _newsSentiment;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadDataFromSource(_selectedDataSource);
  }

  Future<void> _loadDataFromSource(DataSource source) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 根据数据源选择不同的API
      final result = source == DataSource.akshare 
          ? await ApiService.getFullData()  // AkShare数据源
          : await ApiService.getJinshiData();  // 金十数据源
      
      if (result != null) {
        setState(() {
          _marketData = result['market'] != null
              ? MarketData.fromJson(result['market'])
              : null;
          _technicalData = result['technical'] != null
              ? TechnicalIndicators.fromJson(result['technical'])
              : null;
          _scoreResult = result['score'] != null
              ? ScoreResult.fromJson(result['score'])
              : null;
          _newsSentiment = result['news_sentiment'] != null
              ? NewsSentiment.fromJson(result['news_sentiment'])
              : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '无法连接到服务器，请检查后端服务是否启动';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '数据加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await ApiService.refreshData();
    await Future.delayed(const Duration(seconds: 2));
    await _loadData();

    setState(() {
      _isRefreshing = false;
    });
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
              child: const Icon(
                Icons.analytics,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text('GH-Max'),
          ],
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
        bottom: _buildDataSourceTabBar(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _buildContent(),
                ),
    );
  }

  PreferredSizeWidget _buildDataSourceTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              '数据源:',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 12),
            ToggleButtons(
              isSelected: [
                _selectedDataSource == DataSource.akshare,
                _selectedDataSource == DataSource.jinshi,
              ],
              onPressed: (index) {
                setState(() {
                  _selectedDataSource = index == 0 ? DataSource.akshare : DataSource.jinshi;
                  // 切换数据源后重新加载数据
                  _loadDataFromSource(_selectedDataSource);
                });
              },
              selectedColor: Colors.white,  // 选中时文字为白色，与青蓝背景对比
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,  // 未选中时文字为灰色
              fillColor: AppTheme.primaryColor,  // 选中时背景为青蓝色
              borderColor: AppTheme.primaryColor.withOpacity(0.5),
              borderWidth: 1,
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('AkShare'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('金十数据'),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedDataSource == DataSource.akshare ? '实时行情' : '财经新闻',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _showBackendHelp,
              child: const Text('如何启动后端服务?'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackendHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('启动后端服务'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 打开终端'),
            SizedBox(height: 8),
            Text('2. 进入 backend 目录:'),
            Text('   cd gh_max_app/backend'),
            SizedBox(height: 8),
            Text('3. 安装依赖:'),
            Text('   pip install -r requirements.txt'),
            SizedBox(height: 8),
            Text('4. 启动服务:'),
            Text('   python app.py'),
            SizedBox(height: 8),
            Text('5. 服务启动后地址:'),
            Text('   http://localhost:5000'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 调试信息卡片
          Card(
            color: Colors.orange.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔍 调试信息', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('当前数据源: ${_selectedDataSource == DataSource.jinshi ? "金十数据" : "AkShare"}'),
                  Text('应显示货币符号: ${_selectedDataSource == DataSource.jinshi ? "¥" : "\$"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 综合评分卡片
          if (_scoreResult != null)
            ScoreCard(scoreResult: _scoreResult!, isJinshi: _selectedDataSource == DataSource.jinshi)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1),

          const SizedBox(height: 16),

          // 市场数据卡片
          if (_marketData != null)
            MarketCard(marketData: _marketData!, isJinshi: _selectedDataSource == DataSource.jinshi)
                .animate()
                .fadeIn(duration: 300.ms, delay: 100.ms)
                .slideY(begin: 0.1),

          const SizedBox(height: 16),

          // 技术指标卡片
          if (_technicalData != null)
            TechnicalCard(technicalData: _technicalData!)
                .animate()
                .fadeIn(duration: 300.ms, delay: 200.ms)
                .slideY(begin: 0.1),

          const SizedBox(height: 16),

          // 新闻情绪卡片
          if (_newsSentiment != null)
            NewsCard(newsSentiment: _newsSentiment!)
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms)
                .slideY(begin: 0.1),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
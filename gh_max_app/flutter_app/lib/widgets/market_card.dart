// 市场数据卡片组件

import 'package:flutter/material.dart';
import '../models/market_data.dart';
import '../utils/theme.dart';

class MarketCard extends StatelessWidget {
  final MarketData marketData;
  final bool isJinshi;

  const MarketCard({super.key, required this.marketData, this.isJinshi = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '核心行情',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 黄金价格
            if (marketData.gold != null)
              _buildPriceItem(
                icon: Icons.currency_bitcoin,
                name: isJinshi ? '上海黄金 AU9999' : '现货黄金 XAU/USD',
                price: marketData.gold!.price,
                change: marketData.gold!.change,
                changePct: marketData.gold!.changePct,
                color: AppTheme.primaryColor,
                isJinshi: isJinshi,
              ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // 其他市场数据
            Row(
              children: [
                Expanded(
                  child: _buildSimpleItem(
                    icon: Icons.attach_money,
                    name: '美元指数',
                    value: marketData.dxy?.price.toStringAsFixed(2) ?? '--',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleItem(
                    icon: Icons.account_balance,
                    name: '10Y美债',
                    value: marketData.bond10y != null
                        ? '${marketData.bond10y!.value.toStringAsFixed(2)}%'
                        : '--',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSimpleItem(
                    icon: Icons.trending_up,
                    name: 'VIX恐慌指数',
                    value: marketData.vix?.value.toStringAsFixed(2) ?? '--',
                    color: marketData.vix != null
                        ? (marketData.vix!.value > 25 ? AppTheme.bearColor : AppTheme.bullColor)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleItem(
                    icon: Icons.pie_chart,
                    name: '更新时间',
                    value: _formatTime(marketData.timestamp),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem({
    required IconData icon,
    required String name,
    required double price,
    required double change,
    required double changePct,
    required Color color,
    bool isJinshi = false,
  }) {
    final isPositive = change >= 0;
    final changeColor = isPositive ? AppTheme.bullColor : AppTheme.bearColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${isJinshi ? '¥' : '\$'}${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: changeColor,
                          ),
                          Text(
                            '${isPositive ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleItem({
    required IconData icon,
    required String name,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '--';
    try {
      final parts = timestamp.split(' ');
      if (parts.length >= 2) {
        return parts[1].substring(0, 5); // HH:MM
      }
      return timestamp;
    } catch (e) {
      return timestamp;
    }
  }
}

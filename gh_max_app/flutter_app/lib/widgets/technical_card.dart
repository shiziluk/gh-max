// 技术指标卡片组件

import 'package:flutter/material.dart';
import '../models/technical_data.dart';
import '../utils/theme.dart';

class TechnicalCard extends StatelessWidget {
  final TechnicalIndicators technicalData;

  const TechnicalCard({super.key, required this.technicalData});

  @override
  Widget build(BuildContext context) {
    final current = technicalData.current;
    if (current == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('技术指标数据加载中...'),
        ),
      );
    }

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
                    Icon(Icons.candlestick_chart, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      '技术面分析',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: technicalData.trend == '偏多'
                        ? AppTheme.bullColor.withOpacity(0.2)
                        : AppTheme.bearColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    technicalData.trend,
                    style: TextStyle(
                      color: technicalData.trend == '偏多'
                          ? AppTheme.bullColor
                          : AppTheme.bearColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 均线系统
            _buildSection('均线系统', [
              _buildIndicatorRow('MA5', current.ma5, current.close),
              _buildIndicatorRow('MA20', current.ma20, current.close),
              _buildIndicatorRow('MA60', current.ma60, current.close),
            ]),

            const SizedBox(height: 16),

            // MACD指标
            _buildSection('MACD', [
              _buildMacdRow('DIF', current.dif),
              _buildMacdRow('DEA', current.dea),
              _buildMacdRow('MACD', current.macd),
            ]),

            const SizedBox(height: 16),

            // RSI和KDJ
            Row(
              children: [
                Expanded(
                  child: _buildRsiGauge(current.rsi),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKdjGauge(current.k, current.d, current.j),
                ),
              ],
            ),

            // 背离信号
            if (_hasDivergences()) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildDivergenceSection(),
            ],

            // K线形态
            if (technicalData.patterns.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildPatternsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildIndicatorRow(String name, double? ma, double price) {
    if (ma == null) return const SizedBox.shrink();

    final isAbove = price > ma;
    final color = isAbove ? AppTheme.bullColor : AppTheme.bearColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              '\$${ma.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(
            isAbove ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildMacdRow(String name, double value) {
    final isPositive = value >= 0;
    final color = isPositive ? AppTheme.bullColor : AppTheme.bearColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              name,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: value >= 0 ? Alignment.centerLeft : Alignment.centerRight,
                widthFactor: (value.abs() / 2).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              value.toStringAsFixed(3),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRsiGauge(double rsi) {
    final color = rsi > 70
        ? AppTheme.bearColor
        : rsi < 30
            ? AppTheme.bullColor
            : AppTheme.neutralColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'RSI(14)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: rsi / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                rsi.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getRsiLabel(rsi),
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  String _getRsiLabel(double rsi) {
    if (rsi > 80) return '极度超买';
    if (rsi > 70) return '超买区';
    if (rsi < 20) return '极度超卖';
    if (rsi < 30) return '超卖区';
    return '正常区间';
  }

  Widget _buildKdjGauge(double k, double d, double j) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'KDJ(9)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKdjValue('K', k),
              _buildKdjValue('D', d),
              _buildKdjValue('J', j),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKdjValue(String name, double value) {
    final color = value > 80
        ? AppTheme.bearColor
        : value < 20
            ? AppTheme.bullColor
            : Colors.blue;

    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  bool _hasDivergences() {
    if (technicalData.divergences == null) return false;
    return technicalData.divergences!.values.any((d) => d.hasDivergence);
  }

  Widget _buildDivergenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 18),
            SizedBox(width: 4),
            Text(
              '背离信号',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: technicalData.divergences!.entries
              .where((e) => e.value.hasDivergence)
              .map((e) {
            final div = e.value;
            final color = div.signal == '利多' ? AppTheme.bullColor : AppTheme.bearColor;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    div.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPatternsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pattern, color: AppTheme.primaryColor, size: 18),
            SizedBox(width: 4),
            Text(
              'K线形态',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: technicalData.patterns.map((p) {
            final color = p.signal == '偏多'
                ? AppTheme.bullColor
                : p.signal == '偏空'
                    ? AppTheme.bearColor
                    : AppTheme.neutralColor;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    p.description,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

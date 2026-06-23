// 评分卡片组件

import 'package:flutter/material.dart';
import '../models/score_data.dart';
import '../utils/theme.dart';

class ScoreCard extends StatelessWidget {
  final ScoreResult scoreResult;
  final bool isJinshi;

  const ScoreCard({super.key, required this.scoreResult, this.isJinshi = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'GH-Max 综合评分',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(scoreResult.trendColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scoreResult.trend,
                    style: TextStyle(
                      color: Color(scoreResult.trendColor),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 核心分数显示
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        scoreResult.totalScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Color(scoreResult.trendColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '分',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    scoreResult.trendIcon + ' ' + scoreResult.action,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(scoreResult.trendColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 分项评分
            ...scoreResult.scores.entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        item.name,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: item.score / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(item.color),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        item.score.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(item.color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 技术信号
            if (scoreResult.techSignals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scoreResult.techSignals.take(5).map((signal) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      signal,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // 交易位置
            if (scoreResult.positions != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildPositions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositions() {
    final pos = scoreResult.positions!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '交易参考位置',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPositionItem('支撑', pos.support, AppTheme.bullColor),
            _buildPositionItem('阻力', pos.resistance, AppTheme.bearColor),
            if (pos.stopLoss != null)
              _buildPositionItem('止损', pos.stopLoss!, Colors.grey),
            if (pos.takeProfit != null)
              _buildPositionItem('止盈', pos.takeProfit!, AppTheme.bullColor),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${isJinshi ? '¥' : '\$'}${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

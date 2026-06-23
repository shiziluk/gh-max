// API服务 - 与后端通信

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';
import '../models/technical_data.dart';
import '../models/score_data.dart';
import '../models/news_data.dart';

class ApiService {
  // 默认本地地址，正式部署时改为服务器地址
  static String baseUrl = 'http://localhost:5000';
  
  // 超时时间（毫秒）
  static const timeout = 30000;
  
  // 重试次数
  static const maxRetries = 3;
  static const retryDelay = Duration(seconds: 2);
  
  // 带重试的GET请求
  static Future<http.Response?> _getWithRetry(String url) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http.get(
          Uri.parse(url),
        ).timeout(Duration(milliseconds: timeout));
        if (response != null && response.statusCode == 200) return response;
      } catch (e) {
        if (i == maxRetries - 1) return null;
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }
  
  // 带重试的POST请求
  static Future<http.Response?> _postWithRetry(String url, {Map<String, String>? headers, Object? body}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers ?? {'Content-Type': 'application/json'},
          body: body,
        ).timeout(Duration(milliseconds: timeout));
        return response;
      } catch (e) {
        if (i == maxRetries - 1) return null;
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  // ==================== 市场数据 ====================

  static Future<MarketData?> getMarketData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/market'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return MarketData.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('获取市场数据失败: $e');
    }
    return null;
  }

  // ==================== 技术指标 ====================

  static Future<TechnicalIndicators?> getTechnicalData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/technical'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return TechnicalIndicators.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('获取技术指标失败: $e');
    }
    return null;
  }

  // ==================== 综合评分 ====================

  static Future<ScoreResult?> getScore() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/score'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return ScoreResult.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('获取评分失败: $e');
    }
    return null;
  }

  // ==================== 新闻情绪 ====================

  static Future<NewsSentiment?> getNewsSentiment() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/news'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return NewsSentiment.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('获取新闻情绪失败: $e');
    }
    return null;
  }

  // ==================== 完整数据 ====================

  static Future<Map<String, dynamic>?> getFullData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/full'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('获取完整数据失败: $e');
    }
    return null;
  }

  // ==================== 金十数据源 ====================

  static Future<Map<String, dynamic>?> getJinshiData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/jinshi'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('获取金十数据失败: $e');
    }
    return null;
  }

  // ==================== 手动刷新 ====================

  static Future<bool> refreshData() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/refresh'),
      ).timeout(const Duration(milliseconds: timeout));

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('刷新数据失败: $e');
      return false;
    }
  }

  // ==================== 历史数据 ====================

  static Future<List<dynamic>?> getMarketHistory({int days = 7, String? source}) async {
    try {
      String url = '$baseUrl/api/history?days=$days&type=market';
      if (source != null && source.isNotEmpty) {
        url += '&source=$source';
      }
      final response = await _getWithRetry(url);

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('获取历史数据失败: $e');
    }
    return null;
  }

  static Future<List<dynamic>?> getScoreHistory({int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history?days=$days&type=score'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('获取评分历史失败: $e');
    }
    return null;
  }

  // ==================== 设置 ====================

  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/settings'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('获取设置失败: $e');
    }
    return null;
  }

  static Future<bool> updateSettings({
    String? refreshInterval,
    bool? notifications,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (refreshInterval != null) body['refresh_interval'] = refreshInterval;
      if (notifications != null) body['notifications'] = notifications;

      final response = await http.post(
        Uri.parse('$baseUrl/api/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(milliseconds: timeout));

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('更新设置失败: $e');
      return false;
    }
  }

  // ==================== 连接测试 ====================

  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
      ).timeout(const Duration(milliseconds: 5000));

      return response != null && response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== AI配置 ====================

  static Future<Map<String, dynamic>?> getAIConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ai/config'),
      ).timeout(const Duration(milliseconds: timeout));

      if (response != null && response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('获取AI配置失败: $e');
    }
    return null;
  }

  static Future<bool> saveAIConfig({
    required String apiKey,
    required bool enabled,
    String model = 'qwen-plus',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/config'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'api_key': apiKey,
          'enabled': enabled,
          'model': model,
        }),
      ).timeout(const Duration(milliseconds: timeout));

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('保存AI配置失败: $e');
      return false;
    }
  }
}

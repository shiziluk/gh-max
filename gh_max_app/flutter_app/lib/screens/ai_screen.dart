// AI助手页面 - 提供智能分析和问答功能

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme.dart';
import '../utils/navigation_manager.dart';
import 'dart:io';
import 'dart:async';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _aiEnabled = false;
  String _aiStatus = '检测中...';
  String? _currentAnalysis;
  String get _historyFilePath {
    final exeDir = Platform.resolvedExecutable;
    final dir = File(exeDir).parent.path;
    return dir + '\\' + 'chat_history.json';
  }


  @override
  void initState() {
    super.initState();
    _checkAIStatus();
    _loadAnalysis();
    _loadHistory();
    // Auto-refresh AI status every 5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      _checkAIStatus();
      return true;
    });
  }

  Future<void> _checkAIStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/ai/status'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiEnabled = data['available'] ?? false;
          _aiStatus = data['available'] 
              ? 'AI服务已就绪 (${data['model']})' 
              : '请先配置千问API Key';
        });
      }
    } catch (e) {
      setState(() {
        _aiStatus = '服务连接失败';
      });
    }
  }

  Future<void> _loadAnalysis() async {
    if (!_aiEnabled) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/ai/analyze'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _currentAnalysis = data['analysis'];
          });
        }
      }
    } catch (e) {
      // 分析加载失败，静默处理
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final file = File(_historyFilePath);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonStr);
        setState(() {
          _messages.clear();
          _messages.addAll(jsonList.map((e) => ChatMessage.fromJson(e)));
        });
      }
    } catch (e) {
      // Silent fail on load
    }
  }

  Future<void> _saveHistory() async {
    try {
      final file = File(_historyFilePath);
      final jsonList = _messages.map((m) => m.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      // Silent fail on save
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Force status check before sending if not confirmed enabled
    if (!_aiEnabled) {
      await _checkAIStatus();
    }
    if (!_aiEnabled) return;

    _messageController.clear();
    
    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            text: data['success'] == true 
                ? data['response'] 
                : '抱歉，AI回复失败：${data['error']}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: '服务请求失败，请稍后重试',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '网络连接失败，请检查后台服务',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _saveHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI助手'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: '清除聊天记录',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _checkAIStatus().then((_) => _loadAnalysis()); },
            tooltip: '刷新分析',
          ),
        ],
      ),
      body: Column(
        children: [
          // AI状态指示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _aiEnabled 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _aiEnabled ? Icons.check_circle : Icons.warning,
                  color: _aiEnabled ? AppTheme.primaryColor : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiStatus,
                    style: TextStyle(
                      color: _aiEnabled 
                          ? AppTheme.primaryColor 
                          : Colors.orange,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!_aiEnabled)
                  TextButton(
                    onPressed: () {
                      // 通过NavigationManager切换到设置页面（索引4）
                      NavigationManager.instance.requestTabSwitch(4);
                    },
                    child: const Text('去配置'),
                  ),
              ],
            ),
          ),

          // AI分析卡片
          if (_currentAnalysis != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'AI市场分析',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentAnalysis!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          // 聊天消息列表
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark ? AppTheme.textTertiary : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '开始与AI助手对话',
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondary : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '询问黄金市场分析、技术指标解读等',
                          style: TextStyle(
                            color: isDark ? AppTheme.textTertiary : Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.primaryColor.withOpacity(0.08) : AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, size: 16, color: isDark ? AppTheme.textTertiary : Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                '长按对话消息可删除单条记录',
                                style: TextStyle(
                                  color: isDark ? AppTheme.textTertiary : Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index], index);
                    },
                  ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _aiStatus.contains('检测') ? '正在检测AI服务...' : (_aiEnabled ? '输入您的问题...' : '请先在设置中配置AI服务'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.darkSurface : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.darkSurface : Colors.grey.shade300,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    enabled: !_isLoading && (_aiEnabled || _aiStatus == '检测中...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: !_isLoading && (_aiEnabled || _aiStatus == '检测中...') ? _sendMessage : null,
                  icon: Icon(
                    Icons.send,
                    color: _aiEnabled && !_isLoading 
                        ? AppTheme.primaryColor 
                        : (isDark ? AppTheme.textTertiary : Colors.grey.shade400),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: () => _deleteMessage(index),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser 
                    ? Colors.white 
                    : (isDark ? AppTheme.textPrimary : Colors.black87),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isUser 
                    ? Colors.white.withOpacity(0.7)
                    : (isDark ? AppTheme.textTertiary : Colors.grey.shade500),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AI正在思考...',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有聊天记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { setState(() => _messages.clear()); _saveHistory(); Navigator.pop(ctx); },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { setState(() => _messages.removeAt(index)); _saveHistory(); Navigator.pop(ctx); },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
  );
}

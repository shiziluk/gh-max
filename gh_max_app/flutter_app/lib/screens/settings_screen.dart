// 设置页面

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../utils/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _refreshInterval = '5分钟';
  bool _isLoading = true;
  String _serverStatus = '检测中...';
  final TextEditingController _serverController = TextEditingController(
    text: 'http://localhost:5000',
  );
  final TextEditingController _aiApiKeyController = TextEditingController();
  bool _aiEnabled = false;
  String _aiModel = 'qwen-plus';

  final ThemeManager _themeManager = ThemeManager.instance;

  bool get _isDarkMode => _themeManager.isDarkMode;

  final List<String> _refreshOptions = [
    '1分钟',
    '5分钟',
    '15分钟',
    '30分钟',
    '1小时',
  ];

  // AI模型选项
  final List<String> _aiModels = [
    'qwen-turbo',
    'qwen-plus',
    'qwen-max',
    'qwen-max-longcontext',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkServerStatus();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ApiService.getSettings();
    if (settings != null) {
      setState(() {
        _refreshInterval = settings['refresh_interval'] ?? '5分钟';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
    
    // 加载AI配置
    await _loadAIConfig();
  }

  Future<void> _loadAIConfig() async {
    try {
      final response = await ApiService.getAIConfig();
      if (response != null) {
        setState(() {
          _aiEnabled = response['enabled'] ?? false;
          _aiModel = response['model'] ?? 'qwen-plus';
          // API Key不从后端返回（安全考虑），只显示是否已配置
        });
      }
    } catch (e) {
      // 静默处理
    }
  }

  Future<void> _checkServerStatus() async {
    final isConnected = await ApiService.testConnection();
    setState(() {
      _serverStatus = isConnected ? '已连接' : '未连接';
    });
  }

  Future<void> _saveSettings() async {
    // 保存常规设置
    final success = await ApiService.updateSettings(
      refreshInterval: _refreshInterval,
      notifications: _notificationsEnabled,
    );

    // 保存AI配置
    await ApiService.saveAIConfig(
      apiKey: _aiApiKeyController.text,
      enabled: _aiEnabled,
      model: _aiModel,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '设置已保存' : '设置保存失败'),
          backgroundColor: success ? AppTheme.bullColor : AppTheme.bearColor,
        ),
      );
    }
  }

  Future<void> _toggleTheme() async {
    await _themeManager.toggleTheme();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 服务器状态
                  _buildSection(
                    title: '服务器连接',
                    children: [
                      ListTile(
                        leading: Icon(
                          _serverStatus == '已连接'
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: _serverStatus == '已连接'
                              ? AppTheme.bullColor
                              : AppTheme.bearColor,
                        ),
                        title: const Text('服务器状态'),
                        subtitle: Text(_serverStatus),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _checkServerStatus,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _serverController,
                          decoration: const InputDecoration(
                            labelText: '服务器地址',
                            border: OutlineInputBorder(),
                            hintText: 'http://localhost:5000',
                          ),
                          onSubmitted: (value) {
                            ApiService.baseUrl = value;
                            _checkServerStatus();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 数据刷新
                  _buildSection(
                    title: '数据刷新',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.timer, color: AppTheme.primaryColor),
                        title: const Text('刷新频率'),
                        subtitle: Text('当前: $_refreshInterval'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRefreshPicker(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 通知设置
                  _buildSection(
                    title: '通知设置',
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications, color: AppTheme.primaryColor),
                        title: const Text('推送通知'),
                        subtitle: const Text('价格突破、信号变化时提醒'),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                          _saveSettings();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 主题设置
                  _buildSection(
                    title: '主题设置',
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppTheme.primaryColor,
                        ),
                        title: const Text('深色模式'),
                        subtitle: Text(_isDarkMode ? '当前: 深色主题' : '当前: 浅色主题'),
                        value: _isDarkMode,
                        onChanged: (value) => _toggleTheme(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // AI设置
                  _buildSection(
                    title: 'AI 反馈与建议',
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.smart_toy, color: Colors.purple),
                        title: const Text('启用AI功能'),
                        subtitle: const Text('接入千问模型获取智能分析建议'),
                        value: _aiEnabled,
                        onChanged: (value) {
                          setState(() => _aiEnabled = value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _aiApiKeyController,
                                decoration: const InputDecoration(
                                  labelText: '千问 API Key',
                                  border: OutlineInputBorder(),
                                  hintText: '请输入您的千问API密钥',
                                  helperText: '在阿里云或达摩院平台获取API Key',
                                ),
                                enabled: _aiEnabled,
                                onSubmitted: (value) => _saveSettings(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _aiEnabled ? _saveSettings : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              child: const Text('确认'),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cpu, color: Colors.orange),
                        title: const Text('AI模型选择'),
                        subtitle: Text('当前: $_aiModel'),
                        trailing: const Icon(Icons.chevron_right),
                        enabled: _aiEnabled,
                        onTap: () => _showModelPicker(),
                      ),
                      const ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.blue),
                        title: Text('使用说明'),
                        subtitle: Text('绑定API Key后，系统将基于AI模型提供市场分析和交易建议'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 关于
                  _buildSection(
                    title: '关于',
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info, color: AppTheme.primaryColor),
                        title: Text('GH-Max'),
                        subtitle: Text('版本 1.0.0'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.description, color: Colors.grey),
                        title: Text('说明文档'),
                        subtitle: Text('现货黄金全域多维AI智能研判系统'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('保存设置'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showRefreshPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择刷新频率',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._refreshOptions.map((option) => ListTile(
                  leading: Icon(
                    _refreshInterval == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _refreshInterval == option
                        ? AppTheme.primaryColor
                        : Colors.grey,
                  ),
                  title: Text(option),
                  onTap: () {
                    setState(() => _refreshInterval = option);
                    Navigator.pop(context);
                    _saveSettings();
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择AI模型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._aiModels.map((model) => ListTile(
                  leading: Icon(
                    _aiModel == model
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _aiModel == model
                        ? AppTheme.primaryColor
                        : Colors.grey,
                  ),
                  title: Text(model),
                  subtitle: Text(_getModelDescription(model)),
                  onTap: () {
                    setState(() => _aiModel = model);
                    Navigator.pop(context);
                    _saveSettings();
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getModelDescription(String model) {
    switch (model) {
      case 'qwen-turbo':
        return '轻量级，响应快，适合简单对话';
      case 'qwen-plus':
        return '平衡性能，适合日常分析（推荐）';
      case 'qwen-max':
        return '高性能，适合复杂推理';
      case 'qwen-max-longcontext':
        return '超长上下文，适合处理大量信息';
      default:
        return '';
    }
  }
}
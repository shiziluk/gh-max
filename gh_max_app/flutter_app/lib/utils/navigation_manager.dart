// 导航管理器 - 用于跨页面导航控制

import 'package:flutter/material.dart';

class NavigationManager extends ChangeNotifier {
  static final NavigationManager _instance = NavigationManager._internal();
  static NavigationManager get instance => _instance;

  NavigationManager._internal();

  int? _pendingTabIndex;

  /// 请求切换到指定Tab
  void requestTabSwitch(int tabIndex) {
    _pendingTabIndex = tabIndex;
    notifyListeners();
  }

  /// 获取待处理的Tab索引并清除
  int? consumePendingTab() {
    final index = _pendingTabIndex;
    _pendingTabIndex = null;
    return index;
  }
}
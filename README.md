# GH-MAX V1.0 — 现货黄金全域多维AI智能研判系统

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="version">
  <img src="https://img.shields.io/badge/platform-Windows-lightgrey" alt="platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="license">
</p>

## 📖 项目简介

**GH-MAX** 是一款基于多维度数据分析的现货黄金（XAUUSD）智能研判桌面应用，采用 **Python Flask 后端 + Flutter 桌面端** 架构。

系统整合五大分析层级，实时采集多源市场数据，提供综合性市场研判参考，支持接入**通义千问 (Qwen) 大模型**进行智能解读。

> ⚠️ **免责声明**：本系统仅供学习研究与市场数据分析参考，**不构成任何投资建议**。交易决策请结合自身情况独立判断，风险自负。

---

## 🏗️ 五层研判模型

```
┌─────────────────────────────────────────────────┐
│  第1层 · 宏观核心逻辑层 (权重18%)                  │
│  地缘冲突 / 全球经济 / 美联储政策 / 美债利率         │
├─────────────────────────────────────────────────┤
│  第2层 · 消息面量化打分 (权重12%)                   │
│  利多/利空分类 / 影响强度评估 / 时间衰减             │
├─────────────────────────────────────────────────┤
│  第3层 · 技术面AI研判 (权重15%)                     │
│  MACD/RSI/KDJ / 布林带 / K线形态 / 顶底背离识别      │
├─────────────────────────────────────────────────┤
│  第4层 · 跨资产联动 (权重42%)                       │
│  美元指数 / 美债利率 / 实际利率 / 资产轮动 / 大宗商品   │
├─────────────────────────────────────────────────┤
│  第5层 · 情绪心理分析 (权重13%)                     │
│  CFTC持仓 / 资金结构 / 舆情爬虫 / 交易心理           │
└─────────────────────────────────────────────────┘
```

---

## ✨ 功能特性

### 桌面端五大面板
| 面板 | 功能 |
|------|------|
| 🏠 **首页** | 综合仪表盘：评分/行情/技术/新闻一览 |
| 📈 **图表** | K线图 + 评分走势图，支持多周期/多数据源 |
| 🤖 **AI助手** | 通义千问智能分析 + 自由对话问答 |
| 📋 **历史** | 历史行情与评分数据回溯 |
| ⚙️ **设置** | 服务器连接 / 刷新频率 / AI配置 / 深色模式 |

### 每日输出
- ✅ 宏观综述 — 全球经济与政策环境概览
- ✅ 实时数据 — 黄金/美指/美债/VIX同步刷新
- ✅ 消息清单 — 财经快讯自动爬取与情感分析
- ✅ 技术结论 — 多指标综合评判与背离信号
- ✅ 情绪研判 — CFTC持仓结构与舆情量化
- ✅ 走势预判 — GH综合评分(0-100)与方向信号
- ✅ 风险预警 — 突破阈值自动告警

### AI助手（可选配置）
- 接入**通义千问 (Qwen)** 大模型
- 一键生成市场分析解读
- 支持自由对话问答
- 模型可选：`qwen-turbo` / `qwen-plus` / `qwen-max` / `qwen-max-longcontext`
- **API Key 本地加密保存，重启无需重复输入**

---

## 📁 项目结构

```
gh_max_app/
├── README.md                     # 本文件
├── build_package.bat             # 一键打包脚本
├── backend.spec                  # PyInstaller 打包配置
├── installer.iss                 # Inno Setup 安装包脚本
│
├── backend/                      # Python 后端
│   ├── app.py                    # Flask API 主入口
│   ├── config.py                 # 全局配置（权重/缓存/信号阈值等）
│   ├── data_service.py           # 数据服务（akshare + 多源爬虫）
│   ├── technical_indicators.py   # 技术指标计算（MACD/RSI/KDJ/布林带等）
│   ├── scoring_model.py          # GH-MAX 综合评分模型
│   ├── ai_service.py             # AI 服务（通义千问 API 集成）
│   ├── database.py               # SQLite 数据库管理
│   ├── commodity_linkage.py      # 大宗商品联动分析
│   ├── asset_rotation.py         # 资产轮动分析
│   ├── cftc_analysis.py          # CFTC 持仓分析
│   ├── real_rate_calculator.py   # 实际利率计算
│   ├── dynamic_weight.py         # 动态权重调整
│   ├── daily_report.py           # 每日报告生成
│   ├── notification.py           # 桌面推送通知
│   ├── logging_service.py        # 日志服务
│   ├── web_interface.html        # Web 备用界面
│   └── requirements.txt          # Python 依赖清单
│
└── flutter_app/                  # Flutter 桌面应用
    ├── lib/
    │   ├── main.dart             # 应用入口 + 底部导航
    │   ├── models/               # 数据模型
    │   │   ├── market_data.dart  # 行情数据
    │   │   ├── score_data.dart   # 评分数据
    │   │   ├── technical_data.dart
    │   │   └── news_data.dart
    │   ├── screens/              # 五大页面
    │   │   ├── home_screen.dart
    │   │   ├── chart_screen.dart
    │   │   ├── ai_screen.dart
    │   │   ├── history_screen.dart
    │   │   └── settings_screen.dart
    │   ├── services/
    │   │   └── api_service.dart  # 后端 API 通信
    │   ├── widgets/              # 可复用卡片组件
    │   └── utils/                # 主题管理/导航
    ├── windows/                  # Windows 原生配置
    ├── pubspec.yaml              # Flutter 依赖
    └── Release/                  # 已编译的 Windows 可执行文件
```

---

## 🚀 快速开始

### 环境要求
| 组件 | 版本要求 |
|------|----------|
| Python | ≥ 3.9 |
| Flutter SDK | ≥ 3.0 |
| 操作系统 | Windows 10/11 |

### 1. 启动后端服务

```bash
cd gh_max_app/backend
pip install -r requirements.txt
python app.py
```

服务启动后访问：**http://localhost:5000**

### 2. 运行前端应用

```bash
cd gh_max_app/flutter_app
flutter pub get
flutter run -d windows
```

或直接运行已编译版本：

```bash
cd gh_max_app/flutter_app/Release
flutter_app.exe
```

### 3. 配置 AI 功能（可选）

1. 打开应用 → **设置** 页面
2. 在「AI配置」填入 [通义千问 API Key](https://dashscope.aliyun.com/)
3. 选择模型（推荐 `qwen-plus`）
4. 启用开关 → 保存

> 🔒 API Key 存储在本地 `ai_config.json`（已加入 .gitignore），重启后自动加载。

---

## 📦 打包为安装包

```bash
# 1. 安装 PyInstaller
pip install pyinstaller

# 2. 安装 Inno Setup (https://jrsoftware.org/isinfo.php)

# 3. 运行一键打包
build_package.bat

# 4. 用 Inno Setup 打开 installer.iss → 编译
#    输出: installer_output/GH-MAX-Setup-v1.0.0.exe
```

---

## 🛠️ 技术栈

| 层级 | 技术 |
|------|------|
| 后端框架 | Python 3.11 + Flask 3.x |
| 前端框架 | Flutter 3.x (Dart) |
| 数据库 | SQLite |
| 数据源 | akshare / 新浪财经 / 搜狐财经 / 金十数据 |
| AI模型 | 通义千问 (Qwen) via DashScope API |
| 图表 | fl_chart |
| 网络 | http + requests |
| 网页爬虫 | BeautifulSoup4 + lxml |
| 打包 | PyInstaller + Inno Setup |

---

## 🔐 安全说明

- API Key 存储在本地 `ai_config.json`，该文件已在 `.gitignore` 中排除
- 前端设置页不显示已保存的 Key 明文，仅显示配置状态
- 数据库文件和日志文件均不会提交至版本控制
- 爬虫 Cookie 等敏感信息已从源码中清除

---

## 📄 License

MIT License — 仅供学习研究使用。

---

**GH-MAX V1.0** | 现货黄金全域多维AI智能研判系统

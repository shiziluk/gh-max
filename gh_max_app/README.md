# GH-Max V1.0 —— 现货黄金全域多维AI智能研判系统

GH-Max 是一款基于多维度数据分析的现货黄金（XAUUSD）智能研判桌面应用。系统整合**宏观基本面、技术指标、跨资产联动、市场情绪、AI大模型**五大分析层级，为黄金交易者提供综合性市场研判参考。

> ⚠️ **免责声明**：本系统仅提供市场数据分析与参考，不构成任何投资建议。交易决策请结合自身判断，风险自负。

## 功能特性

### 五层研判模型
| 层级 | 名称 | 内容 |
|------|------|------|
| 1 | 宏观核心逻辑层 | 地缘冲突、全球经济、美联储政策、美债利率 |
| 2 | 消息面量化打分 | 利多/利空分类、影响强度、时间衰减 |
| 3 | 技术面AI研判 | MACD/RSI/KDJ、布林带、K线形态、背离识别 |
| 4 | 跨资产联动 | 美元指数、美债利率、资产轮动 |
| 5 | 情绪心理分析 | 资金结构、舆情爬虫、交易心理 |

### 每日输出
- 宏观综述
- 实时数据（黄金/美指/美债/VIX）
- 消息清单
- 技术结论
- 情绪研判
- 走势预判
- 风险预警

### AI助手（可选）
- 接入**通义千问（Qwen）**大模型
- 智能市场分析解读
- 黄金市场问答对话
- 支持模型：qwen-turbo / qwen-plus / qwen-max / qwen-max-longcontext

## 项目结构

```
gh_max_app/
├── backend/                    # Python后端
│   ├── app.py                  # Flask API服务入口
│   ├── config.py               # 配置文件
│   ├── data_service.py         # 数据服务（akshare封装+爬虫）
│   ├── technical_indicators.py # 技术指标计算
│   ├── scoring_model.py        # GH-Max评分模型
│   ├── database.py             # 数据库管理
│   ├── ai_service.py           # AI服务（通义千问）
│   ├── notification.py         # 推送通知
│   ├── daily_report.py         # 每日报告生成
│   ├── commodity_linkage.py    # 大宗商品联动分析
│   ├── asset_rotation.py       # 资产轮动分析
│   ├── cftc_analysis.py        # CFTC持仓分析
│   ├── real_rate_calculator.py # 实际利率计算
│   ├── dynamic_weight.py       # 动态权重调整
│   ├── logging_service.py      # 日志服务
│   └── requirements.txt        # Python依赖
│
└── flutter_app/                # Flutter跨平台桌面应用
    ├── lib/
    │   ├── main.dart           # 应用入口
    │   ├── models/             # 数据模型
    │   ├── services/           # API服务
    │   ├── screens/            # 页面（首页/图表/AI/历史/设置）
    │   ├── widgets/            # UI组件
    │   └── utils/              # 工具类（主题/导航）
    └── pubspec.yaml            # Flutter依赖
```

## 快速启动

### 环境要求
- Python 3.9+
- Flutter SDK 3.0+
- Windows 10/11（当前仅支持Windows桌面端）

### 1. 启动后端服务

```bash
# 进入后端目录
cd gh_max_app/backend

# 安装Python依赖
pip install -r requirements.txt

# 启动服务
python app.py
```

服务启动后运行在 http://localhost:5000

### 2. 运行Flutter应用

```bash
# 进入Flutter目录
cd gh_max_app/flutter_app

# 获取依赖
flutter pub get

# 构建并运行
flutter run -d windows
```

或者直接运行已构建的Release版本：
```bash
cd gh_max_app/flutter_app/Release
flutter_app.exe
```

### 3. 配置AI功能（可选）

1. 启动应用后进入**设置**页面
2. 在"AI配置"区域填入[通义千问API Key](https://dashscope.aliyun.com/)
3. 选择模型（推荐 qwen-plus）
4. 启用AI开关并保存

> API Key 会加密保存在本地 `ai_config.json` 中，重启无需重新输入。

## 技术栈

- **后端**：Python + Flask + akshare + BeautifulSoup
- **前端**：Flutter (Dart)
- **数据库**：SQLite
- **数据源**：akshare（免费财经数据API）+ 新浪财经/搜狐财经/金十数据爬虫
- **AI模型**：通义千问 (Qwen) via DashScope API

## 开发说明

### 数据源
系统默认使用金十数据作为主要数据源，同时支持AkShare数据源。可在首页顶部切换。

### API Key安全
- API Key存储在本地 `ai_config.json` 文件中
- 该文件已加入 `.gitignore`，不会被提交到版本控制
- 前端设置页不显示已保存的Key原文，仅显示配置状态

## License

本项目仅供学习研究使用。使用本系统产生的任何交易后果由使用者自行承担。

---

**GH-Max V1.0** | 现货黄金全域多维AI智能研判系统

"""
GH-Max 配置文件
"""

# ==================== 全局设置 ====================
DEBUG = False
HOST = "0.0.0.0"
PORT = 5000

# 数据刷新频率（秒）
REFRESH_INTERVALS = {
    "1分钟": 60,
    "5分钟": 300,
    "15分钟": 900,
    "30分钟": 1800,
    "1小时": 3600
}
DEFAULT_REFRESH_INTERVAL = "5分钟"

# ==================== GH-Max 权重配置 ====================
WEIGHT_RATE = 22      # 实际利率+美债
WEIGHT_USD = 20       # 美元+美联储
WEIGHT_GEO = 18       # 地缘避险+新闻
WEIGHT_ECON = 12      # CPI/非农/PMI宏观
WEIGHT_TECH = 15      # 技术面+K线形态+指标背离
WEIGHT_CAP = 8         # ETF资金+恐慌指数
WEIGHT_AI = 5          # 情绪心理（人性因子）

# ==================== HTTP请求头 ====================
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"
}

# ==================== 数据库配置 ====================
DB_PATH = "data/gh_max.db"

# ==================== 缓存配置 ====================
CACHE_CONFIG = {
    "jinshi_memory_expire_seconds": 30,      # 金十数据内存缓存过期时间（秒）
    "jinshi_db_expire_hours": 0.083,        # 金十数据数据库缓存过期时间（小时），0.083≈5分钟
}

# ==================== 日志配置 ====================
LOG_FILE = "data/gh_max.log"
SAVE_LOG = True

# ==================== 新闻关键词配置 ====================
BULL_KEYWORDS = [
    "降息", "衰退", "地缘", "冲突", "避险", "鸽派", "局势紧张",
    "减产", "宽松", "量化宽松", "QE", "战争", "制裁", "危机",
    "萧条", "负增长", "失业", "央行增持"
]

BEAR_KEYWORDS = [
    "加息", "鹰派", "高通胀", "美债走高", "和谈", "就业强劲",
    "缩表", "收紧", "经济复苏", "GDP增长", "乐观", "加息预期",
    "紧缩", "收益率上升", "美元走强"
]

# ==================== 交易信号阈值 ====================
SIGNAL_THRESHOLDS = {
    "强势多头": 60,
    "偏多震荡": 50,
    "中性震荡": 40,
    "偏空震荡": 30,
    "强势空头": 20
}

# ==================== 推送通知配置 ====================
PUSH_NOTIFICATIONS = {
    "price_alert": True,      # 价格突破提醒
    "signal_change": True,     # 信号变化提醒
    "news_alert": True,        # 重要新闻提醒
    "divergence": True         # 背离信号提醒
}

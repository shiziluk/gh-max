"""
数据库模块
使用SQLite存储历史数据
"""

import sqlite3
import os
import json
from datetime import datetime, timedelta
from typing import List, Dict, Optional


class Database:
    """数据库管理类"""

    def __init__(self, db_path: str = "data/gh_max.db"):
        self.db_path = db_path
        self._ensure_data_dir()
        self._init_database()

    def _ensure_data_dir(self):
        """确保数据目录存在"""
        db_dir = os.path.dirname(self.db_path)
        if db_dir and not os.path.exists(db_dir):
            os.makedirs(db_dir)

    def _get_connection(self) -> sqlite3.Connection:
        """获取数据库连接"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_database(self):
        """初始化数据库表"""
        conn = self._get_connection()
        cursor = conn.cursor()

        # 行情数据表
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS market_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                gold_price REAL,
                gold_open REAL,
                gold_high REAL,
                gold_low REAL,
                dxy_price REAL,
                bond_10y REAL,
                vix REAL,
                etf_change REAL,
                total_score REAL,
                trend TEXT,
                source TEXT DEFAULT 'akshare',
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # 为旧表添加缺失字段（如果不存在）
        cursor.execute("PRAGMA table_info(market_data)")
        columns = [col[1] for col in cursor.fetchall()]
        if 'source' not in columns:
            cursor.execute("ALTER TABLE market_data ADD COLUMN source TEXT DEFAULT 'akshare'")
        if 'gold_open' not in columns:
            cursor.execute("ALTER TABLE market_data ADD COLUMN gold_open REAL")
        if 'gold_high' not in columns:
            cursor.execute("ALTER TABLE market_data ADD COLUMN gold_high REAL")
        if 'gold_low' not in columns:
            cursor.execute("ALTER TABLE market_data ADD COLUMN gold_low REAL")

        # 技术指标历史表
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS technical_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                period TEXT,
                close REAL,
                ma5 REAL,
                ma20 REAL,
                ma60 REAL,
                rsi REAL,
                macd REAL,
                kdj_k REAL,
                kdj_d REAL,
                kdj_j REAL,
                bb_upper REAL,
                bb_lower REAL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 评分历史表
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS score_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                total_score REAL,
                rate_score REAL,
                usd_score REAL,
                tech_score REAL,
                macro_score REAL,
                sentiment_score REAL,
                news_score REAL,
                trend TEXT,
                action TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 新闻历史表
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS news_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                news_content TEXT,
                sentiment TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 金十数据缓存表（长期缓存）
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS jinshi_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                data TEXT,
                expire_time TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 设置表
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 创建索引
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_market_timestamp ON market_data(timestamp)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_score_timestamp ON score_history(timestamp)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_news_timestamp ON news_history(timestamp)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_jinshi_timestamp ON jinshi_cache(timestamp)")

        conn.commit()
        conn.close()

    def save_market_data(self, data: Dict):
        """保存市场数据"""
        from datetime import datetime
        conn = self._get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO market_data (
                timestamp, gold_price, gold_open, gold_high, gold_low, dxy_price, bond_10y, vix, etf_change, total_score, trend, source
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            data.get("gold", {}).get("price"),
            data.get("gold", {}).get("open"),
            data.get("gold", {}).get("high"),
            data.get("gold", {}).get("low"),
            data.get("dxy", {}).get("price"),
            data.get("bond_10y", {}).get("value"),
            data.get("vix", {}).get("value"),
            data.get("gold_etf", {}).get("change_pct"),
            data.get("total_score"),
            data.get("trend"),
            data.get("source", "akshare")
        ))

        conn.commit()
        conn.close()

    def delete_market_data(self, record_id: int):
        """删除指定ID的市场数据记录"""
        conn = self._get_connection()
        cursor = conn.cursor()

        cursor.execute("DELETE FROM market_data WHERE id = ?", (record_id,))
        conn.commit()
        conn.close()

    def save_score_data(self, data: Dict):
        """保存评分数据"""
        conn = self._get_connection()
        cursor = conn.cursor()

        scores = data.get("scores", {})

        cursor.execute("""
            INSERT INTO score_history (
                timestamp, total_score, rate_score, usd_score, tech_score,
                macro_score, sentiment_score, news_score, trend, action
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            data.get("timestamp"),
            data.get("total_score"),
            scores.get("rate", {}).get("score"),
            scores.get("usd", {}).get("score"),
            scores.get("tech", {}).get("score"),
            scores.get("macro", {}).get("score"),
            scores.get("sentiment", {}).get("score"),
            scores.get("news", {}).get("score"),
            data.get("trend"),
            data.get("action")
        ))

        conn.commit()
        conn.close()

    def save_news(self, news_list: List[Dict], timestamp: str = None):
        """保存新闻数据"""
        if not timestamp:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        conn = self._get_connection()
        cursor = conn.cursor()

        for news in news_list:
            cursor.execute("""
                INSERT INTO news_history (timestamp, news_content, sentiment)
                VALUES (?, ?, ?)
            """, (timestamp, news.get("content", ""), news.get("sentiment", "中性")))

        conn.commit()
        conn.close()

    def get_market_history(self, days: int = 7) -> List[Dict]:
        """获取市场历史数据"""
        conn = self._get_connection()
        cursor = conn.cursor()

        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        cursor.execute("""
            SELECT * FROM market_data
            WHERE timestamp >= ?
            ORDER BY timestamp DESC
        """, (start_date,))

        rows = cursor.fetchall()
        conn.close()

        return [dict(row) for row in rows]

    def get_market_history_by_source(self, days: int = 7, source: str = 'akshare') -> List[Dict]:
        """按数据源获取市场历史数据"""
        conn = self._get_connection()
        cursor = conn.cursor()

        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        cursor.execute("""
            SELECT * FROM market_data
            WHERE timestamp >= ? AND source = ?
            ORDER BY timestamp DESC
        """, (start_date, source))

        rows = cursor.fetchall()
        conn.close()

        return [dict(row) for row in rows]

    def get_score_history(self, days: int = 30) -> List[Dict]:
        """获取评分历史"""
        conn = self._get_connection()
        cursor = conn.cursor()

        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        cursor.execute("""
            SELECT * FROM score_history
            WHERE timestamp >= ?
            ORDER BY timestamp DESC
        """, (start_date,))

        rows = cursor.fetchall()
        conn.close()

        return [dict(row) for row in rows]

    def get_latest_score(self) -> Optional[Dict]:
        """获取最新评分"""
        conn = self._get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT * FROM score_history
            ORDER BY timestamp DESC
            LIMIT 1
        """)

        row = cursor.fetchone()
        conn.close()

        return dict(row) if row else None

    def get_score_statistics(self, days: int = 30) -> Dict:
        """获取评分统计"""
        conn = self._get_connection()
        cursor = conn.cursor()

        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        cursor.execute("""
            SELECT
                AVG(total_score) as avg_score,
                MAX(total_score) as max_score,
                MIN(total_score) as min_score,
                COUNT(*) as count
            FROM score_history
            WHERE timestamp >= ?
        """, (start_date,))

        row = cursor.fetchone()
        conn.close()

        return dict(row) if row else {}

    def save_setting(self, key: str, value: str):
        """保存设置"""
        conn = self._get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO settings (key, value, updated_at)
            VALUES (?, ?, ?)
        """, (key, value, datetime.now().strftime("%Y-%m-%d %H:%M:%S")))

        conn.commit()
        conn.close()

    def get_setting(self, key: str, default: str = None) -> Optional[str]:
        """获取设置"""
        conn = self._get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))

        row = cursor.fetchone()
        conn.close()

        return row["value"] if row else default

    def get_trend_distribution(self, days: int = 30) -> Dict:
        """获取趋势分布统计"""
        conn = self._get_connection()
        cursor = conn.cursor()

        start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

        cursor.execute("""
            SELECT trend, COUNT(*) as count
            FROM score_history
            WHERE timestamp >= ?
            GROUP BY trend
        """, (start_date,))

        rows = cursor.fetchall()
        conn.close()

        return {row["trend"]: row["count"] for row in rows}

    def save_jinshi_cache(self, data: Dict, expire_hours: int = 24):
        """保存金十数据到缓存（长期缓存）"""
        import json
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        expire_time = (datetime.now() + timedelta(hours=expire_hours)).strftime("%Y-%m-%d %H:%M:%S")
        data_json = json.dumps(data)
        
        cursor.execute("""
            INSERT INTO jinshi_cache (timestamp, data, expire_time)
            VALUES (?, ?, ?)
        """, (timestamp, data_json, expire_time))
        
        conn.commit()
        conn.close()

    def get_jinshi_cache(self) -> Optional[Dict]:
        """获取有效的金十数据缓存"""
        import json
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        cursor.execute("""
            SELECT * FROM jinshi_cache
            WHERE expire_time > ?
            ORDER BY timestamp DESC
            LIMIT 1
        """, (now,))
        
        row = cursor.fetchone()
        conn.close()
        
        if row:
            try:
                return json.loads(row["data"])
            except:
                return None
        return None

    def delete_market_history(self, days: int = None) -> int:
        """
        删除历史市场数据
        如果指定days，则删除days天之前的数据
        如果不指定days，则删除所有历史数据
        """
        conn = self._get_connection()
        cursor = conn.cursor()
        
        if days:
            delete_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
            cursor.execute("DELETE FROM market_data WHERE timestamp < ?", (delete_date,))
        else:
            cursor.execute("DELETE FROM market_data")
        
        deleted_count = cursor.rowcount
        conn.commit()
        conn.close()
        
        return deleted_count

    def delete_score_history(self, days: int = None) -> int:
        """
        删除历史评分数据
        如果指定days，则删除days天之前的数据
        如果不指定days，则删除所有历史数据
        """
        conn = self._get_connection()
        cursor = conn.cursor()
        
        if days:
            delete_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
            cursor.execute("DELETE FROM score_history WHERE timestamp < ?", (delete_date,))
        else:
            cursor.execute("DELETE FROM score_history")
        
        deleted_count = cursor.rowcount
        conn.commit()
        conn.close()
        
        return deleted_count

    def delete_all_history(self) -> Dict:
        """删除所有历史数据"""
        market_deleted = self.delete_market_history()
        score_deleted = self.delete_score_history()
        
        return {
            "market_data_deleted": market_deleted,
            "score_history_deleted": score_deleted
        }

    def close(self):
        """关闭数据库连接（预留方法）"""
        pass

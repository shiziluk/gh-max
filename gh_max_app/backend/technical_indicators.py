"""
技术指标计算模块
包含：MACD、RSI、KDJ、布林带、均线系统等
"""

import numpy as np
import pandas as pd
from typing import Tuple, List, Dict


class TechnicalIndicators:
    """技术指标计算类"""

    @staticmethod
    def calculate_sma(prices: pd.Series, period: int) -> pd.Series:
        """简单移动平均线 SMA"""
        return prices.rolling(window=period).mean()

    @staticmethod
    def calculate_ema(prices: pd.Series, period: int) -> pd.Series:
        """指数移动平均线 EMA"""
        return prices.ewm(span=period, adjust=False).mean()

    @staticmethod
    def calculate_rsi(prices: pd.Series, period: int = 14) -> pd.Series:
        """相对强弱指数 RSI"""
        deltas = prices.diff()
        gains = deltas.copy()
        losses = deltas.copy()
        gains[gains < 0] = 0
        losses[losses > 0] = 0
        losses = abs(losses)

        avg_gain = gains.rolling(window=period).mean()
        avg_loss = losses.rolling(window=period).mean()

        # 使用EMA方式计算后续值
        avg_gain = gains.ewm(alpha=1/period, adjust=False).mean()
        avg_loss = losses.ewm(alpha=1/period, adjust=False).mean()

        rs = avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))
        return rsi

    @staticmethod
    def calculate_macd(prices: pd.Series, fast: int = 12, slow: int = 26, signal: int = 9) -> Tuple[pd.Series, pd.Series, pd.Series]:
        """MACD指标计算"""
        ema_fast = prices.ewm(span=fast, adjust=False).mean()
        ema_slow = prices.ewm(span=slow, adjust=False).mean()
        dif = ema_fast - ema_slow
        dea = dif.ewm(span=signal, adjust=False).mean()
        macd = 2 * (dif - dea)
        return dif, dea, macd

    @staticmethod
    def calculate_kdj(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 9) -> Tuple[pd.Series, pd.Series, pd.Series]:
        """KDJ随机指标"""
        low_list = low.rolling(window=period).min()
        high_list = high.rolling(window=period).max()

        rsv = (close - low_list) / (high_list - low_list) * 100
        rsv = rsv.fillna(50)

        k = rsv.ewm(alpha=1/3, adjust=False).mean()
        d = k.ewm(alpha=1/3, adjust=False).mean()
        j = 3 * k - 2 * d
        return k, d, j

    @staticmethod
    def calculate_bollinger_bands(prices: pd.Series, period: int = 20, std_dev: int = 2) -> Tuple[pd.Series, pd.Series, pd.Series]:
        """布林带"""
        sma = prices.rolling(window=period).mean()
        std = prices.rolling(window=period).std()
        upper = sma + (std * std_dev)
        lower = sma - (std * std_dev)
        return upper, sma, lower

    @staticmethod
    def calculate_cci(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 14) -> pd.Series:
        """顺势指标 CCI"""
        tp = (high + low + close) / 3
        sma = tp.rolling(window=period).mean()
        mad = tp.rolling(window=period).apply(lambda x: np.abs(x - x.mean()).mean())
        cci = (tp - sma) / (0.015 * mad)
        return cci

    @staticmethod
    def calculate_atr(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 14) -> pd.Series:
        """平均真实波幅 ATR"""
        tr1 = high - low
        tr2 = abs(high - close.shift())
        tr3 = abs(low - close.shift())
        tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        atr = tr.rolling(window=period).mean()
        return atr

    @staticmethod
    def calculate_obv(close: pd.Series, volume: pd.Series) -> pd.Series:
        """能量潮指标 OBV"""
        obv = (np.sign(close.diff()) * volume).fillna(0).cumsum()
        return obv

    @staticmethod
    def check_divergence(price: pd.Series, indicator: pd.Series, lookback: int = 20) -> Dict:
        """
        检测背离
        返回: {"type": "顶背离/底背离/无背离", "signal": "利空/利多/无信号", "strength": 强度值}
        """
        if len(price) < lookback or len(indicator) < lookback:
            return {"type": "数据不足", "signal": "无信号", "strength": 0}

        # 最近N个周期的高点和低点
        price_recent = price.tail(lookback)
        indicator_recent = indicator.tail(lookback)

        # 价格是否创新高/新低
        price_new_high = price.iloc[-1] == price_recent.max()
        price_new_low = price.iloc[-1] == price_recent.min()

        # 指标是否创新高/新低
        ind_new_high = indicator.iloc[-1] == indicator_recent.max()
        ind_new_low = indicator.iloc[-1] == indicator_recent.min()

        result = {"type": "无背离", "signal": "无信号", "strength": 0}

        # 顶背离：价格创新高，指标未创新高
        if price_new_high and not ind_new_high:
            result = {"type": "顶背离", "signal": "利空", "strength": 8}
        # 底背离：价格创新低，指标未创新低
        elif price_new_low and not ind_new_low:
            result = {"type": "底背离", "signal": "利多", "strength": 8}
        # 隐性顶背离：价格未创新高，指标创新高
        elif ind_new_high and not price_new_high:
            result = {"type": "隐性顶背离", "signal": "利空", "strength": 5}
        # 隐性底背离：价格未创新低，指标创新低
        elif ind_new_low and not price_new_low:
            result = {"type": "隐性底背离", "signal": "利多", "strength": 5}

        return result

    @staticmethod
    def detect_patterns(high: pd.Series, low: pd.Series, close: pd.Series, period: int = 20) -> List[Dict]:
        """
        K线形态识别
        """
        patterns = []

        if len(close) < period:
            return patterns

        # 最近周期数据
        high_recent = high.tail(period)
        low_recent = low.tail(period)
        close_recent = close.tail(period)

        # 计算关键价位
        high_max = high_recent.max()
        low_min = low_recent.min()
        close_last = close.iloc[-1]
        ma20 = close_recent.mean()

        # M头形态检测
        if close_last < ma20 and high_recent.iloc[-5:].max() < high_max * 0.98:
            patterns.append({
                "name": "M头",
                "signal": "偏空",
                "strength": 7,
                "description": "双顶结构，看跌信号"
            })

        # W底形态检测
        if close_last > ma20 and low_recent.iloc[-5:].min() > low_min * 1.02:
            patterns.append({
                "name": "W底",
                "signal": "偏多",
                "strength": 7,
                "description": "双底结构，看涨信号"
            })

        # 箱体震荡
        range_pct = (high_max - low_min) / low_min * 100
        if range_pct < 3:
            patterns.append({
                "name": "箱体震荡",
                "signal": "中性",
                "strength": 5,
                "description": f"震荡区间{range_pct:.1f}%，高抛低吸"
            })

        # 突破形态
        if close_last > high_max * 0.98:
            patterns.append({
                "name": "向上突破",
                "signal": "偏多",
                "strength": 8,
                "description": "突破前高，强势信号"
            })
        elif close_last < low_min * 1.02:
            patterns.append({
                "name": "向下破位",
                "signal": "偏空",
                "strength": 8,
                "description": "跌破前低，弱势信号"
            })

        return patterns

    @staticmethod
    def calculate_all_indicators(kline_data: pd.DataFrame) -> Dict:
        """
        计算所有技术指标
        """
        if kline_data.empty or len(kline_data) < 30:
            return {}

        close = kline_data['close']
        high = kline_data['high']
        low = kline_data['low']

        # 基础指标
        ma5 = TechnicalIndicators.calculate_sma(close, 5)
        ma10 = TechnicalIndicators.calculate_sma(close, 10)
        ma20 = TechnicalIndicators.calculate_sma(close, 20)
        ma60 = TechnicalIndicators.calculate_sma(close, 60) if len(close) >= 60 else None

        # MACD
        dif, dea, macd = TechnicalIndicators.calculate_macd(close)

        # RSI
        rsi = TechnicalIndicators.calculate_rsi(close)

        # KDJ
        k, d, j = TechnicalIndicators.calculate_kdj(high, low, close)

        # 布林带
        bb_upper, bb_middle, bb_lower = TechnicalIndicators.calculate_bollinger_bands(close)

        # 背离检测
        rsi_divergence = TechnicalIndicators.check_divergence(close, rsi)
        macd_divergence = TechnicalIndicators.check_divergence(close, dif)
        kdj_divergence = TechnicalIndicators.check_divergence(close, k)

        # 形态识别
        patterns = TechnicalIndicators.detect_patterns(high, low, close)

        # 最新值
        current = {
            "close": float(close.iloc[-1]),
            "ma5": float(ma5.iloc[-1]) if pd.notna(ma5.iloc[-1]) else None,
            "ma10": float(ma10.iloc[-1]) if pd.notna(ma10.iloc[-1]) else None,
            "ma20": float(ma20.iloc[-1]) if pd.notna(ma20.iloc[-1]) else None,
            "ma60": float(ma60.iloc[-1]) if pd.notna(ma60.iloc[-1]) else None,
            "dif": float(dif.iloc[-1]) if pd.notna(dif.iloc[-1]) else 0,
            "dea": float(dea.iloc[-1]) if pd.notna(dea.iloc[-1]) else 0,
            "macd": float(macd.iloc[-1]) if pd.notna(macd.iloc[-1]) else 0,
            "rsi": float(rsi.iloc[-1]) if pd.notna(rsi.iloc[-1]) else 50,
            "k": float(k.iloc[-1]) if pd.notna(k.iloc[-1]) else 50,
            "d": float(d.iloc[-1]) if pd.notna(d.iloc[-1]) else 50,
            "j": float(j.iloc[-1]) if pd.notna(j.iloc[-1]) else 50,
            "bb_upper": float(bb_upper.iloc[-1]) if pd.notna(bb_upper.iloc[-1]) else None,
            "bb_middle": float(bb_middle.iloc[-1]) if pd.notna(bb_middle.iloc[-1]) else None,
            "bb_lower": float(bb_lower.iloc[-1]) if pd.notna(bb_lower.iloc[-1]) else None,
        }

        return {
            "current": current,
            "divergences": {
                "rsi": rsi_divergence,
                "macd": macd_divergence,
                "kdj": kdj_divergence
            },
            "patterns": patterns,
            "trend": "偏多" if close.iloc[-1] > ma20.iloc[-1] else "偏空"
        }

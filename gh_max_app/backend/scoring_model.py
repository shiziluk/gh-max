"""
GH-Max 综合评分模型
五层研判体系：宏观+消息+技术+联动+情绪
支持AI动态权重调节
"""

from typing import Dict, Tuple, List
from config import (
    WEIGHT_RATE, WEIGHT_USD, WEIGHT_GEO, WEIGHT_ECON,
    WEIGHT_TECH, WEIGHT_CAP, WEIGHT_AI
)
from dynamic_weight import DynamicWeightSystem


class GHScoreModel:
    """GH-Max综合评分模型"""

    def __init__(self):
        self.base_score = 50  # 基础分
        self.weight_system = DynamicWeightSystem()  # 动态权重系统

    def calculate_rate_score(self, bond_10y: float) -> float:
        """
        第一层：利率/美债评分
        实际利率下行→持有黄金机会成本降低→黄金上涨
        """
        score = 50

        if bond_10y < 2.5:  # 低利率环境
            score += 12
        elif bond_10y < 3.5:
            score += 6
        elif bond_10y > 5.0:  # 高利率环境
            score -= 12
        elif bond_10y > 4.5:
            score -= 8
        else:
            score += 0

        return max(20, min(80, score))

    def calculate_usd_score(self, dxy: float, dxy_change: float = 0) -> float:
        """
        第二层：美元指数评分
        美元与黄金呈负相关
        """
        score = 50

        # 美元绝对水平
        if dxy < 95:
            score += 10
        elif dxy < 100:
            score += 5
        elif dxy < 103:
            score += 0
        elif dxy < 106:
            score -= 5
        elif dxy < 110:
            score -= 10
        else:
            score -= 12

        # 美元变动方向
        if dxy_change < -1:
            score += 5  # 美元下跌，利多黄金
        elif dxy_change > 1:
            score -= 5  # 美元上涨，利空黄金

        return max(20, min(80, score))

    def calculate_tech_score(self, tech_data: Dict) -> float:
        """
        第三层：技术面评分
        """
        score = 50
        signals = []

        if not tech_data or "current" not in tech_data or tech_data["current"] is None:
            return {"score": score, "signals": signals}

        current = tech_data["current"]
        patterns = tech_data.get("patterns", []) or []
        divergences = tech_data.get("divergences", {}) or {}

        # 趋势判断
        if current.get("ma5") and current.get("ma20"):
            if current["close"] > current["ma20"]:
                score += 8
                signals.append("价格站上MA20")
            else:
                score -= 8
                signals.append("价格跌破MA20")

        if current.get("ma5") and current.get("ma10"):
            if current["ma5"] > current["ma10"]:
                score += 5
                signals.append("短期均线多头排列")
            else:
                score -= 5
                signals.append("短期均线空头排列")

        # RSI评分
        rsi = current.get("rsi", 50)
        if rsi > 80:
            score -= 5  # 超买
            signals.append("RSI超买")
        elif rsi > 70:
            score -= 3
        elif rsi < 20:
            score += 5  # 超卖
            signals.append("RSI超卖")
        elif rsi < 30:
            score += 3

        # MACD评分
        macd = current.get("macd", 0)
        if macd > 1:
            score += 5
            signals.append("MACD红柱")
        elif macd < -1:
            score -= 5
            signals.append("MACD绿柱")

        # KDJ评分
        k = current.get("k", 50)
        if k > 80:
            score -= 3
        elif k < 20:
            score += 3

        # 背离评分
        if isinstance(divergences, dict):
            for ind_name, div in divergences.items():
                if isinstance(div, dict) and div.get("type") != "无背离":
                    strength = div.get("strength", 0)
                    if div.get("signal") == "利多":
                        score += strength
                        signals.append(f"{ind_name.upper()}底背离")
                    else:
                        score -= strength
                        signals.append(f"{ind_name.upper()}顶背离")

        # 形态评分
        if isinstance(patterns, list):
            for pattern in patterns:
                if isinstance(pattern, dict):
                    sig = pattern.get("signal", "中性")
                    strength = pattern.get("strength", 0)
                    if sig == "偏多":
                        score += strength
                    elif sig == "偏空":
                        score -= strength
                    signals.append(pattern.get("name", ""))

        # 布林带位置
        if current.get("bb_upper") and current.get("bb_lower"):
            bb_range = current["bb_upper"] - current["bb_lower"]
            if bb_range > 0:
                position = (current["close"] - current["bb_lower"]) / bb_range
                if position > 0.8:
                    score -= 3
                    signals.append("触及布林带上轨")
                elif position < 0.2:
                    score += 3
                    signals.append("触及布林带下轨")

        return {
            "score": round(max(20, min(85, score)), 2),
            "signals": signals
        }

    def calculate_macro_score(self, macro_data: Dict) -> float:
        """
        第四层：宏观经济评分
        """
        score = 50

        # CPI评分
        if "cpi" in macro_data:
            cpi = macro_data["cpi"].get("value", 0)
            if cpi > 5:
                score -= 8  # 高通胀但可能利多黄金
            elif cpi > 3:
                score -= 5
            elif cpi > 2:
                score += 0
            else:
                score += 5

        # 非农就业评分
        if "nonfarm" in macro_data:
            nonfarm = macro_data["nonfarm"].get("value", 0)
            if nonfarm > 300:
                score -= 6  # 就业强劲，利空黄金
            elif nonfarm > 200:
                score -= 3
            elif nonfarm < 50:
                score += 8  # 就业疲软，避险买盘
            elif nonfarm < 100:
                score += 4

        # PMI评分
        if "pmi" in macro_data:
            pmi = macro_data["pmi"].get("value", 50)
            if pmi < 45:
                score += 8  # 经济萎缩，避险需求
            elif pmi < 48:
                score += 4
            elif pmi > 55:
                score -= 5  # 经济过热
            else:
                score += 0

        return round(max(20, min(80, score)), 2)

    def calculate_sentiment_score(self, vix: float, etf_change: float) -> float:
        """
        第五层：情绪资金评分
        """
        score = 50

        # VIX恐慌指数
        if vix > 30:
            score += 10  # 高恐慌，避险买盘
        elif vix > 25:
            score += 5
        elif vix < 15:
            score -= 8  # 低恐慌，市场乐观
        elif vix < 20:
            score -= 4

        # ETF资金流向
        if etf_change > 1:
            score += 6  # 资金流入
        elif etf_change > 0.5:
            score += 3
        elif etf_change < -1:
            score -= 6  # 资金流出
        elif etf_change < -0.5:
            score -= 3

        return round(max(20, min(80, score)), 2)

    def calculate_news_score(self, sentiment_result: Dict) -> float:
        """
        新闻情绪评分
        """
        base = sentiment_result.get("sentiment_score", 50)
        bull = sentiment_result.get("bull_count", 0)
        bear = sentiment_result.get("bear_count", 0)

        # 加权调整
        if bull > bear + 3:
            base += 5
        elif bear > bull + 3:
            base -= 5

        return round(max(15, min(85, base)), 2)

    def calculate_total_score(
        self,
        market_data: Dict,
        tech_data: Dict,
        macro_data: Dict,
        sentiment_data: Dict,
        news_sentiment: Dict
    ) -> Dict:
        """
        计算GH-Max综合评分
        使用AI动态权重调节系统
        """
        # 获取基础数据
        gold_price = market_data.get("gold", {}).get("price", 0)
        dxy_price = market_data.get("dxy", {}).get("price", 100)
        dxy_change = market_data.get("dxy", {}).get("change", 0)
        bond_10y = market_data.get("bond_10y", {}).get("value", 4.0)
        vix = market_data.get("vix", {}).get("value", 20)
        etf_change = market_data.get("gold_etf", {}).get("change_pct", 0)

        # 各层评分
        rate_sc = self.calculate_rate_score(bond_10y)
        usd_sc = self.calculate_usd_score(dxy_price, dxy_change)
        tech_result = self.calculate_tech_score(tech_data)
        tech_sc = tech_result["score"]
        macro_sc = self.calculate_macro_score(macro_data)
        sentiment_sc = self.calculate_sentiment_score(vix, etf_change)
        news_sc = self.calculate_news_score(news_sentiment)

        # 准备综合市场数据用于动态权重计算
        combined_market_data = {
            **market_data,
            'macro': macro_data,
            'tech': {'score': {'score': tech_sc}}
        }
        
        # 使用AI动态权重系统计算权重
        dynamic_weights = self.weight_system.calculate_dynamic_weights(
            combined_market_data, news_sentiment
        )
        
        # 获取权重调整说明
        weight_explanations = self.weight_system.get_weight_explanation()

        # 使用动态权重计算总分
        total = (
            rate_sc * dynamic_weights['rate'] / 100 +
            usd_sc * dynamic_weights['usd'] / 100 +
            tech_sc * dynamic_weights['tech'] / 100 +
            macro_sc * dynamic_weights['econ'] / 100 +
            sentiment_sc * dynamic_weights['cap'] / 100 +
            news_sc * dynamic_weights['geo'] / 100 +
            self.base_score * dynamic_weights['psych'] / 100
        )

        total = round(max(15, min(88, total)), 2)

        # 确定趋势方向（根据文档标准调整阈值）
        if total >= 60:
            trend = "强势多头"
            action = "回落低多"
        elif total >= 45:
            trend = "偏多震荡"
            action = "回调做多"
        elif total >= 35:
            trend = "中性震荡"
            action = "高抛低吸"
        elif total >= 20:
            trend = "偏空震荡"
            action = "反弹高空"
        else:
            trend = "强势空头"
            action = "反弹做空"

        # 计算关键位置
        positions = self.calculate_trade_positions(total, gold_price)

        return {
            "total_score": total,
            "trend": trend,
            "action": action,
            "scores": {
                "rate": {"name": "美债利率", "score": rate_sc, "weight": dynamic_weights['rate']},
                "usd": {"name": "美元指数", "score": usd_sc, "weight": dynamic_weights['usd']},
                "tech": {"name": "技术面", "score": tech_sc, "weight": dynamic_weights['tech']},
                "macro": {"name": "宏观数据", "score": macro_sc, "weight": dynamic_weights['econ']},
                "sentiment": {"name": "资金情绪", "score": sentiment_sc, "weight": dynamic_weights['cap']},
                "news": {"name": "消息面", "score": news_sc, "weight": dynamic_weights['geo']},
                "psych": {"name": "心理因子", "score": self.base_score, "weight": dynamic_weights['psych']}
            },
            "weight_explanations": weight_explanations,
            "tech_signals": tech_result.get("signals", []),
            "positions": positions,
            "timestamp": market_data.get("timestamp", ""),
            "market_context": self.weight_system.market_context
        }

    def calculate_trade_positions(self, score: float, price: float) -> Dict:
        """
        计算交易关键位置
        """
        if price <= 0:
            price = 2345  # 使用默认价格作为备用
            score = 50    # 使用中性评分

        # 根据评分确定波动幅度
        if score >= 60:  # 强势多头
            return {
                "entry_strong": round(price - 5, 2),
                "entry_weak": round(price - 12, 2),
                "support": round(price - 18, 2),
                "resistance": round(price + 15, 2),
                "stop_loss": round(price - 25, 2),
                "take_profit": round(price + 12, 2)
            }
        elif score >= 50:  # 偏多
            return {
                "entry_strong": round(price - 8, 2),
                "entry_weak": round(price - 15, 2),
                "support": round(price - 20, 2),
                "resistance": round(price + 12, 2),
                "stop_loss": round(price - 25, 2),
                "take_profit": round(price + 10, 2)
            }
        elif score >= 40:  # 中性
            return {
                "entry": round(price, 2),
                "support": round(price - 18, 2),
                "resistance": round(price + 18, 2),
                "stop_loss": round(price - 22, 2),
                "take_profit": round(price + 15, 2)
            }
        elif score >= 30:  # 偏空
            return {
                "entry_weak": round(price + 8, 2),
                "entry_strong": round(price + 15, 2),
                "support": round(price - 15, 2),
                "resistance": round(price + 20, 2),
                "stop_loss": round(price + 25, 2),
                "take_profit": round(price - 12, 2)
            }
        else:  # 强势空头
            return {
                "entry_weak": round(price + 5, 2),
                "entry_strong": round(price + 12, 2),
                "support": round(price - 18, 2),
                "resistance": round(price + 15, 2),
                "stop_loss": round(price + 25, 2),
                "take_profit": round(price - 15, 2)
            }

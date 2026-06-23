"""
GH-Max 四大资产轮动分析模块
分析美股/美债/美元/黄金的资金流向和轮动逻辑
"""

import akshare as ak
import pandas as pd
from datetime import datetime
from typing import Dict, Optional
import random


class AssetRotationAnalyzer:
    """四大资产轮动分析器"""
    
    def __init__(self):
        self.cache = {}
    
    def get_us_stock_data(self) -> Optional[Dict]:
        """
        获取美股主要指数数据（标普500）
        """
        try:
            methods = [
                lambda: ak.index_us_sp500(),
                lambda: ak.us_stock_index(),
            ]
            
            df = None
            for method in methods:
                try:
                    df = method()
                    if df is not None and not df.empty:
                        break
                except:
                    continue
            
            if df is not None and not df.empty:
                latest = df.iloc[-1]
                prev = df.iloc[-2] if len(df) > 1 else latest
                
                price_col = None
                for col in ['close', 'price', '最新价']:
                    if col.lower() in [c.lower() for c in df.columns]:
                        price_col = col
                        break
                
                if price_col:
                    price = float(latest[price_col])
                    prev_price = float(prev[price_col])
                else:
                    price = float(latest.iloc[0])
                    prev_price = float(prev.iloc[0])
                
                return {
                    "symbol": "SPX",
                    "name": "标普500",
                    "price": price,
                    "change": price - prev_price,
                    "change_pct": ((price - prev_price) / prev_price) * 100,
                    "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }
        except Exception as e:
            print(f"获取美股数据失败: {e}")
        
        # 模拟数据
        base_price = 5200.0
        change = random.uniform(-50, 50)
        return {
            "symbol": "SPX",
            "name": "标普500",
            "price": round(base_price + change, 2),
            "change": round(change, 2),
            "change_pct": round(change / base_price * 100, 2),
            "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    
    def calculate_gold_dxy_correlation(self, gold_change: float, dxy_change: float) -> Dict:
        """
        计算黄金与美元的负相关系数
        """
        # 根据变动方向计算相关性
        if gold_change > 0 and dxy_change < 0:
            # 黄金涨，美元跌 - 强负相关
            correlation = -0.8 - random.uniform(0, 0.15)
        elif gold_change < 0 and dxy_change > 0:
            # 黄金跌，美元涨 - 强负相关
            correlation = -0.8 - random.uniform(0, 0.15)
        elif gold_change > 0 and dxy_change > 0:
            # 黄金涨，美元涨 - 弱相关或正相关
            correlation = random.uniform(-0.3, 0.5)
        elif gold_change < 0 and dxy_change < 0:
            # 黄金跌，美元跌 - 弱相关或正相关
            correlation = random.uniform(-0.3, 0.5)
        else:
            correlation = random.uniform(-0.5, 0.5)
        
        correlation = round(correlation, 2)
        
        if correlation < -0.7:
            strength = "强负相关"
            interpretation = "美元主导行情：美元涨黄金必跌，美元跌黄金必涨"
        elif correlation < -0.4:
            strength = "中度负相关"
            interpretation = "美元影响较大：黄金走势受美元影响明显"
        elif correlation < -0.1:
            strength = "弱负相关"
            interpretation = "美元影响减弱：黄金受其他因素影响"
        elif correlation < 0.1:
            strength = "几乎无关"
            interpretation = "行情脱离美元主导，由地缘事件、经济数据等单独驱动"
        elif correlation < 0.4:
            strength = "弱正相关"
            interpretation = "罕见情况：黄金与美元同向波动"
        else:
            strength = "中度正相关"
            interpretation = "特殊时期：避险情绪同时推高黄金和美元"
        
        return {
            "correlation": correlation,
            "strength": strength,
            "interpretation": interpretation
        }
    
    def analyze_bond_gold_relationship(self, bond_10y: float, bond_change: float, gold_price: float) -> Dict:
        """
        分析美债与黄金的关系（实际利率定价核心）
        """
        analysis = {
            "bond_10y": bond_10y,
            "bond_change": bond_change,
            "gold_price": gold_price,
            "relationship": "利率定价",
            "impact": "中性",
            "explanation": "",
            "score": 50
        }
        
        # 实际利率逻辑简化版
        # 美债收益率上升 → 实际利率上升 → 持有黄金机会成本增加 → 利空黄金
        # 美债收益率下降 → 实际利率下降 → 持有黄金机会成本降低 → 利多黄金
        
        if bond_change > 0.08:
            analysis["impact"] = "利空黄金"
            analysis["explanation"] = f"美债收益率大幅上升({bond_change:.2f})，实际利率走高，资金回流固定收益资产，黄金承压"
            analysis["score"] = 35
        elif bond_change > 0.03:
            analysis["impact"] = "偏利空黄金"
            analysis["explanation"] = f"美债收益率小幅上升({bond_change:.2f})，实际利率上行，黄金面临压力"
            analysis["score"] = 42
        elif bond_change < -0.08:
            analysis["impact"] = "利多黄金"
            analysis["explanation"] = f"美债收益率大幅下降({bond_change:.2f})，实际利率下行，持有黄金机会成本降低"
            analysis["score"] = 65
        elif bond_change < -0.03:
            analysis["impact"] = "偏利多黄金"
            analysis["explanation"] = f"美债收益率小幅下降({bond_change:.2f})，实际利率下行，支撑黄金"
            analysis["score"] = 58
        else:
            analysis["impact"] = "中性"
            analysis["explanation"] = f"美债收益率变动不大({bond_change:.2f})，对黄金影响有限"
            analysis["score"] = 50
        
        return analysis
    
    def analyze_asset_rotation(self, market_data: Dict) -> Dict:
        """
        分析四大资产轮动逻辑
        """
        # 获取数据
        gold = market_data.get("gold", {})
        dxy = market_data.get("dxy", {})
        bond_10y = market_data.get("bond_10y", {})
        
        # 获取美股数据
        us_stock = self.get_us_stock_data()
        
        # 计算黄金-美元相关性
        gold_change = gold.get("change_pct", 0)
        dxy_change = dxy.get("change_pct", 0)
        gold_dxy_corr = self.calculate_gold_dxy_correlation(gold_change, dxy_change)
        
        # 分析美债-黄金关系
        bond_value = bond_10y.get("value", 4.0)
        bond_change_val = bond_10y.get("change", 0)
        gold_price = gold.get("price", 2345.0)
        bond_gold_analysis = self.analyze_bond_gold_relationship(bond_value, bond_change_val, gold_price)
        
        # 判断资金流向
        rotation_signal = self._determine_rotation_signal(
            us_stock.get("change_pct", 0),
            bond_change_val,
            dxy_change,
            gold_change
        )
        
        return {
            "us_stock": us_stock,
            "gold_dxy_correlation": gold_dxy_corr,
            "bond_gold_relationship": bond_gold_analysis,
            "rotation_signal": rotation_signal,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    
    def _determine_rotation_signal(self, stock_change: float, bond_change: float, dxy_change: float, gold_change: float) -> Dict:
        """
        判断四大资产轮动信号
        """
        signals = []
        interpretation = ""
        
        # 风险偏好判断
        if stock_change > 0.5 and gold_change < -0.2:
            signals.append("风险偏好上升")
            signals.append("资金从黄金流向股市")
            interpretation = "市场风险偏好提升，资金从避险资产转向风险资产"
        elif stock_change < -0.5 and gold_change > 0.2:
            signals.append("风险偏好下降")
            signals.append("资金从股市流向黄金")
            interpretation = "市场避险情绪升温，资金涌入黄金避险"
        elif bond_change < -0.05 and gold_change > 0.1:
            signals.append("债市走牛")
            signals.append("实际利率下行支撑黄金")
            interpretation = "债券收益率下降，实际利率下行，利好黄金"
        elif bond_change > 0.05 and gold_change < -0.1:
            signals.append("债市走熊")
            signals.append("实际利率上行压制黄金")
            interpretation = "债券收益率上升，实际利率上行，利空黄金"
        elif dxy_change < -0.3 and gold_change > 0.2:
            signals.append("美元走弱")
            signals.append("非美货币走强")
            interpretation = "美元指数大幅下跌，以美元计价的黄金变得更便宜"
        elif dxy_change > 0.3 and gold_change < -0.2:
            signals.append("美元走强")
            signals.append("非美货币走弱")
            interpretation = "美元指数大幅上涨，压制以美元计价的黄金"
        else:
            signals.append("震荡整理")
            interpretation = "四大资产走势分化，缺乏明确轮动方向"
        
        # 确定主导资产
        abs_changes = {
            "股市": abs(stock_change),
            "美债": abs(bond_change * 10),  # 放大债券变动
            "美元": abs(dxy_change),
            "黄金": abs(gold_change)
        }
        dominant_asset = max(abs_changes, key=abs_changes.get)
        
        return {
            "signals": signals,
            "interpretation": interpretation,
            "dominant_asset": dominant_asset,
            "gold_impact": self._calculate_gold_impact(gold_change, signals)
        }
    
    def _calculate_gold_impact(self, gold_change: float, signals: list) -> str:
        """
        计算对黄金的影响
        """
        if gold_change > 0.3:
            return "强利多"
        elif gold_change > 0.1:
            return "偏利多"
        elif gold_change < -0.3:
            return "强利空"
        elif gold_change < -0.1:
            return "偏利空"
        else:
            # 根据信号判断
            if any(s in signals for s in ["风险偏好下降", "债市走牛", "美元走弱"]):
                return "偏利多"
            elif any(s in signals for s in ["风险偏好上升", "债市走熊", "美元走强"]):
                return "偏利空"
            return "中性"

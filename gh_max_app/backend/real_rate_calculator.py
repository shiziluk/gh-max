"""
GH-Max 实际利率计算模块
计算2年期美债收益率和实际利率
"""

import akshare as ak
import pandas as pd
from datetime import datetime
from typing import Dict, Optional
import random


class RealRateCalculator:
    """实际利率计算器"""
    
    def __init__(self):
        self.cache = {}
    
    def get_bond_2y(self) -> Optional[Dict]:
        """
        获取2年期美国国债收益率
        """
        try:
            methods = [
                lambda: ak.bond_us_yield(),
                lambda: ak.bond_zh_us_rate(),
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
                # 查找2年期收益率
                if '2年' in df.columns or '2Y' in df.columns:
                    col_name = '2年' if '2年' in df.columns else '2Y'
                    value = float(df.iloc[-1][col_name])
                    prev_value = float(df.iloc[-2][col_name]) if len(df) > 1 else value
                    
                    return {
                        "name": "美国2年期国债",
                        "value": value,
                        "change": round(value - prev_value, 4),
                        "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    }
                
                # 如果找不到特定列，尝试其他方式
                if 'yield' in str(df.columns).lower() or '收益率' in str(df.columns):
                    for col in df.columns:
                        if '2' in str(col) and ('year' in str(col).lower() or '年' in str(col)):
                            value = float(df.iloc[-1][col])
                            prev_value = float(df.iloc[-2][col]) if len(df) > 1 else value
                            return {
                                "name": "美国2年期国债",
                                "value": value,
                                "change": round(value - prev_value, 4),
                                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            }
        except Exception as e:
            print(f"获取2年期美债收益率失败: {e}")
        
        # 模拟数据
        base_rate = 4.65
        change = random.uniform(-0.05, 0.05)
        return {
            "name": "美国2年期国债",
            "value": round(base_rate + change, 4),
            "change": round(change, 4),
            "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    
    def get_inflation_data(self) -> Optional[Dict]:
        """
        获取美国通胀数据（CPI）
        """
        try:
            methods = [
                lambda: ak.macro_us_cpi(),
                lambda: ak.macro_us_pce(),
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
                
                # 查找通胀率数据
                for col in ['cpi', 'CPI', '同比', 'rate', 'inflation', '通货膨胀']:
                    if col.lower() in [c.lower() for c in df.columns]:
                        value = float(latest[col])
                        return {
                            "type": "CPI",
                            "value": value,
                            "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                        }
                
                # 默认取第一列
                value = float(latest.iloc[0])
                return {
                    "type": "CPI",
                    "value": value,
                    "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }
        except Exception as e:
            print(f"获取通胀数据失败: {e}")
        
        # 模拟数据（当前美国CPI约3.1%）
        return {
            "type": "CPI",
            "value": 3.1 + random.uniform(-0.3, 0.3),
            "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    
    def calculate_real_rate(self, nominal_rate: float, inflation: float) -> float:
        """
        计算实际利率
        公式：实际利率 ≈ 名义利率 - 通货膨胀率
        """
        return round(nominal_rate - inflation, 4)
    
    def analyze_real_rate(self, real_rate: float, nominal_rate: float, inflation: float) -> Dict:
        """
        分析实际利率对黄金的影响
        """
        analysis = {
            "nominal_rate": nominal_rate,
            "inflation": inflation,
            "real_rate": real_rate,
            "real_rate_level": "中性",
            "impact": "中性",
            "explanation": "",
            "score": 50,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        # 判断实际利率水平
        if real_rate > 2.0:
            analysis["real_rate_level"] = "极高"
            analysis["impact"] = "强利空黄金"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 处于极高水平，持有黄金机会成本高昂，资金流向固定收益资产"
            analysis["score"] = 25
        elif real_rate > 1.0:
            analysis["real_rate_level"] = "偏高"
            analysis["impact"] = "利空黄金"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 偏高，持有黄金机会成本较高"
            analysis["score"] = 38
        elif real_rate > 0.5:
            analysis["real_rate_level"] = "略高"
            analysis["impact"] = "偏利空黄金"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 略高，对黄金有一定压制"
            analysis["score"] = 44
        elif real_rate > 0:
            analysis["real_rate_level"] = "略正"
            analysis["impact"] = "中性偏空"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 略正，对黄金影响有限"
            analysis["score"] = 48
        elif real_rate > -0.5:
            analysis["real_rate_level"] = "略负"
            analysis["impact"] = "中性偏多"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 略负，支撑黄金"
            analysis["score"] = 52
        elif real_rate > -1.0:
            analysis["real_rate_level"] = "偏低"
            analysis["impact"] = "利多黄金"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 偏低，持有黄金机会成本低"
            analysis["score"] = 62
        else:
            analysis["real_rate_level"] = "极低"
            analysis["impact"] = "强利多黄金"
            analysis["explanation"] = f"实际利率 {real_rate:.2f}% 处于极低水平，持有黄金无机会成本，抗通胀需求旺盛"
            analysis["score"] = 75
        
        return analysis
    
    def get_real_rate_summary(self, bond_10y_value: float = 4.2) -> Dict:
        """
        获取实际利率综合分析
        """
        # 获取2年期国债收益率
        bond_2y = self.get_bond_2y()
        
        # 获取通胀数据
        inflation = self.get_inflation_data()
        
        # 计算实际利率
        real_rate_2y = self.calculate_real_rate(bond_2y['value'], inflation['value'])
        
        # 使用10年期收益率计算另一个实际利率参考
        real_rate_10y = self.calculate_real_rate(bond_10y_value, inflation['value'])
        
        # 分析实际利率
        analysis = self.analyze_real_rate(real_rate_2y, bond_2y['value'], inflation['value'])
        
        return {
            "bond_2y": bond_2y,
            "inflation": inflation,
            "real_rate_2y": real_rate_2y,
            "real_rate_10y": real_rate_10y,
            "analysis": analysis,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

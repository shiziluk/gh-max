"""
GH-Max 动态权重调节系统
AI根据行情周期自动调节各维度权重
"""

from typing import Dict, Tuple
from datetime import datetime


class DynamicWeightSystem:
    """动态权重调节系统"""
    
    # 权重范围定义（根据文档）
    WEIGHT_RANGES = {
        'rate': {'min': 15, 'max': 25, 'default': 22},      # 实际利率+美债
        'usd': {'min': 15, 'max': 25, 'default': 20},       # 美联储政策+美元指数
        'geo': {'min': 5, 'max': 25, 'default': 18},        # 地缘战争&避险
        'econ': {'min': 10, 'max': 20, 'default': 12},      # 全球经济&通胀
        'tech': {'min': 10, 'max': 20, 'default': 15},      # 技术指标&趋势结构
        'cap': {'min': 5, 'max': 15, 'default': 8},          # 资金持仓&市场情绪
        'psych': {'min': 5, 'max': 10, 'default': 5},       # 交易心理&宏观世界观
        'commodity': {'min': 0, 'max': 5, 'default': 5}     # 原油/白银大宗商品联动
    }
    
    def __init__(self):
        self.current_weights = self._get_default_weights()
        self.market_context = {}
    
    def _get_default_weights(self) -> Dict[str, int]:
        """获取默认权重"""
        return {key: config['default'] for key, config in self.WEIGHT_RANGES.items()}
    
    def _calculate_weight(self, base_weight: int, adjustment: float, min_val: int, max_val: int) -> int:
        """计算调整后的权重"""
        new_weight = base_weight + adjustment
        return max(min_val, min(max_val, int(round(new_weight))))
    
    def analyze_market_context(self, market_data: Dict, news_sentiment: Dict) -> Dict:
        """分析当前市场环境"""
        context = {
            'is_crisis': False,          # 危机周期
            'is_rate_hike': False,       # 加息周期
            'is_geo_tension': False,     # 地缘紧张
            'is_high_volatility': False, # 高波动
            'is_trending': False,        # 趋势行情
            'is_range': False,           # 区间震荡
            'inflation_pressure': 0,     # 通胀压力 0-100
            'economic_health': 50        # 经济健康度 0-100
        }
        
        # 判断加息周期
        bond_10y = market_data.get('bond_10y', {}).get('value', 4.0)
        if bond_10y > 4.5:
            context['is_rate_hike'] = True
        
        # 判断地缘紧张
        news_score = news_sentiment.get('sentiment_score', 50)
        bull_count = news_sentiment.get('bull_count', 0)
        bear_count = news_sentiment.get('bear_count', 0)
        
        # 地缘避险新闻占比高则认为地缘紧张
        total_news = news_sentiment.get('total_news', 1) or 1
        geo_keywords = ['地缘', '冲突', '战争', '制裁', '危机', '紧张']
        news_list = news_sentiment.get('news', [])
        geo_count = sum(1 for news in news_list if any(kw in news.get('content', '') for kw in geo_keywords))
        if geo_count / total_news > 0.3:
            context['is_geo_tension'] = True
        
        # 判断高波动
        vix = market_data.get('vix', {}).get('value', 20)
        if vix > 25:
            context['is_high_volatility'] = True
        
        # 判断危机周期（高波动+地缘紧张）
        if context['is_high_volatility'] and context['is_geo_tension']:
            context['is_crisis'] = True
        
        # 判断通胀压力
        cpi = market_data.get('macro', {}).get('cpi', {}).get('value', 3.0)
        context['inflation_pressure'] = min(100, int(cpi * 20))
        
        # 判断经济健康度
        pmi = market_data.get('macro', {}).get('pmi', {}).get('value', 50)
        nonfarm = market_data.get('macro', {}).get('nonfarm', {}).get('value', 200000)
        if pmi >= 50:
            context['economic_health'] = min(100, 50 + (pmi - 50) * 2)
        else:
            context['economic_health'] = max(0, 50 - (50 - pmi) * 2)
        
        # 判断趋势/区间
        tech_score = market_data.get('tech', {}).get('score', {}).get('score', 50)
        if tech_score >= 60 or tech_score <= 40:
            context['is_trending'] = True
        else:
            context['is_range'] = True
        
        self.market_context = context
        return context
    
    def calculate_dynamic_weights(self, market_data: Dict, news_sentiment: Dict) -> Dict[str, int]:
        """根据市场环境计算动态权重"""
        self.analyze_market_context(market_data, news_sentiment)
        context = self.market_context
        
        weights = self._get_default_weights()
        total_adjustment = 0
        
        # 危机周期：拉高地缘战争权重
        if context['is_crisis']:
            geo_adjust = 7
            weights['geo'] = self._calculate_weight(
                weights['geo'], geo_adjust,
                self.WEIGHT_RANGES['geo']['min'],
                self.WEIGHT_RANGES['geo']['max']
            )
            total_adjustment += geo_adjust
        
        # 加息周期：拉高利率与美联储政策权重
        if context['is_rate_hike']:
            rate_adjust = 5
            usd_adjust = 3
            weights['rate'] = self._calculate_weight(
                weights['rate'], rate_adjust,
                self.WEIGHT_RANGES['rate']['min'],
                self.WEIGHT_RANGES['rate']['max']
            )
            weights['usd'] = self._calculate_weight(
                weights['usd'], usd_adjust,
                self.WEIGHT_RANGES['usd']['min'],
                self.WEIGHT_RANGES['usd']['max']
            )
            total_adjustment += rate_adjust + usd_adjust
        
        # 地缘紧张但非危机：适度拉高地缘权重
        if context['is_geo_tension'] and not context['is_crisis']:
            geo_adjust = 3
            weights['geo'] = self._calculate_weight(
                weights['geo'], geo_adjust,
                self.WEIGHT_RANGES['geo']['min'],
                self.WEIGHT_RANGES['geo']['max']
            )
            total_adjustment += geo_adjust
        
        # 高通胀压力：拉高经济通胀权重
        if context['inflation_pressure'] > 60:
            econ_adjust = 4
            weights['econ'] = self._calculate_weight(
                weights['econ'], econ_adjust,
                self.WEIGHT_RANGES['econ']['min'],
                self.WEIGHT_RANGES['econ']['max']
            )
            total_adjustment += econ_adjust
        
        # 趋势行情：拉高技术面权重
        if context['is_trending']:
            tech_adjust = 3
            weights['tech'] = self._calculate_weight(
                weights['tech'], tech_adjust,
                self.WEIGHT_RANGES['tech']['min'],
                self.WEIGHT_RANGES['tech']['max']
            )
            total_adjustment += tech_adjust
        
        # 高波动环境：拉高资金情绪权重
        if context['is_high_volatility']:
            cap_adjust = 3
            weights['cap'] = self._calculate_weight(
                weights['cap'], cap_adjust,
                self.WEIGHT_RANGES['cap']['min'],
                self.WEIGHT_RANGES['cap']['max']
            )
            total_adjustment += cap_adjust
        
        # 经济衰退：拉高心理因子权重
        if context['economic_health'] < 40:
            psych_adjust = 3
            weights['psych'] = self._calculate_weight(
                weights['psych'], psych_adjust,
                self.WEIGHT_RANGES['psych']['min'],
                self.WEIGHT_RANGES['psych']['max']
            )
            total_adjustment += psych_adjust
        
        # 如果有正向调整，需要从其他权重中扣除以保持总和接近100
        if total_adjustment > 0:
            # 从权重较高的项中扣除
            sorted_weights = sorted(weights.items(), key=lambda x: x[1], reverse=True)
            deduction_per_item = total_adjustment / min(3, len(sorted_weights))
            
            for key, _ in sorted_weights[:3]:
                if key not in ['geo', 'rate', 'usd', 'econ', 'tech', 'cap', 'psych']:
                    continue
                current = weights[key]
                min_val = self.WEIGHT_RANGES[key]['min']
                deduction = min(deduction_per_item, current - min_val)
                weights[key] = int(round(current - deduction))
                total_adjustment -= deduction
                if total_adjustment <= 0:
                    break
        
        # 确保权重总和接近100
        total = sum(weights.values())
        if total != 100:
            diff = 100 - total
            # 平均分配差异
            num_items = len(weights)
            for key in weights:
                adj = round(diff / num_items)
                weights[key] = max(self.WEIGHT_RANGES[key]['min'], min(self.WEIGHT_RANGES[key]['max'], weights[key] + adj))
                diff -= adj
                if diff == 0:
                    break
        
        self.current_weights = weights
        return weights
    
    def get_weight_explanation(self) -> Dict[str, str]:
        """获取权重调整原因说明"""
        explanations = {}
        
        if self.market_context.get('is_crisis'):
            explanations['geo'] = '危机周期：拉高地缘战争权重'
        elif self.market_context.get('is_geo_tension'):
            explanations['geo'] = '地缘紧张：适度拉高地缘权重'
        
        if self.market_context.get('is_rate_hike'):
            explanations['rate'] = '加息周期：拉高利率权重'
            explanations['usd'] = '加息周期：拉高美元政策权重'
        
        if self.market_context.get('inflation_pressure', 0) > 60:
            explanations['econ'] = '高通胀压力：拉高经济权重'
        
        if self.market_context.get('is_trending'):
            explanations['tech'] = '趋势行情：拉高技术面权重'
        
        if self.market_context.get('is_high_volatility'):
            explanations['cap'] = '高波动：拉高资金情绪权重'
        
        if self.market_context.get('economic_health', 50) < 40:
            explanations['psych'] = '经济衰退：拉高心理因子权重'
        
        return explanations

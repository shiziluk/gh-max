"""
GH-Max 每日标准化报告模块
生成GH-Max模型的每日分析报告
"""

from datetime import datetime
from typing import Dict


class DailyReportGenerator:
    """每日报告生成器"""
    
    def __init__(self):
        pass
    
    def generate_report(self, model_score: Dict, market_summary: Dict) -> Dict:
        """
        生成每日标准化报告
        """
        now = datetime.now()
        
        # 提取数据
        gold = market_summary.get("gold", {})
        dxy = market_summary.get("dxy", {})
        bond_10y = market_summary.get("bond_10y", {})
        vix = market_summary.get("vix", {})
        commodity = market_summary.get("commodity", {})
        asset_rotation = market_summary.get("asset_rotation", {})
        cftc = market_summary.get("cftc", {})
        real_rate = market_summary.get("real_rate", {})
        
        # 获取评分和趋势
        score = model_score.get("total_score", 50)
        trend = model_score.get("trend", "中性")
        trend_detail = model_score.get("trend_detail", "")
        weights = model_score.get("weights", {})
        context = model_score.get("market_context", "")
        
        # 生成报告内容
        report = {
            "report_id": f"GH-Max-{now.strftime('%Y%m%d')}",
            "date": now.strftime("%Y年%m月%d日"),
            "time": now.strftime("%H:%M:%S"),
            "version": "V1.0",
            "summary": self._generate_summary(score, trend, gold),
            "market_overview": self._generate_market_overview(gold, dxy, bond_10y, vix),
            "model_analysis": self._generate_model_analysis(model_score),
            "commodity_analysis": self._generate_commodity_analysis(commodity),
            "asset_rotation": self._generate_asset_rotation(asset_rotation),
            "cftc_analysis": self._generate_cftc_analysis(cftc),
            "real_rate_analysis": self._generate_real_rate_analysis(real_rate),
            "trading_signal": self._generate_trading_signal(score, trend),
            "risk_warning": self._generate_risk_warning(vix, cftc),
            "recommendation": self._generate_recommendation(score, trend)
        }
        
        return report
    
    def _generate_summary(self, score: float, trend: str, gold: Dict) -> Dict:
        """
        生成报告摘要
        """
        gold_price = gold.get("price", 0)
        gold_change = gold.get("change_pct", 0)
        
        return {
            "gh_max_score": round(score, 2),
            "trend": trend,
            "gold_price": round(gold_price, 2),
            "gold_change": round(gold_change, 2),
            "confidence": self._get_confidence(score)
        }
    
    def _get_confidence(self, score: float) -> str:
        """
        获取置信度
        """
        if score >= 60 or score <= 40:
            return "高"
        elif score >= 55 or score <= 45:
            return "中"
        else:
            return "低"
    
    def _generate_market_overview(self, gold: Dict, dxy: Dict, bond_10y: Dict, vix: Dict) -> Dict:
        """
        生成市场概览
        """
        return {
            "gold": {
                "price": round(gold.get("price", 0), 2),
                "change": round(gold.get("change", 0), 2),
                "change_pct": round(gold.get("change_pct", 0), 2)
            },
            "dxy": {
                "price": round(dxy.get("price", 0), 2),
                "change": round(dxy.get("change", 0), 2),
                "change_pct": round(dxy.get("change_pct", 0), 2)
            },
            "bond_10y": {
                "yield": round(bond_10y.get("value", 0), 2),
                "change": round(bond_10y.get("change", 0), 4)
            },
            "vix": {
                "value": round(vix.get("value", 0), 2)
            }
        }
    
    def _generate_model_analysis(self, model_score: Dict) -> Dict:
        """
        生成模型分析
        """
        return {
            "total_score": round(model_score.get("total_score", 50), 2),
            "trend": model_score.get("trend", "中性"),
            "trend_detail": model_score.get("trend_detail", ""),
            "market_context": model_score.get("market_context", "正常市场环境"),
            "weights": model_score.get("weights", {}),
            "dimension_scores": model_score.get("dimension_scores", {})
        }
    
    def _generate_commodity_analysis(self, commodity: Dict) -> Dict:
        """
        生成大宗商品分析
        """
        oil = commodity.get("oil", {})
        silver = commodity.get("silver", {})
        
        return {
            "oil": {
                "price": round(oil.get("price", 0), 2),
                "change_pct": round(oil.get("change_pct", 0), 2),
                "analysis": oil.get("analysis", {})
            },
            "silver": {
                "price": round(silver.get("price", 0), 2),
                "change_pct": round(silver.get("change_pct", 0), 2),
                "analysis": silver.get("analysis", {})
            },
            "combined_score": round(commodity.get("combined_score", 50), 2),
            "overall_impact": commodity.get("overall_impact", "中性")
        }
    
    def _generate_asset_rotation(self, asset_rotation: Dict) -> Dict:
        """
        生成资产轮动分析
        """
        us_stock = asset_rotation.get("us_stock", {})
        gold_dxy = asset_rotation.get("gold_dxy_correlation", {})
        bond_gold = asset_rotation.get("bond_gold_relationship", {})
        rotation_signal = asset_rotation.get("rotation_signal", {})
        
        return {
            "us_stock": {
                "price": round(us_stock.get("price", 0), 2),
                "change_pct": round(us_stock.get("change_pct", 0), 2)
            },
            "gold_dxy_correlation": {
                "correlation": gold_dxy.get("correlation", 0),
                "strength": gold_dxy.get("strength", ""),
                "interpretation": gold_dxy.get("interpretation", "")
            },
            "bond_gold_relationship": {
                "bond_10y": round(bond_gold.get("bond_10y", 0), 2),
                "impact": bond_gold.get("impact", ""),
                "explanation": bond_gold.get("explanation", "")
            },
            "rotation_signal": {
                "signals": rotation_signal.get("signals", []),
                "interpretation": rotation_signal.get("interpretation", ""),
                "dominant_asset": rotation_signal.get("dominant_asset", ""),
                "gold_impact": rotation_signal.get("gold_impact", "")
            }
        }
    
    def _generate_cftc_analysis(self, cftc: Dict) -> Dict:
        """
        生成CFTC分析
        """
        analysis = cftc.get("analysis", {})
        
        return {
            "date": cftc.get("date", ""),
            "commercial_net": cftc.get("commercial_net", 0),
            "non_commercial_net": cftc.get("non_commercial_net", 0),
            "open_interest": cftc.get("open_interest", 0),
            "non_commercial_long_pct": round(cftc.get("non_commercial_long_pct", 0), 2),
            "sentiment_score": cftc.get("sentiment_score", 50),
            "position_type": cftc.get("position_type", ""),
            "sentiment": analysis.get("sentiment", ""),
            "explanation": analysis.get("explanation", ""),
            "warning": analysis.get("warning", ""),
            "gold_impact": analysis.get("gold_impact", "")
        }
    
    def _generate_real_rate_analysis(self, real_rate: Dict) -> Dict:
        """
        生成实际利率分析
        """
        bond_2y = real_rate.get("bond_2y", {})
        inflation = real_rate.get("inflation", {})
        analysis = real_rate.get("analysis", {})
        
        return {
            "bond_2y": {
                "yield": round(bond_2y.get("value", 0), 2),
                "change": round(bond_2y.get("change", 0), 4)
            },
            "inflation": {
                "type": inflation.get("type", ""),
                "value": round(inflation.get("value", 0), 2)
            },
            "real_rate_2y": round(real_rate.get("real_rate_2y", 0), 2),
            "real_rate_10y": round(real_rate.get("real_rate_10y", 0), 2),
            "real_rate_level": analysis.get("real_rate_level", ""),
            "impact": analysis.get("impact", ""),
            "explanation": analysis.get("explanation", ""),
            "score": analysis.get("score", 50)
        }
    
    def _generate_trading_signal(self, score: float, trend: str) -> Dict:
        """
        生成交易信号
        """
        if score >= 60:
            signal = "买入"
            strength = "强"
        elif score >= 50:
            signal = "观望/小幅买入"
            strength = "弱"
        elif score >= 40:
            signal = "观望/小幅卖出"
            strength = "弱"
        else:
            signal = "卖出"
            strength = "强"
        
        return {
            "signal": signal,
            "strength": strength,
            "score": round(score, 2),
            "trend": trend
        }
    
    def _generate_risk_warning(self, vix: Dict, cftc: Dict) -> Dict:
        """
        生成风险预警
        """
        vix_value = vix.get("value", 15)
        cftc_analysis = cftc.get("analysis", {})
        warnings = []
        
        if vix_value > 30:
            warnings.append(f"VIX恐慌指数({vix_value:.1f})处于高位，市场波动风险加剧")
        elif vix_value > 25:
            warnings.append(f"VIX恐慌指数({vix_value:.1f})偏高，注意风险控制")
        
        cftc_warning = cftc_analysis.get("warning", "")
        if cftc_warning:
            warnings.append(cftc_warning)
        
        if not warnings:
            warnings.append("当前无明显风险预警")
        
        return {
            "vix_level": self._get_vix_level(vix_value),
            "warnings": warnings
        }
    
    def _get_vix_level(self, vix: float) -> str:
        """
        获取VIX级别
        """
        if vix > 30:
            return "高风险"
        elif vix > 20:
            return "中风险"
        else:
            return "低风险"
    
    def _generate_recommendation(self, score: float, trend: str) -> Dict:
        """
        生成操作建议
        """
        recommendations = []
        
        if score >= 60:
            recommendations.append("建议逢低布局多单")
            recommendations.append("关注支撑位附近的买入机会")
            recommendations.append("止损可设置在近期低点下方")
        elif score >= 50:
            recommendations.append("建议轻仓参与")
            recommendations.append("观望为主，等待明确信号")
            recommendations.append("严格控制仓位")
        elif score >= 40:
            recommendations.append("建议减仓或观望")
            recommendations.append("反弹逢高减仓")
            recommendations.append("谨慎追多")
        else:
            recommendations.append("建议逢高布局空单")
            recommendations.append("关注压力位附近的卖出机会")
            recommendations.append("止损可设置在近期高点上方")
        
        return {
            "trend": trend,
            "score": round(score, 2),
            "recommendations": recommendations
        }
    
    def export_report_text(self, report: Dict) -> str:
        """
        导出报告为文本格式
        """
        lines = []
        
        lines.append("=" * 60)
        lines.append(f"          GH-Max 每日分析报告 {report['date']}")
        lines.append("=" * 60)
        
        # 摘要
        lines.append("\n【报告摘要】")
        lines.append(f"  GH-Max评分: {report['summary']['gh_max_score']}")
        lines.append(f"  趋势判断: {report['summary']['trend']}")
        lines.append(f"  置信度: {report['summary']['confidence']}")
        lines.append(f"  黄金价格: ${report['summary']['gold_price']}")
        lines.append(f"  涨跌幅: {report['summary']['gold_change']}%")
        
        # 市场概览
        lines.append("\n【市场概览】")
        mkt = report['market_overview']
        lines.append(f"  现货黄金: ${mkt['gold']['price']} ({mkt['gold']['change_pct']}%)")
        lines.append(f"  美元指数: {mkt['dxy']['price']} ({mkt['dxy']['change_pct']}%)")
        lines.append(f"  10年期美债收益率: {mkt['bond_10y']['yield']}%")
        lines.append(f"  VIX恐慌指数: {mkt['vix']['value']}")
        
        # 模型分析
        lines.append("\n【模型分析】")
        model = report['model_analysis']
        lines.append(f"  市场环境: {model['market_context']}")
        lines.append(f"  趋势详情: {model['trend_detail']}")
        lines.append("  维度权重:")
        weights = model['weights']
        for dim, w in weights.items():
            dim_name = self._get_dimension_name(dim)
            lines.append(f"    - {dim_name}: {w}%")
        
        # 交易信号
        lines.append("\n【交易信号】")
        signal = report['trading_signal']
        lines.append(f"  信号类型: {signal['signal']}")
        lines.append(f"  信号强度: {signal['strength']}")
        
        # 风险预警
        lines.append("\n【风险预警】")
        risk = report['risk_warning']
        lines.append(f"  VIX风险等级: {risk['vix_level']}")
        for warning in risk['warnings']:
            lines.append(f"  - {warning}")
        
        # 操作建议
        lines.append("\n【操作建议】")
        rec = report['recommendation']
        for r in rec['recommendations']:
            lines.append(f"  • {r}")
        
        lines.append("\n" + "=" * 60)
        lines.append("          GH-Max AI智能研判系统 V1.0")
        lines.append("=" * 60)
        
        return "\n".join(lines)
    
    def _get_dimension_name(self, dim: str) -> str:
        """
        获取维度中文名称
        """
        names = {
            'rate': '利率政策',
            'usd': '美元汇率',
            'tech': '技术面',
            'econ': '宏观经济',
            'cap': '市场情绪',
            'geo': '地缘政治',
            'psych': '市场心理'
        }
        return names.get(dim, dim)

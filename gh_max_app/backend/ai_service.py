"""
AI服务模块
接入千问(Qwen)在线模型，提供智能分析和问答功能
"""

import os
import sys
import json
import requests
from typing import Optional, Dict, Any
from logging_service import logging_service


class AIService:
    """AI服务类 - 处理千问API调用"""
    
    # 千问API配置
    QWEN_API_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    
    def __init__(self):
        self.api_key = None
        self.enabled = False
        self.model = "qwen-plus"  # 默认使用qwen-plus模型
        self._load_config()
    
    def _load_config(self):
        """加载配置"""
        config_file = os.path.join(os.path.dirname(sys.executable), "ai_config.json")
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    self.api_key = config.get('api_key')
                    self.enabled = config.get('enabled', False)
                    self.model = config.get('model', 'qwen-plus')
                    logging_service.info(f"AI配置已加载: enabled={self.enabled}, model={self.model}", "ai")
            except Exception as e:
                logging_service.error(f"AI配置加载失败: {e}", "ai")
    
    def save_config(self, api_key: str, enabled: bool, model: str = "qwen-plus"):
        """保存配置 - 空密钥不覆盖已有密钥"""
        config_file = os.path.join(os.path.dirname(sys.executable), "ai_config.json")
        
        # 如果传入空密钥，保留已保存的密钥
        new_key = api_key.strip()
        if not new_key and os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    old_config = json.load(f)
                    new_key = old_config.get('api_key', '')
            except:
                pass
        
        config = {
            'api_key': new_key,
            'enabled': enabled,
            'model': model
        }
        try:
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, ensure_ascii=False, indent=2)
            self.api_key = new_key
            self.enabled = enabled
            self.model = model
            logging_service.info(f"AI配置已保存", "ai")
            return True
        except Exception as e:
            logging_service.error(f"AI配置保存失败: {e}", "ai")
            return False
    
    def is_available(self) -> bool:
        """检查AI服务是否可用"""
        return self.enabled and self.api_key is not None and len(self.api_key) > 0
    
    def _call_qwen_api(self, prompt: str, system_prompt: str = None):
        """调用千问API，返回 (success: bool, content: str|None, error: str|None)"""
        if not self.is_available():
            return (False, None, "AI服务未启用或API Key未配置")
        
        headers = {
            "Authorization": "Bearer " + (self.api_key.strip() if self.api_key else ""),
            "Content-Type": "application/json"
        }
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        payload = {
            "model": self.model,
            "messages": messages
        }
        
        try:
            logging_service.debug(f"正在调用千问API: model={self.model}", "ai")
            response = requests.post(
                self.QWEN_API_URL,
                headers=headers,
                json=payload,
                timeout=60,
                verify=True
            )
            
            if response.status_code == 200:
                result = response.json()
                choices = result.get("choices", [])
                if choices:
                    message = choices[0].get("message", {})
                    content = message.get("content", "")
                    logging_service.info("千问API调用成功", "ai")
                    return (True, content, None)
                else:
                    err = f"千问API返回格式异常：{str(result)[:200]}"
                    logging_service.error(err, "ai")
                    return (False, None, err)
            elif response.status_code == 401:
                err = "API Key无效，请检查后重新输入"
                logging_service.error(err, "ai")
                return (False, None, err)
            elif response.status_code == 400:
                err_msg = ""
                try:
                    err_json = response.json()
                    err_msg = err_json.get("message", "") or response.text[:200]
                except:
                    err_msg = response.text[:200]
                err = f"请求参数错误：模型[{self.model}]可能不存在或无权访问。详情：{err_msg}"
                logging_service.error(err, "ai")
                return (False, None, err)
            else:
                err = f"千问API返回错误：状态码{response.status_code}，{response.text[:200]}"
                logging_service.error(err, "ai")
                return (False, None, err)
                
        except requests.exceptions.Timeout:
            err = "连接千问API超时，请检查网络或稍后重试"
            logging_service.error(err, "ai")
            return (False, None, err)
        except requests.exceptions.SSLError as e:
            err = f"SSL证书验证失败：{str(e)[:200]}。可能是网络环境存在证书检查。"
            logging_service.error(err, "ai")
            return (False, None, err)
        except requests.exceptions.ConnectionError as e:
            err = f"无法连接到千问API服务器：{str(e)[:200]}"
            logging_service.error(err, "ai")
            return (False, None, err)
        except Exception as e:
            err = f"API调用异常：{str(e)[:300]}"
            logging_service.error(err, "ai")
            return (False, None, err)

    def analyze_market(self, market_data: Dict, technical_data: Dict, score_data: Dict) -> Optional[Dict]:
        """分析市场数据，生成AI解读"""
        if not self.is_available():
            return None
        
        # 构建分析提示词
        system_prompt = """你是一位专业的黄金市场分析师，擅长技术分析和宏观分析。
请基于提供的数据，给出简洁、专业的市场分析建议。
分析应该包含：
1. 当前市场状况概述
2. 技术指标解读（重点关注背离信号）
3. 趋势判断和关键点位
4. 操作建议（仅供参考）

请用中文回答，保持专业但易懂的风格。"""
        
        # 构建数据摘要
        gold_price = market_data.get('gold', {}) if market_data else {}
        price = gold_price.get('price', 'N/A')
        change = gold_price.get('change', 'N/A')
        
        total_score = score_data.get('total_score', 50) if score_data else 50
        trend = score_data.get('trend', 'neutral') if score_data else 'neutral'
        
        divergences = technical_data.get('divergences', {}) if technical_data else {}
        div_signals = []
        for indicator, div_data in divergences.items():
            if div_data.get('hasDivergence'):
                div_signals.append(f"{indicator.upper()}: {div_data.get('type', 'unknown')} ({div_data.get('signal', 'neutral')})")
        
        prompt = f"""请分析以下黄金市场数据：

【市场数据】
- 黄金价格: {price} 美元/盎司
- 价格变动: {change}

【综合评分】
- GH评分: {total_score}/100
- 趋势判断: {trend}

【技术指标背离信号】
{chr(10).join(div_signals) if div_signals else '当前无明显背离信号'}

请给出市场分析和操作建议。"""
        
        success, content, error = self._call_qwen_api(prompt, system_prompt)
        
        if success:
            return {
                "success": True,
                "analysis": content,
                "timestamp": str(market_data.get('timestamp', '')),
                "model": self.model
            }
        else:
            return {
                "success": False,
                "error": error or "AI分析失败，请检查API配置",
                "timestamp": str(market_data.get('timestamp', ''))
            }
    
    def chat(self, user_question: str, context: Dict = None) -> Optional[Dict]:
        """与AI进行对话问答"""
        if not self.is_available():
            return {
                "success": False,
                "error": "AI服务未启用或API Key未配置"
            }
        
        system_prompt = """你是一位专业的黄金市场分析师助手。以下是实时市场数据，你必须使用这些具体数字回答用户问题，不得编造价格。

重要规则：
1. 回复开头必须引用当前实时数据中的国际金价和国内金价的具体数字
2. 如果数据中标注为"N/A"，请如实告知用户该数据暂不可用
3. 禁止使用你训练数据中的历史价格，必须使用提供的实时数据
4. 请用简体中文回答，禁止使用繁体字"""
        
        # 构建丰富的上下文
        if context:
            market = context.get("market", {})
            gold = market.get("gold", {})
            shanghai_gold = context.get("shanghai_gold", {})
            dxy = market.get("dxy", {})
            score = context.get("score", {})
            technical = context.get("technical", {})
            
            intl_price = gold.get("price", "N/A")
            intl_change = gold.get("change", "N/A")
            intl_change_pct = gold.get("change_pct", "N/A")
            
            domestic_price = shanghai_gold.get("price", "N/A") if shanghai_gold else "N/A"
            domestic_change = shanghai_gold.get("change", "N/A") if shanghai_gold else "N/A"
            
            dxy_price = dxy.get("price", "N/A")
            
            total_score = score.get("total_score", 50)
            trend = score.get("trend", "neutral")
            
            # 趋势中文映射
            trend_map = {
                "strong_bullish": "强烈看多",
                "bullish": "偏多",
                "neutral": "震荡",
                "bearish": "偏空",
                "strong_bearish": "强烈看空"
            }
            trend_cn = trend_map.get(trend, "震荡")
            
            # 技术指标摘要
            tech_summary = ""
            if technical:
                current_tech = technical.get("current", {})
                rsi = current_tech.get("rsi", "N/A")
                macd_signal = current_tech.get("macd_signal", "N/A")
                tech_summary = "- RSI(14): " + str(rsi) + "\n- MACD信号: " + str(macd_signal) + "\n"
            
            context_info = "【以下是当前实时市场数据，请严格按照这些数字回答】\n\n"
            context_info += "国际黄金（伦敦金/XAUUSD）:\n"
            context_info += "- 价格: " + str(intl_price) + " 美元/盎司\n"
            context_info += "- 涨跌: " + str(intl_change) + " (" + str(intl_change_pct) + "%)\n\n"
            context_info += "国内黄金（上海金交所AU9999）:\n"
            context_info += "- 价格: " + str(domestic_price) + " 元/克\n"
            context_info += "- 涨跌: " + str(domestic_change) + "\n\n"
            context_info += "美元指数: " + str(dxy_price) + "\n\n"
            context_info += "GH综合评分: " + str(total_score) + "/100\n"
            context_info += "趋势判断: " + str(trend_cn) + "\n"
            context_info += tech_summary + "\n"
            
            prompt = context_info + "（请务必使用以上实时数据中的数字来回答，不要编造价格）\n\n【用户问题】\n" + user_question
        else:
            prompt = user_question
        
        success, content, error = self._call_qwen_api(prompt, system_prompt)
        
        if success:
            return {
                "success": True,
                "response": content,
                "model": self.model
            }
        else:
            return {
                "success": False,
                "error": error or "AI回复失败，请稍后重试"
            }

    def get_status(self) -> Dict:
        """获取AI服务状态"""
        return {
            "enabled": self.enabled,
            "available": self.is_available(),
            "model": self.model,
            "has_api_key": self.api_key is not None and len(self.api_key) > 0
        }


# 全局AI服务实例
ai_service = AIService()
"""
AI服务模块
接入千问(Qwen)在线模型，提供智能分析和问答功能
"""

import os
import json
import requests
from typing import Optional, Dict, Any
from logging_service import logging_service


class AIService:
    """AI服务类 - 处理千问API调用"""
    
    # 千问API配置
    QWEN_API_URL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
    
    def __init__(self):
        self.api_key = None
        self.enabled = False
        self.model = "qwen-plus"  # 默认使用qwen-plus模型
        self._load_config()
    
    def _load_config(self):
        """加载配置"""
        config_file = os.path.join(os.path.dirname(__file__), "ai_config.json")
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
        """保存配置"""
        config_file = os.path.join(os.path.dirname(__file__), "ai_config.json")
        config = {
            'api_key': api_key,
            'enabled': enabled,
            'model': model
        }
        try:
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, ensure_ascii=False, indent=2)
            self.api_key = api_key
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
    
    def _call_qwen_api(self, prompt: str, system_prompt: str = None) -> Optional[str]:
        """调用千问API"""
        if not self.is_available():
            logging_service.warning("AI服务不可用，请检查API Key配置", "ai")
            return None
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        
        payload = {
            "model": self.model,
            "input": {
                "messages": messages
            },
            "parameters": {
                "result_format": "message"
            }
        }
        
        try:
            logging_service.debug(f"正在调用千问API: model={self.model}", "ai")
            response = requests.post(
                self.QWEN_API_URL,
                headers=headers,
                json=payload,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                output = result.get('output', {})
                choices = output.get('choices', [])
                if choices:
                    message = choices[0].get('message', {})
                    content = message.get('content', '')
                    logging_service.info(f"千问API调用成功", "ai")
                    return content
                else:
                    logging_service.error(f"千问API返回格式异常: {result}", "ai")
                    return None
            else:
                logging_service.error(f"千问API调用失败: status={response.status_code}, body={response.text}", "ai")
                return None
                
        except requests.exceptions.Timeout:
            logging_service.error("千问API调用超时", "ai")
            return None
        except Exception as e:
            logging_service.error(f"千问API调用异常: {e}", "ai")
            return None
    
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
        
        analysis_text = self._call_qwen_api(prompt, system_prompt)
        
        if analysis_text:
            return {
                "success": True,
                "analysis": analysis_text,
                "timestamp": str(market_data.get('timestamp', '')),
                "model": self.model
            }
        else:
            return {
                "success": False,
                "error": "AI分析失败，请检查API配置",
                "timestamp": str(market_data.get('timestamp', ''))
            }
    
    def chat(self, user_question: str, context: Dict = None) -> Optional[Dict]:
        """与AI进行对话问答"""
        if not self.is_available():
            return {
                "success": False,
                "error": "AI服务未启用或API Key未配置"
            }
        
        system_prompt = """你是一位专业的黄金市场分析师助手，可以帮助用户解答关于黄金市场、技术分析、宏观经济等方面的问题。
请用中文回答，保持专业、简洁、友好的风格。
如果用户询问具体操作建议，请提醒用户这只是参考建议，实际操作需要结合自身情况判断。"""
        
        # 如果有上下文数据，添加到提示词中
        if context:
            score = context.get('score', {})
            market = context.get('market', {})
            gold = market.get('gold', {})
            
            context_info = f"""
【当前市场背景】
- 黄金价格: {gold.get('price', 'N/A')} 美元/盎司
- GH评分: {score.get('total_score', 50)}/100
- 趋势: {score.get('trend', 'neutral')}
"""
            prompt = context_info + "\n【用户问题】\n" + user_question
        else:
            prompt = user_question
        
        response_text = self._call_qwen_api(prompt, system_prompt)
        
        if response_text:
            return {
                "success": True,
                "response": response_text,
                "model": self.model
            }
        else:
            return {
                "success": False,
                "error": "AI回复失败，请稍后重试"
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
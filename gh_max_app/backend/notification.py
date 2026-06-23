"""
推送通知模块
支持桌面通知和移动推送
"""

import threading
from datetime import datetime
from typing import Dict, Optional
from plyer import notification
from config import PUSH_NOTIFICATIONS


class NotificationManager:
    """通知管理类"""

    def __init__(self):
        self.enabled = True
        self.last_price_alert = {}
        self.last_signal_alert = {}
        self.price_threshold = 10  # 价格变化超过10美元才提醒

    def send_notification(self, title: str, message: str, app_name: str = "GH-Max"):
        """发送系统通知"""
        if not self.enabled:
            return

        try:
            notification.notify(
                title=title,
                message=message,
                app_name=app_name,
                timeout=10
            )
        except Exception as e:
            print(f"发送通知失败: {e}")

    def check_price_alert(self, current_price: float, prev_price: float):
        """检查价格是否突破阈值"""
        if not PUSH_NOTIFICATIONS.get("price_alert", True):
            return

        if prev_price <= 0 or current_price <= 0:
            return

        change = abs(current_price - prev_price)

        # 检查是否超过阈值
        if change >= self.price_threshold:
            alert_key = f"{current_price:.0f}"
            if alert_key in self.last_price_alert:
                # 5分钟内不重复提醒
                if (datetime.now() - self.last_price_alert[alert_key]).seconds < 300:
                    return

            direction = "大涨" if current_price > prev_price else "大跌"
            self.send_notification(
                title=f"黄金价格{direction}提醒",
                message=f"当前价格: ${current_price:.2f}，较上次变化: ${change:.2f}"
            )
            self.last_price_alert[alert_key] = datetime.now()

    def check_signal_change(self, current_score: float, prev_score: float, trend: str):
        """检查信号是否变化"""
        if not PUSH_NOTIFICATIONS.get("signal_change", True):
            return

        if prev_score is None:
            return

        score_change = abs(current_score - prev_score)

        # 评分变化超过10分才提醒
        if score_change >= 10:
            self.send_notification(
                title="GH-Max评分重大变化",
                message=f"评分变化 {prev_score:.1f} → {current_score:.1f}，当前趋势: {trend}"
            )

    def check_divergence_alert(self, divergences: Dict):
        """检查背离信号"""
        if not PUSH_NOTIFICATIONS.get("divergence", True):
            return

        if divergences is None or not isinstance(divergences, dict):
            return

        for ind_name, div in divergences.items():
            if div is None or not isinstance(div, dict):
                continue
            div_type = div.get("type", "")
            if div_type != "无背离" and div_type != "数据不足":
                signal = div.get("signal", "")

                alert_key = f"{ind_name}_{div_type}"
                if alert_key in self.last_signal_alert:
                    if (datetime.now() - self.last_signal_alert[alert_key]).seconds < 600:
                        continue

                self.send_notification(
                    title=f"{ind_name.upper()}背离信号",
                    message=f"检测到{div_type}，信号: {signal}"
                )
                self.last_signal_alert[alert_key] = datetime.now()

    def check_news_alert(self, sentiment_score: float):
        """检查重要新闻情绪变化"""
        if not PUSH_NOTIFICATIONS.get("news_alert", True):
            return

        if sentiment_score >= 70:
            self.send_notification(
                title="市场情绪极度偏多",
                message=f"利多消息占主导，情绪评分: {sentiment_score:.1f}"
            )
        elif sentiment_score <= 30:
            self.send_notification(
                title="市场情绪极度偏空",
                message=f"利空消息占主导，情绪评分: {sentiment_score:.1f}"
            )

    def send_daily_report_ready(self):
        """发送每日报告就绪通知"""
        self.send_notification(
            title="GH-Max 每日分析报告已更新",
            message="点击查看今日黄金全维度研判分析"
        )

    def send_error_alert(self, error_type: str, message: str):
        """发送错误警报"""
        self.send_notification(
            title=f"GH-Max 错误提醒: {error_type}",
            message=message
        )


# 全局通知管理器
notification_manager = NotificationManager()


def async_notify(func):
    """异步通知装饰器"""
    def wrapper(*args, **kwargs):
        thread = threading.Thread(target=func, args=args, kwargs=kwargs)
        thread.daemon = True
        thread.start()
    return wrapper

"""
GH-Max Flask API服务
提供RESTful API接口
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime
import threading
import time
import schedule
import traceback
import signal
import sys
from config import DEBUG, HOST, PORT, REFRESH_INTERVALS, DEFAULT_REFRESH_INTERVAL, CACHE_CONFIG
from data_service import DataService
from technical_indicators import TechnicalIndicators
from scoring_model import GHScoreModel
from database import Database
from notification import notification_manager
from logging_service import logging_service
from daily_report import DailyReportGenerator
from ai_service import ai_service

app = Flask(__name__)
CORS(app)

# 初始化服务
data_service = DataService()
scoring_model = GHScoreModel()
db = Database()
report_generator = DailyReportGenerator()

# 当前状态
current_state = {
    "refresh_interval": DEFAULT_REFRESH_INTERVAL,
    "is_running": False,
    "last_update": None,
    "prev_score": None,
    "prev_price": None,
    "current_data": None
}

# 自动刷新控制
refresh_thread = None
stop_refresh = threading.Event()


def refresh_data():
    """刷新所有数据"""
    try:
        timestamp = datetime.now().strftime("%H:%M:%S")
        logging_service.info(f"正在刷新数据...", "refresh")

        # 1. 获取市场数据
        market_data = data_service.get_market_summary()
        if market_data is None:
            logging_service.error("市场数据获取失败", "refresh")
            return
        logging_service.debug(f"市场数据获取成功: {list(market_data.keys())}", "refresh")

        # 2. 获取K线数据和技术指标
        kline = data_service.get_gold_kline(period="4小时", limit=100)
        tech_data = TechnicalIndicators.calculate_all_indicators(kline) if kline is not None else {}
        logging_service.debug(f"技术指标计算完成: {list(tech_data.keys())}", "refresh")

        # 3. 获取宏观数据
        macro_data = data_service.get_macro_data() or {}
        logging_service.debug(f"宏观数据: {list(macro_data.keys())}", "refresh")

        # 4. 获取新闻并分析情绪
        news_list = data_service.crawl_jin10_news()
        news_sentiment = data_service.analyze_news_sentiment(news_list)
        logging_service.debug(f"新闻情绪分析完成: sentiment_score={news_sentiment.get('sentiment_score', 50)}", "refresh")

        # 5. 计算综合评分
        try:
            score_result = scoring_model.calculate_total_score(
                market_data, tech_data, macro_data, {}, news_sentiment
            )
            if score_result is None:
                logging_service.error("评分计算失败", "refresh")
                return
            logging_service.debug(f"评分计算成功: total_score={score_result.get('total_score')}", "refresh")
        except Exception as score_exc:
            logging_service.error(f"评分计算异常: {score_exc}", "refresh")
            traceback.print_exc()
            return

        # 合并数据
        result = {
            "market": market_data,
            "technical": tech_data,
            "macro": macro_data,
            "news_sentiment": news_sentiment,
            "score": score_result,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

        # 保存到数据库（带异常处理）
        try:
            if score_result.get("total_score") is not None and score_result.get("trend") is not None:
                db.save_market_data({**market_data, "total_score": score_result["total_score"], "trend": score_result["trend"]})
            db.save_score_data(score_result)
            if news_sentiment.get("news"):
                db.save_news(news_sentiment["news"])
        except Exception as db_exc:
            logging_service.warning(f"数据库保存失败: {db_exc}", "refresh")
        
        # 同时保存金十数据源的数据（用于图表对比）
        try:
            jinshi_result = get_jinshi_data_cached()
            if jinshi_result:
                jinshi_score = jinshi_result.get("score", {})
                jinshi_market = jinshi_result.get("market", {})
                if jinshi_score.get("total_score") is not None and jinshi_score.get("trend") is not None:
                    # 添加异常值过滤：国内黄金价格（AU9999）正常范围约900-980元/克
                    gold_price = jinshi_market.get("gold", {}).get("price", 0)
                    
                    import json, urllib.request, os; _p='d:\\workspace\\许阳这小子的诉求\\.dbg\\jinshi-price-display-error.env'; _u,_s='http://127.0.0.1:7777/event','jinshi-price-display-error'; exec("try:\n with open(_p) as f: c=f.read(); _u=next((l.split('=',1)[1] for l in c.split('\\n') if l.startswith('DEBUG_SERVER_URL=')),_u); _s=next((l.split('=',1)[1] for l in c.split('\\n') if l.startswith('DEBUG_SESSION_ID=')),_s)\nexcept: pass"); urllib.request.urlopen(urllib.request.Request(_u, data=json.dumps({"sessionId":_s,"runId":"pre","hypothesisId":"H4","location":"app.py:119","msg":"[DEBUG] 价格验证检查","data":{"gold_price":gold_price,"is_valid":gold_price<=0 or (gold_price>=900 and gold_price<=980)}}).encode(), headers={"Content-Type":"application/json"})).read()
                    
                    if gold_price > 0 and (gold_price < 900 or gold_price > 980):
                        logging_service.warning(f"检测到异常价格 {gold_price}元/克，跳过保存", "refresh")
                    else:
                        # 使用金十数据中的市场数据（已替换为上海黄金交易所价格）
                        db.save_market_data({
                            **jinshi_market,  # 使用金十数据中的市场数据（已包含上海金价）
                            "total_score": jinshi_score["total_score"],
                            "trend": jinshi_score["trend"],
                            "source": "jinshi"
                        })
                        logging_service.debug("金十数据已保存到market_data表", "refresh")
        except Exception as jinshi_exc:
            logging_service.warning(f"金十数据保存失败: {jinshi_exc}", "refresh")

        # 检查通知
        try:
            gold_price = market_data.get("gold", {}).get("price", 0) if market_data.get("gold") else 0
            if current_state["prev_price"] and current_state["prev_price"] > 0:
                notification_manager.check_price_alert(gold_price, current_state["prev_price"])

            if current_state["prev_score"] is not None and score_result.get("total_score") is not None:
                notification_manager.check_signal_change(
                    score_result["total_score"],
                    current_state["prev_score"],
                    score_result["trend"]
                )

            notification_manager.check_divergence_alert(tech_data.get("divergences", {}))
            notification_manager.check_news_alert(news_sentiment.get("sentiment_score", 50))
        except Exception as notify_exc:
            logging_service.warning(f"通知检查失败: {notify_exc}", "refresh")

        # 更新状态
        current_state["prev_score"] = score_result["total_score"]
        current_state["prev_price"] = gold_price
        current_state["last_update"] = datetime.now()
        current_state["current_data"] = result

        logging_service.info(f"数据刷新完成 | 评分: {score_result['total_score']} | 趋势: {score_result['trend']}", "refresh")

    except Exception as e:
        logging_service.error(f"数据刷新错误: {e}", "refresh")
        traceback.print_exc()
        notification_manager.send_error_alert("数据刷新", str(e))


def auto_refresh_loop():
    """自动刷新循环"""
    while not stop_refresh.is_set():
        try:
            interval_seconds = REFRESH_INTERVALS.get(current_state["refresh_interval"], 300)
            
            # 检查是否到刷新时间（带有锁定机制）
            current_time = datetime.now()
            if hasattr(auto_refresh_loop, 'last_run'):
                elapsed = (current_time - auto_refresh_loop.last_run).total_seconds()
                if elapsed >= interval_seconds:
                    # 添加双重检查避免重复执行
                    if not hasattr(auto_refresh_loop, 'is_running') or not auto_refresh_loop.is_running:
                        auto_refresh_loop.is_running = True
                        try:
                            refresh_data()
                        finally:
                            auto_refresh_loop.is_running = False
                        auto_refresh_loop.last_run = current_time
            else:
                auto_refresh_loop.last_run = current_time
                auto_refresh_loop.is_running = True
                try:
                    refresh_data()
                finally:
                    auto_refresh_loop.is_running = False
            
            # 精确睡眠到下一个刷新周期
            if hasattr(auto_refresh_loop, 'last_run'):
                elapsed = (datetime.now() - auto_refresh_loop.last_run).total_seconds()
                sleep_time = max(1, interval_seconds - elapsed)
                time.sleep(sleep_time)
            else:
                time.sleep(interval_seconds)
                
        except Exception as e:
            logging_service.error(f"自动刷新循环错误: {e}", "refresh")
            time.sleep(5)


# ==================== API路由 ====================

@app.route('/')
def index():
    """首页"""
    return jsonify({
        "name": "GH-Max API",
        "version": "1.0.0",
        "description": "现货黄金全域多维AI智能研判系统",
        "endpoints": [
            "/api/market - 获取市场数据",
            "/api/technical - 获取技术指标",
            "/api/score - 获取综合评分",
            "/api/news - 获取新闻",
            "/api/report - 获取每日分析报告",
            "/api/history - 获取历史数据",
            "/api/refresh - 手动刷新数据",
            "/api/settings - 获取/设置参数"
        ]
    })


@app.route('/api/market')
def get_market():
    """获取市场数据"""
    source = request.args.get('source', 'akshare')
    
    import json, urllib.request, os; _p='d:\\workspace\\许阳这小子的诉求\\.dbg\\jinshi-price-display-error.env'; _u,_s='http://127.0.0.1:7777/event','jinshi-price-display-error'; exec("try:\n with open(_p) as f: c=f.read(); _u=next((l.split('=',1)[1] for l in c.split('\\n') if l.startswith('DEBUG_SERVER_URL=')),_u); _s=next((l.split('=',1)[1] for l in c.split('\\n') if l.startswith('DEBUG_SESSION_ID=')),_s)\nexcept: pass"); urllib.request.urlopen(urllib.request.Request(_u, data=json.dumps({"sessionId":_s,"runId":"pre","hypothesisId":"H2","location":"app.py:224","msg":"[DEBUG] API请求来源: "+source,"data":{"source":source}}).encode(), headers={"Content-Type":"application/json"})).read()
    
    if source == 'jinshi':
        # 金十数据源 - 返回国内黄金价格（上海黄金交易所）
        market_data = data_service.get_market_summary() or {}
        shanghai_gold = data_service.get_shanghai_gold_price()
        if shanghai_gold and market_data.get("gold"):
            market_data["gold"] = {
                **market_data["gold"],
                **shanghai_gold
            }
        
        import json, urllib.request, os; _p='d:\\workspace\\许阳这小子的诉求\\.dbg\\jinshi-price-display-error.env'; _u,_s='http://127.0.0.1:7777/event','jinshi-price-display-error'; exec("try:\n with open(_p) as f: c=f.read(); _u=next((l.split('=',1)[1] for l in c.split('\\n') if l.startswith('DEBUG_SERVER_URL=')),_u); _s=next((l.split('=',1)[1] for l in c.split('\\n') if l.startswith('DEBUG_SESSION_ID=')),_s)\nexcept: pass"); urllib.request.urlopen(urllib.request.Request(_u, data=json.dumps({"sessionId":_s,"runId":"pre","hypothesisId":"H2","location":"app.py:237","msg":"[DEBUG] 金十API响应数据","data":{"gold_price":market_data.get("gold",{}).get("price",0),"gold_name":market_data.get("gold",{}).get("name","")}}).encode(), headers={"Content-Type":"application/json"})).read()
        
        return jsonify(market_data)
    
    # AkShare数据源 - 返回国际黄金价格（现货黄金 XAUUSD）
    # 实时获取数据，不使用缓存
    market_data = data_service.get_market_summary() or {}
    if market_data:
        return jsonify(market_data)
    else:
        if current_state["current_data"]:
            return jsonify(current_state["current_data"]["market"])
        else:
            refresh_data()
            return jsonify(current_state["current_data"]["market"] if current_state["current_data"] else {})


@app.route('/api/technical')
def get_technical():
    """获取技术指标"""
    if current_state["current_data"]:
        return jsonify(current_state["current_data"]["technical"])
    else:
        refresh_data()
        return jsonify(current_state["current_data"]["technical"] if current_state["current_data"] else {})


@app.route('/api/score')
def get_score():
    """获取综合评分"""
    if current_state["current_data"]:
        return jsonify(current_state["current_data"]["score"])
    else:
        refresh_data()
        return jsonify(current_state["current_data"]["score"] if current_state["current_data"] else {})


@app.route('/api/news')
def get_news():
    """获取新闻情绪分析"""
    if current_state["current_data"]:
        return jsonify(current_state["current_data"]["news_sentiment"])
    else:
        refresh_data()
        return jsonify(current_state["current_data"]["news_sentiment"] if current_state["current_data"] else {})


@app.route('/api/full')
def get_full_data():
    """获取完整数据（AkShare数据源）"""
    if not current_state["current_data"]:
        refresh_data()
    return jsonify(current_state["current_data"] if current_state["current_data"] else {})


# 金十数据缓存（内存缓存用于快速访问）
jinshi_cache = {
    "data": None,
    "timestamp": None,
    "expire_seconds": CACHE_CONFIG.get("jinshi_memory_expire_seconds", 30)  # 从配置文件读取缓存过期时间
}

def get_jinshi_data_cached():
    """获取缓存的金十数据（优先使用数据库持久化缓存）"""
    now = datetime.now()
    
    # 首先检查内存缓存
    if jinshi_cache["data"] is not None and jinshi_cache["timestamp"] is not None:
        elapsed = (now - jinshi_cache["timestamp"]).total_seconds()
        logging_service.debug(f"内存缓存检查 - 已过去 {elapsed:.2f} 秒，过期时间: {jinshi_cache['expire_seconds']} 秒", "jinshi")
        if elapsed < jinshi_cache["expire_seconds"]:
            logging_service.debug("使用金十数据内存缓存", "jinshi")
            return jinshi_cache["data"]
    
    # 其次检查数据库持久化缓存（24小时）
    db_cache = db.get_jinshi_cache()
    if db_cache:
        logging_service.debug("使用金十数据数据库缓存", "jinshi")
        db_cache["cached"] = True
        # 更新内存缓存
        jinshi_cache["data"] = db_cache
        jinshi_cache["timestamp"] = now
        return db_cache
    
    logging_service.debug("缓存失效或不存在，重新获取金十数据", "jinshi")
    # 缓存失效，重新获取
    try:
        # 获取金十新闻
        news_list = data_service.crawl_jin10_news()
        news_sentiment = data_service.analyze_news_sentiment(news_list)
        
        # 获取市场数据（黄金价格等）
        market_data = data_service.get_market_summary() or {}
        
        # 使用上海黄金交易所价格替换国际现货黄金价格（金十数据源使用国内金价）
        shanghai_gold = data_service.get_shanghai_gold_price()
        if shanghai_gold and market_data.get("gold"):
            market_data["gold"] = {
                **market_data["gold"],
                **shanghai_gold
            }
            logging_service.debug("已将金十数据的黄金价格替换为上海黄金交易所价格", "jinshi")
        
        # 获取技术指标
        kline = data_service.get_gold_kline(period="4小时", limit=100)
        tech_data = TechnicalIndicators.calculate_all_indicators(kline) if kline is not None else {}
        
        # 计算评分（使用金十新闻情绪）
        score_result = scoring_model.calculate_total_score(
            market_data, tech_data, {}, {}, news_sentiment
        ) or {}
        
        result = {
            "market": market_data,
            "technical": tech_data,
            "news_sentiment": news_sentiment,
            "score": score_result,
            "source": "jinshi",  # 标记数据源为金十
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "cached": False
        }
        
        # 更新内存缓存
        jinshi_cache["data"] = result
        jinshi_cache["timestamp"] = now
        
        # 保存到数据库持久化缓存（从配置文件读取过期时间）
        db.save_jinshi_cache(result, expire_hours=CACHE_CONFIG.get("jinshi_db_expire_hours", 0.083))
        
        # 保存市场数据到market_data表，标记为jinshi数据源
        try:
            if score_result.get("total_score") is not None and score_result.get("trend") is not None:
                # 添加异常值过滤：国内黄金价格（AU9999）正常范围约900-980元/克
                gold_price = market_data.get("gold", {}).get("price", 0)
                if gold_price > 0:
                    # 检查价格是否在合理范围内
                    if gold_price < 900 or gold_price > 980:
                        logging_service.warning(f"检测到异常价格 {gold_price}元/克，跳过保存", "jinshi")
                    else:
                        db.save_market_data({
                            **market_data, 
                            "total_score": score_result["total_score"], 
                            "trend": score_result["trend"],
                            "source": "jinshi"
                        })
                        logging_service.debug("金十数据已保存到market_data表", "jinshi")
                else:
                    db.save_market_data({
                        **market_data, 
                        "total_score": score_result["total_score"], 
                        "trend": score_result["trend"],
                        "source": "jinshi"
                    })
                    logging_service.debug("金十数据已保存到market_data表", "jinshi")
        except Exception as db_exc:
            logging_service.warning(f"金十数据保存到market_data表失败: {db_exc}", "jinshi")
        
        return result
    except Exception as e:
        logging_service.error(f"金十数据获取失败: {e}", "jinshi")
        # 如果缓存有数据，返回缓存数据
        if jinshi_cache["data"] is not None:
            jinshi_cache["data"]["cached"] = True
            return jinshi_cache["data"]
        return {"error": str(e)}


@app.route('/api/jinshi')
def get_jinshi_data():
    """获取金十数据源数据（带缓存）"""
    result = get_jinshi_data_cached()
    return jsonify(result)


@app.route('/api/report')
def get_daily_report():
    """获取每日分析报告"""
    format_type = request.args.get('format', 'json')
    
    if not current_state["current_data"]:
        refresh_data()
    
    if current_state["current_data"]:
        market_data = current_state["current_data"]["market"]
        score_data = current_state["current_data"]["score"]
        
        report = report_generator.generate_report(score_data, market_data)
        
        if format_type == 'text':
            text_report = report_generator.export_report_text(report)
            return text_report, 200, {'Content-Type': 'text/plain; charset=utf-8'}
        else:
            return jsonify(report)
    else:
        return jsonify({"error": "无法生成报告，数据不可用"})


@app.route('/api/refresh')
def manual_refresh():
    """手动刷新数据"""
    thread = threading.Thread(target=refresh_data)
    thread.start()
    return jsonify({
        "status": "refresh_started",
        "message": "数据刷新已开始"
    })


@app.route('/api/history')
def get_history():
    """获取历史数据"""
    days = request.args.get('days', 7, type=int)
    data_type = request.args.get('type', 'all')
    source = request.args.get('source', 'all')

    if data_type == 'market':
        # 始终返回一个列表格式
        if source == 'akshare':
            history_data = db.get_market_history_by_source(days, 'akshare')
            return jsonify(history_data if isinstance(history_data, list) else [])
        elif source == 'jinshi':
            history_data = db.get_market_history_by_source(days, 'jinshi')
            return jsonify(history_data if isinstance(history_data, list) else [])
        else:
            return jsonify({
                "akshare": db.get_market_history_by_source(days, 'akshare'),
                "jinshi": db.get_market_history_by_source(days, 'jinshi')
            })
    elif data_type == 'score':
        return jsonify(db.get_score_history(days))
    elif data_type == 'statistics':
        return jsonify({
            "score_stats": db.get_score_statistics(days),
            "trend_distribution": db.get_trend_distribution(days)
        })
    else:
        return jsonify({
            "market": {
                "akshare": db.get_market_history_by_source(days, 'akshare'),
                "jinshi": db.get_market_history_by_source(days, 'jinshi')
            },
            "score": db.get_score_history(days),
            "statistics": {
                "score_stats": db.get_score_statistics(days),
                "trend_distribution": db.get_trend_distribution(days)
            }
        })


@app.route('/api/settings')
def get_settings():
    """获取设置"""
    return jsonify({
        "refresh_interval": current_state["refresh_interval"],
        "refresh_intervals": list(REFRESH_INTERVALS.keys()),
        "is_running": current_state["is_running"],
        "last_update": current_state["last_update"].strftime("%Y-%m-%d %H:%M:%S") if current_state["last_update"] else None,
        "notifications": notification_manager.enabled
    })


@app.route('/api/settings', methods=['POST'])
def update_settings():
    """更新设置"""
    data = request.json

    if "refresh_interval" in data:
        if data["refresh_interval"] in REFRESH_INTERVALS:
            current_state["refresh_interval"] = data["refresh_interval"]
            db.save_setting("refresh_interval", data["refresh_interval"])

    if "notifications" in data:
        notification_manager.enabled = data["notifications"]
        db.save_setting("notifications", str(data["notifications"]))

    return jsonify({
        "status": "success",
        "settings": {
            "refresh_interval": current_state["refresh_interval"],
            "notifications": notification_manager.enabled
        }
    })


@app.route('/api/history', methods=['DELETE'])
def delete_history():
    """删除历史数据"""
    data = request.json or {}
    days = data.get("days")
    type = data.get("type", "all")  # all, market, score
    
    try:
        if days:
            # 按天数删除（删除days天之前的数据）
            if type == "market":
                deleted = db.delete_market_history(days)
                result = {"market_data_deleted": deleted, "score_history_deleted": 0}
                message = f"已删除 {deleted} 条{days}天之前的市场数据"
            elif type == "score":
                deleted = db.delete_score_history(days)
                result = {"market_data_deleted": 0, "score_history_deleted": deleted}
                message = f"已删除 {deleted} 条{days}天之前的评分数据"
            else:
                market_deleted = db.delete_market_history(days)
                score_deleted = db.delete_score_history(days)
                result = {"market_data_deleted": market_deleted, "score_history_deleted": score_deleted}
                message = f"已删除 {market_deleted} 条市场数据和 {score_deleted} 条评分数据（{days}天之前）"
        else:
            # 删除所有数据
            if type == "market":
                deleted = db.delete_market_history()
                result = {"market_data_deleted": deleted, "score_history_deleted": 0}
                message = f"已删除全部 {deleted} 条市场数据"
            elif type == "score":
                deleted = db.delete_score_history()
                result = {"market_data_deleted": 0, "score_history_deleted": deleted}
                message = f"已删除全部 {deleted} 条评分数据"
            else:
                result = db.delete_all_history()
                message = f"已删除全部 {result['market_data_deleted']} 条市场数据和 {result['score_history_deleted']} 条评分数据"
        
        return jsonify({
            "status": "success",
            "message": message,
            "deleted": result,
            "days": days,
            "type": type
        })
    except Exception as e:
        logging_service.error(f"删除历史数据失败: {e}", "api")
        return jsonify({
            "status": "error",
            "message": f"删除失败: {str(e)}"
        }), 500


@app.route('/api/status')
def get_status():
    """获取运行状态"""
    return jsonify({
        "is_running": current_state["is_running"],
        "refresh_interval": current_state["refresh_interval"],
        "last_update": current_state["last_update"].strftime("%Y-%m-%d %H:%M:%S") if current_state["last_update"] else None,
        "uptime": (datetime.now() - current_state["last_update"]).seconds if current_state["last_update"] else None
    })


# ==================== AI接口 ====================

@app.route('/api/ai/status')
def get_ai_status():
    """获取AI服务状态"""
    return jsonify(ai_service.get_status())


@app.route('/api/ai/config', methods=['GET'])
def get_ai_config():
    """获取AI配置"""
    return jsonify({
        "enabled": ai_service.enabled,
        "model": ai_service.model,
        "has_api_key": ai_service.api_key is not None and len(ai_service.api_key) > 0
    })


@app.route('/api/ai/config', methods=['POST'])
def update_ai_config():
    """更新AI配置"""
    data = request.json
    api_key = data.get('api_key', '')
    enabled = data.get('enabled', False)
    model = data.get('model', 'qwen-plus')
    
    success = ai_service.save_config(api_key, enabled, model)
    
    if success:
        return jsonify({
            "status": "success",
            "message": "AI配置已保存",
            "config": {
                "enabled": enabled,
                "model": model,
                "has_api_key": len(api_key) > 0
            }
        })
    else:
        return jsonify({
            "status": "error",
            "message": "AI配置保存失败"
        }), 500


@app.route('/api/ai/analyze')
def ai_analyze():
    """AI分析当前市场"""
    if not current_state["current_data"]:
        refresh_data()
    
    if not ai_service.is_available():
        return jsonify({
            "success": False,
            "error": "AI服务未启用或API Key未配置，请在设置中配置千问API Key"
        })
    
    market_data = current_state["current_data"].get("market", {})
    technical_data = current_state["current_data"].get("technical", {})
    score_data = current_state["current_data"].get("score", {})
    
    result = ai_service.analyze_market(market_data, technical_data, score_data)
    return jsonify(result)


@app.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    """AI对话接口"""
    data = request.json
    user_question = data.get('question', '')
    
    if not user_question:
        return jsonify({
            "success": False,
            "error": "请输入问题"
        })
    
    if not ai_service.is_available():
        return jsonify({
            "success": False,
            "error": "AI服务未启用或API Key未配置，请在设置中配置千问API Key"
        })
    
    if not current_state["current_data"]:
        try: refresh_data()
        except: pass
    context = None
    if current_state["current_data"]:
        market_data = current_state["current_data"].get("market", {})
        shanghai_gold = None
        try: shanghai_gold = data_service.get_shanghai_gold_price()
        except: pass
        if not shanghai_gold or not shanghai_gold.get("price"):
            try:
                jr = get_jinshi_data_cached()
                if jr:
                    jg = jr.get("market", {}).get("gold", {})
                    if jg.get("price"): shanghai_gold = jg
            except: pass
        context = {
            "market": market_data,
            "score": current_state["current_data"].get("score", {}),
            "technical": current_state["current_data"].get("technical", {}),
            "shanghai_gold": shanghai_gold or {}
        }
    result = ai_service.chat(user_question, context)
    return jsonify(result)


def graceful_shutdown(signal_num, frame):
    """优雅退出处理函数"""
    print("\n" + "=" * 60)
    print("    正在停止GH-Max服务...")
    print("=" * 60)
    
    # 停止自动刷新
    current_state["is_running"] = False
    stop_refresh.set()
    
    # 禁用通知
    notification_manager.enabled = False
    
    # 等待刷新线程结束
    if refresh_thread is not None and refresh_thread.is_alive():
        print("  等待刷新线程停止...")
        refresh_thread.join(timeout=5)
    
    # 关闭数据库连接
    db.close()
    
    print("  后台通知已禁用")
    print("  后台服务已停止")
    print("=" * 60)
    print("    GH-Max服务已安全退出")
    print("=" * 60)
    
    sys.exit(0)


# 注册信号处理
signal.signal(signal.SIGINT, graceful_shutdown)
signal.signal(signal.SIGTERM, graceful_shutdown)


@app.route('/api/shutdown', methods=['POST'])
def shutdown_server():
    """通过API请求停止服务"""
    print("\n收到服务停止请求")
    graceful_shutdown(None, None)
    return jsonify({
        "status": "success",
        "message": "服务已停止"
    })


# ==================== 主程序 ====================

def main():
    """启动服务"""
    print("=" * 60)
    print("    GH-Max V1.0 现货黄金全域多维AI智能研判系统")
    print("    正在启动服务...")
    print("=" * 60)

    # 加载设置
    saved_interval = db.get_setting("refresh_interval")
    if saved_interval and saved_interval in REFRESH_INTERVALS:
        current_state["refresh_interval"] = saved_interval
    
    # 加载通知设置
    saved_notifications = db.get_setting("notifications")
    if saved_notifications is not None:
        notification_manager.enabled = saved_notifications.lower() == "true"

    # 启动自动刷新线程
    global refresh_thread
    stop_refresh.clear()
    refresh_thread = threading.Thread(target=auto_refresh_loop, daemon=True)
    refresh_thread.start()
    current_state["is_running"] = True

    print(f"\n后端服务已启动!")
    print(f"API地址: http://localhost:{PORT}")
    print(f"刷新频率: {current_state['refresh_interval']}")
    print(f"\n按 Ctrl+C 停止服务")
    print("=" * 60)

    app.run(host=HOST, port=PORT, debug=DEBUG, threaded=True)


if __name__ == "__main__":
    main()

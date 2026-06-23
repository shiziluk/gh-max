"""
日志记录服务
用于详细追踪数据流程和错误
"""

import datetime
import os

class LoggingService:
    """日志服务类"""
    
    def __init__(self, log_dir="logs"):
        self.log_dir = log_dir
        self._ensure_log_dir()
    
    def _ensure_log_dir(self):
        """确保日志目录存在"""
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir)
    
    def _get_log_file(self):
        """获取日志文件名"""
        today = datetime.datetime.now().strftime("%Y-%m-%d")
        return os.path.join(self.log_dir, f"gh_max_{today}.log")
    
    def log(self, message, level="INFO", module="main"):
        """记录日志"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        log_entry = f"[{timestamp}] [{level}] [{module}] {message}\n"
        
        print(f"[{timestamp}] [{level}] [{module}] {message}")
        
        try:
            with open(self._get_log_file(), "a", encoding="utf-8") as f:
                f.write(log_entry)
        except Exception as e:
            print(f"写入日志失败: {e}")
    
    def info(self, message, module="main"):
        """记录信息日志"""
        self.log(message, "INFO", module)
    
    def warning(self, message, module="main"):
        """记录警告日志"""
        self.log(message, "WARNING", module)
    
    def error(self, message, module="main"):
        """记录错误日志"""
        self.log(message, "ERROR", module)
    
    def debug(self, message, module="main"):
        """记录调试日志"""
        self.log(message, "DEBUG", module)
    
    def log_data(self, data_name, data, module="main"):
        """记录数据内容"""
        if data is None:
            self.debug(f"{data_name} 为 None", module)
        elif isinstance(data, dict):
            keys = list(data.keys())
            self.debug(f"{data_name} 包含键: {keys}", module)
            # 检查是否有None值
            for key, value in data.items():
                if value is None:
                    self.warning(f"{data_name}['{key}'] 为 None", module)
        else:
            self.debug(f"{data_name} 类型: {type(data)}", module)

# 全局日志服务
logging_service = LoggingService()

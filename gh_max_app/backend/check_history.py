import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database import Database

db = Database()

# 获取金十数据历史记录
jinshi_data = db.get_market_history_by_source(1, 'jinshi')
print(f"金十数据历史记录: {len(jinshi_data)} 条")

if jinshi_data:
    print("\n最近10条记录:")
    for d in jinshi_data[:10]:
        price = d.get('gold_price', 'N/A')
        timestamp = d.get('timestamp', 'N/A')
        print(f"{timestamp}: {price}")

# 检查是否有异常值
prices = [d.get('gold_price', 0) for d in jinshi_data if d.get('gold_price')]
if prices:
    min_price = min(prices)
    max_price = max(prices)
    avg_price = sum(prices) / len(prices)
    print(f"\n价格统计:")
    print(f"最小: {min_price}")
    print(f"最大: {max_price}")
    print(f"平均: {avg_price:.2f}")
    print(f"波动范围: {(max_price - min_price):.2f}")

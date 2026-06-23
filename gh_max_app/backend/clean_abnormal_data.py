import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database import Database

db = Database()

# 获取金十数据历史记录
jinshi_data = db.get_market_history_by_source(100, 'jinshi')
print(f"总记录数: {len(jinshi_data)}")

# 找出异常数据（价格不在900-980范围）
abnormal_count = 0
for d in jinshi_data:
    price = d.get('gold_price', 0)
    if price > 0 and (price < 900 or price > 980):
        abnormal_count += 1
        print(f"异常记录: {d['timestamp']} - {price}元/克")

print(f"\n异常记录总数: {abnormal_count}")

# 删除异常记录
if abnormal_count > 0:
    print("\n正在删除异常记录...")
    deleted = 0
    for d in jinshi_data:
        price = d.get('gold_price', 0)
        if price > 0 and (price < 900 or price > 980):
            db.delete_market_data(d['id'])
            deleted += 1
    print(f"已删除 {deleted} 条异常记录")

print("清理完成！")

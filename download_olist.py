import os
import sqlite3
import pandas as pd

# 1. 定义数据库名称
db_name = "olist.db"

# 连接到 SQLite 数据库
conn = sqlite3.connect(db_name)

# 2. 获取当前目录下所有的 CSV 文件
csv_files = [f for f in os.listdir('.') if f.endswith('.csv')]

print(f"开始导入 {len(csv_files)} 个文件...")

# 3. 循环读取并导入
for file in csv_files:
    # 统一清洗表名：
    # 1. 去掉 .csv 后缀
    # 2. 去掉 olist_ 前缀
    # 3. 去掉 _dataset 后缀
    table_name = file.replace('.csv', '').replace('olist_', '').replace('_dataset', '')
    
    # 特殊处理翻译表，让它更简短
    if table_name == "product_category_name_translation":
        table_name = "category_translation"
        
    print(f"正在导入: {file} -> 数据库表名: {table_name}")
    
    try:
        df = pd.read_csv(file)
        # 写入数据库
        df.to_sql(table_name, conn, if_exists='replace', index=False)
        print(f"  [成功] 导入了 {len(df)} 行数据。")
    except Exception as e:
        print(f"  [失败] 导入 {file} 出错: {e}")

conn.close()
print("\n数据导入全部完成！")
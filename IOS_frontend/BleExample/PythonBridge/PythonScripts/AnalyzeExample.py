#
//  AnalyzeExample.py
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/8.
//


import json
import numpy as np
from datetime import datetime

def analyze_live_data(json_data):
    """
    实时分析传感器数据
    """
    try:
        data = json.loads(json_data)
        sensor_data = data.get('sensor_data', {})
        
        # 提取数值数据
        acc_x = float(sensor_data.get('acc_x', 0))
        acc_y = float(sensor_data.get('acc_y', 0))
        acc_z = float(sensor_data.get('acc_z', 0))
        
        gyro_x = float(sensor_data.get('gyro_x', 0))
        gyro_y = float(sensor_data.get('gyro_y', 0))
        gyro_z = float(sensor_data.get('gyro_z', 0))
        
        # 示例分析1：计算合加速度
        acceleration_magnitude = np.sqrt(acc_x**2 + acc_y**2 + acc_z**2)
        
        # 示例分析2：简单运动状态判断
        motion_state = "静止"
        if acceleration_magnitude > 1.2:
            motion_state = "移动中"
        
        # 示例分析3：角度变化率（简化的姿态变化检测）
        angle_x = float(sensor_data.get('angle_x', 0))
        angle_change_rate = abs(gyro_x) + abs(gyro_y) + abs(gyro_z)
        
        # 返回分析结果
        result = {
            "success": True,
            "timestamp": sensor_data.get('timestamp', ''),
            "acceleration_magnitude": round(acceleration_magnitude, 3),
            "motion_state": motion_state,
            "angle_change_rate": round(angle_change_rate, 3),
            "is_moving": acceleration_magnitude > 1.0,
            "analysis_time": datetime.now().isoformat()
        }
        
        return result
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

def analyze_csv_file(file_path):
    """
    分析已保存的CSV文件
    """
    try:
        import pandas as pd
        # 这里可以添加更复杂的数据分析逻辑
        df = pd.read_csv(file_path)
        
        # 示例：计算统计数据
        stats = {
            "total_records": len(df),
            "avg_acc_x": df['AX'].mean() if 'AX' in df.columns else 0,
            "avg_acc_y": df['AY'].mean() if 'AY' in df.columns else 0,
            "avg_acc_z": df['AZ'].mean() if 'AZ' in df.columns else 0,
            "analysis_summary": "数据分析完成"
        }
        
        return {
            "success": True,
            "file_analysis": stats
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

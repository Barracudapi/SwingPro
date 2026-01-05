import numpy as np
import json
import math
from datetime import datetime
from typing import Dict, List, Any
import io
import sys
from logger import setup_logger

# 创建日志器
logger = setup_logger('tennis_analyzer')

class TennisStrokeAnalyzer:
    """网球击球检测分析器"""
    
    def __init__(self):
        self.version = "1.0.0"
    
    def analyze_stroke_from_csv_content(self, csv_content: str, threshold: float = 300.0, 
                                       slice_len: int = 200, plot: bool = False) -> Dict[str, Any]:
        """
        从CSV文本内容分析网球击球
        
        参数:
            csv_content: CSV格式的文本内容
            threshold: 击球检测阈值 (默认300)
            slice_len: 击球窗口长度 (默认200个数据点)
            plot: 是否生成图表 (在服务器中通常设为False)
        
        返回:
            分析结果字典
        """
        start_time = datetime.now()
        
        try:
            # 1. 从CSV文本加载数据
            acc_data, gyro_data = self._load_csv_from_string(csv_content)
            
            if len(acc_data) == 0:
                return {
                    "success": False,
                    "error": "CSV中没有有效数据",
                    "timestamp": datetime.now().isoformat()
                }
            
            logger.info(f"📊 加载数据: {len(acc_data)} 个数据点")
            
            # 2. 检测击球时间戳
            timestamps = self._detect_stroke_timestamps(gyro_data, acc_data, threshold)
            logger.info(f"🎾 原始检测到 {len(timestamps)} 个击球点")
            
            # 3. 过滤时间戳（避免重复）
            filtered_timestamps = self._filter_timestamps(timestamps, min_gap=75)
            logger.info(f"🎾 过滤后剩余 {len(filtered_timestamps)} 个击球点")
            
            # 4. 提取击球窗口切片
            acc_slices, gyro_slices = self._extract_stroke_slices(
                acc_data, gyro_data, filtered_timestamps, slice_len, plot
            )
            
            # 5. 分析每个击球的特征，TODO：后面要改成类别/其他分析
            stroke_analysis = self._analyze_strokes(acc_slices, gyro_slices)
            
            # TODO: 存储击球片段，以便其他分析

            # 计算处理时间
            processing_time = (datetime.now() - start_time).total_seconds() * 1000
            
            return {
                "success": True,
                "message": "网球击球分析完成",
                "data": {
                    "strokes_detected": len(filtered_timestamps),
                    "timestamps": filtered_timestamps,
                    "stroke_analysis": stroke_analysis,
                    "statistics": {
                        "total_data_points": len(acc_data),
                        "stroke_rate": f"{len(filtered_timestamps)} strokes",
                        "data_duration_seconds": len(acc_data) / 5.0,  # 假设5Hz采样率
                        "average_interval": self._calculate_average_interval(filtered_timestamps)
                    }
                },
                "analysis_info": {
                    "method": "tennis_stroke_detection",
                    "threshold_used": threshold,
                    "window_size": slice_len,
                    "processing_time_ms": round(processing_time, 2),
                    "version": self.version
                },
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.info(f"❌ 击球分析错误: {str(e)}")
            return {
                "success": False,
                "error": f"击球分析失败: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    def _load_csv_from_string(self, csv_content: str):
        """从字符串加载CSV数据 - 适配你的CSV格式"""
        lines = csv_content.strip().split('\n')
        
        logger.info(f"📖 解析CSV内容，总行数: {len(lines)}")
        
        if len(lines) <= 1:
            logger.warning("⚠️  CSV数据不足（只有表头或无数据）")
            return np.array([]), np.array([])
        
        # 显示表头信息用于调试
        header = lines[0]
        logger.info(f"📋 CSV表头: {header}")
        
        # 解析表头，找出各列的位置
        headers = [h.strip() for h in header.split(',')]
        logger.info(f"📋 解析到的列名: {headers}")
        logger.info(f"📋 列数量: {len(headers)}")
        
        # 找出关键列的位置
        column_mapping = {}
        expected_columns = ['AX', 'AY', 'AZ', 'GX', 'GY', 'GZ']
        
        for i, col in enumerate(headers):
            col_upper = col.upper()
            for expected in expected_columns:
                if expected in col_upper or col_upper in expected:
                    column_mapping[expected] = i
                    logger.info(f"🔍 找到列 '{col}' -> {expected} (索引: {i})")
        
        logger.info(f"📊 列映射结果: {column_mapping}")
        
        # 检查必要的列是否存在
        required_cols = ['AX', 'AY', 'AZ', 'GX', 'GY', 'GZ']
        missing_cols = [col for col in required_cols if col not in column_mapping]
        
        if missing_cols:
            logger.error(f"❌ 缺少必要的列: {missing_cols}")
            logger.error(f"❌ 找到的列: {list(column_mapping.keys())}")
            return np.array([]), np.array([])
        
        # 跳过表头，开始解析数据行
        data_lines = lines[1:] if len(lines) > 1 else []
        logger.info(f"📊 开始解析 {len(data_lines)} 行数据...")
        
        acc_data = []
        gyro_data = []
        error_count = 0
        success_count = 0
        
        # 解析前几行数据用于调试
        sample_data_shown = 0
        for line_num, line in enumerate(data_lines[:5], 1):  # 只显示前5行
            if line.strip():
                values = line.split(',')
                logger.info(f"🔍 第{line_num}行示例: {values[:10]}...")  # 显示前10个值
        
        # 解析所有数据行
        for line_num, line in enumerate(data_lines, 1):
            if not line.strip():
                continue
                
            try:
                # 分割CSV行
                values = [v.strip() for v in line.split(',')]
                
                # 提取加速度数据
                acc_x_idx = column_mapping['AX']
                acc_y_idx = column_mapping['AY']
                acc_z_idx = column_mapping['AZ']
                
                # 提取陀螺仪数据
                gyro_x_idx = column_mapping['GX']
                gyro_y_idx = column_mapping['GY']
                gyro_z_idx = column_mapping['GZ']
                
                # 解析数值
                acc_x = float(values[acc_x_idx]) if acc_x_idx < len(values) else 0.0
                acc_y = float(values[acc_y_idx]) if acc_y_idx < len(values) else 0.0
                acc_z = float(values[acc_z_idx]) if acc_z_idx < len(values) else 0.0
                
                gyro_x = float(values[gyro_x_idx]) if gyro_x_idx < len(values) else 0.0
                gyro_y = float(values[gyro_y_idx]) if gyro_y_idx < len(values) else 0.0
                gyro_z = float(values[gyro_z_idx]) if gyro_z_idx < len(values) else 0.0
                
                acc_data.append([acc_x, acc_y, acc_z])
                gyro_data.append([gyro_x, gyro_y, gyro_z])
                success_count += 1
                
                # 显示前几行数据值用于调试
                if success_count <= 3:
                    logger.info(f"✅ 第{line_num}行数据: "
                            f"acc=[{acc_x:.2f}, {acc_y:.2f}, {acc_z:.2f}], "
                            f"gyro=[{gyro_x:.2f}, {gyro_y:.2f}, {gyro_z:.2f}]")
                    
            except (ValueError, IndexError) as e:
                error_count += 1
                if error_count <= 3:  # 只显示前3个错误
                    logger.warning(f"⚠️  第{line_num}行解析失败: {e}, 数据: {line[:50]}...")
                continue
        
        logger.info(f"📊 解析完成: 成功 {success_count} 行, 失败 {error_count} 行")
        
        if success_count == 0:
            logger.error("❌ 没有成功解析任何数据行")
        
        return np.array(acc_data, float), np.array(gyro_data, float)
    
    def _detect_stroke_timestamps(self, gyro, acc, threshold=300.0):
        """检测击球时间戳"""
        gyro = np.array(gyro, float)
        acc = np.array(acc, float)
        
        # 计算角速度变化
        gyro_diff = np.abs(np.diff(gyro, axis=0))
        
        # 符号变化检测
        gyro_sign_change = np.diff(np.sign(gyro), axis=0)
        acc_sign_change = np.diff(np.sign(acc), axis=0)
        
        stroke_indices = []
        
        for i in range(len(gyro_diff)):
            # 检查是否有角速度超过阈值
            if np.any(gyro_diff[i] > threshold):
                # 检查前后窗口内的符号变化
                start = max(0, i - 3)
                end = min(len(gyro_sign_change), i + 3)
                
                has_change = (
                    np.any(np.abs(gyro_sign_change[start:end]) > 0) and
                    np.any(np.abs(acc_sign_change[start:end]) > 0)
                )
                
                if has_change:
                    stroke_indices.append(i + 1)  # +1因为diff减少了索引
        
        return stroke_indices
    
    def _filter_timestamps(self, timestamps, min_gap=75):
        """过滤时间戳，避免重复检测"""
        if not timestamps:
            return []
        
        filtered = [timestamps[0]]
        for i in range(1, len(timestamps)):
            if timestamps[i] - timestamps[i - 1] >= min_gap:
                filtered.append(timestamps[i])
        
        return filtered
    
    def _extract_stroke_slices(self, acc, gyro, timestamps, window_size=200, plot=False):
        """提取击球窗口切片"""
        acc_slices = []
        gyro_slices = []
        half = window_size // 2
        
        for t in timestamps:
            start = max(t - half, 0)
            end = min(t + half, len(acc))
            
            # 确保窗口大小一致
            if end - start == window_size:
                acc_slice = acc[start:end]
                gyro_slice = gyro[start:end]
                
                acc_slices.append(acc_slice.tolist())  # 转换为列表便于JSON序列化
                gyro_slices.append(gyro_slice.tolist())
        
        return acc_slices, gyro_slices
    
    def _analyze_strokes(self, acc_slices, gyro_slices):
        """分析每个击球的特征"""
        if not acc_slices:
            return []
        
        stroke_analysis = []
        
        for i, (acc_slice, gyro_slice) in enumerate(zip(acc_slices, gyro_slices)):
            acc_array = np.array(acc_slice)
            gyro_array = np.array(gyro_slice)
            
            # 计算基本特征
            acc_magnitude = np.sqrt(np.sum(acc_array**2, axis=1))
            gyro_magnitude = np.sqrt(np.sum(gyro_array**2, axis=1))
            
            stroke_features = {
                "stroke_id": i + 1,
                "peak_acceleration": float(np.max(acc_magnitude)),
                "peak_rotation": float(np.max(gyro_magnitude)),
                "avg_acceleration": float(np.mean(acc_magnitude)),
                "avg_rotation": float(np.mean(gyro_magnitude)),
                "stroke_power": float(np.max(acc_magnitude) * np.max(gyro_magnitude)),
                "duration_points": len(acc_slice)
            }
            
            # 判断击球类型（简化版）
            stroke_type = self._classify_stroke_type(stroke_features)
            stroke_features["estimated_type"] = stroke_type
            
            stroke_analysis.append(stroke_features)
        
        return stroke_analysis
    
    def _classify_stroke_type(self, features):
        """根据特征判断击球类型"""
        peak_acc = features["peak_acceleration"]
        peak_rot = features["peak_rotation"]
        
        if peak_acc < 2.0 and peak_rot < 200:
            return "轻击/短球"
        elif peak_acc < 5.0 and peak_rot < 500:
            return "正常击球"
        elif peak_acc < 8.0:
            return "强力击球"
        else:
            return "非常强力击球"
    
    def _calculate_average_interval(self, timestamps):
        """计算平均击球间隔"""
        if len(timestamps) < 2:
            return "N/A"
        
        intervals = [timestamps[i] - timestamps[i-1] for i in range(1, len(timestamps))]
        avg_interval = np.mean(intervals)
        
        # 转换为秒（假设5Hz采样率）
        avg_seconds = avg_interval / 5.0
        return f"{avg_seconds:.1f}秒"
    
    def process_single_imu_csv(self, csv_path, threshold=300, slice_len=200, plot=False):
        """
        兼容原函数的接口（从文件路径读取）
        """
        with open(csv_path, mode="r", newline="", encoding="utf-8") as f:
            csv_content = f.read()
        
        return self.analyze_stroke_from_csv_content(csv_content, threshold, slice_len, plot)

# 单例实例
_stroke_analyzer = TennisStrokeAnalyzer()

# 简化调用接口
def analyze_tennis_strokes(csv_content: str, threshold: float = 300.0, 
                          slice_len: int = 200, plot: bool = False) -> Dict[str, Any]:
    """
    网球击球分析主函数
    """
    return _stroke_analyzer.analyze_stroke_from_csv_content(csv_content, threshold, slice_len, plot)

# 测试函数
if __name__ == "__main__":
    # 创建测试CSV数据
    test_csv = """Timestamp,DeviceName,Mac,AX,AY,AZ,GX,GY,GZ,AngX,AngY,AngZ,HX,HY,HZ,Electric,Temp
2024-01-01 10:00:00.000,Device1,AA:BB:CC:DD:EE:FF,0.1,0.2,0.9,10.2,8.3,5.1,5.2,3.1,12.5,0,0,0,100,25
2024-01-01 10:00:00.200,Device1,AA:BB:CC:DD:EE:FF,0.2,0.1,0.8,15.1,9.2,6.3,5.3,3.2,12.6,0,0,0,100,25
2024-01-01 10:00:00.400,Device1,AA:BB:CC:DD:EE:FF,0.3,0.3,1.2,350.5,280.3,310.2,5.1,3.0,12.4,0,0,0,100,25
2024-01-01 10:00:00.600,Device1,AA:BB:CC:DD:EE:FF,0.4,0.2,1.1,320.1,290.4,305.8,5.4,3.3,12.7,0,0,0,100,25
2024-01-01 10:00:00.800,Device1,AA:BB:CC:DD:EE:FF,0.2,0.3,0.9,20.3,15.2,12.1,5.0,2.9,12.3,0,0,0,100,25"""
    
    result = analyze_tennis_strokes(test_csv, threshold=300, plot=False)
    logger.info("🎾 网球击球分析测试结果:")
    logger.info(json.dumps(result, indent=2, ensure_ascii=False))
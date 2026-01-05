# app.py - 极简版本，确保能快速运行
from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import math
import sys
import os
import json
import uuid
import logging

# 获取当前文件所在目录
current_dir = os.path.dirname(os.path.abspath(__file__))

# 创建数据存储目录（临时方案，后续考虑数据库）
UPLOAD_FOLDER = 'sensor_data_uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# 添加analyzers目录到Python路径
analyzers_dir = os.path.join(current_dir, 'analyzers')
if analyzers_dir not in sys.path:
    sys.path.insert(0, analyzers_dir)  # 插入到最前面
    print(f"✅ 添加分析模块路径: {analyzers_dir}")

# 打印调试信息
print(f"📁 当前工作目录: {os.getcwd()}")
print(f"📁 当前文件目录: {current_dir}")
print(f"📁 analyzers目录: {analyzers_dir}")
print(f"📁 目录存在: {os.path.exists(analyzers_dir)}")

if os.path.exists(analyzers_dir):
    print("📂 analyzers内容:")
    for item in os.listdir(analyzers_dir):
        print(f"   - {item}")

app = Flask(__name__)
CORS(app)  # 允许所有跨域请求，方便调试

@app.route('/')
def home():
    return "传感器分析服务器已启动！"

@app.route('/recordings', methods=['GET'])
def recordings_dashboard():
    """
    录制数据管理 Web 界面
    """
    try:
        recordings = []
        
        for filename in os.listdir(UPLOAD_FOLDER):
            if filename.endswith('.json') and '_analysis' not in filename:
                filepath = os.path.join(UPLOAD_FOLDER, filename)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    metadata = data.get('metadata', {})
                    recordings.append({
                        "id": metadata.get('session_id', 'unknown'),
                        "device": metadata.get('device_name', 'unknown'),
                        "duration": metadata.get('recording_duration', 0),
                        "points": metadata.get('data_points', 0),
                        "time": metadata.get('upload_timestamp', ''),
                        "size": metadata.get('file_size', 0)
                    })
                except:
                    continue
        
        # 生成HTML页面
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>录制数据管理</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
                tr:hover { background-color: #f5f5f5; }
                .success { color: green; }
                .error { color: red; }
            </style>
        </head>
        <body>
            <h1>录制数据管理</h1>
            <p>存储路径: <code>{}</code></p>
            <p>总计: {} 个录制</p>
            
            <table>
                <tr>
                    <th>ID</th>
                    <th>设备</th>
                    <th>时长</th>
                    <th>数据点</th>
                    <th>时间</th>
                    <th>大小</th>
                    <th>操作</th>
                </tr>
        """.format(UPLOAD_FOLDER, len(recordings))
        
        for rec in recordings:
            html += f"""
                <tr>
                    <td><code>{rec['id']}</code></td>
                    <td>{rec['device']}</td>
                    <td>{rec['duration']:.1f}秒</td>
                    <td>{rec['points']}</td>
                    <td>{rec['time']}</td>
                    <td>{rec['size']:,} 字符</td>
                    <td>
                        <a href="/api/recordings/{rec['id']}" target="_blank">查看详情</a>
                    </td>
                </tr>
            """
        
        html += """
            </table>
            <br>
            <a href="/">返回首页</a>
        </body>
        </html>
        """
        
        return html
        
    except Exception as e:
        return f"<h1>错误</h1><p>{str(e)}</p>", 500

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "running",
        "service": "sensor-analysis",
        "timestamp": datetime.now().isoformat(),
        "message": "服务器正常运行"
    })

@app.route('/api/analyze/simple', methods=['POST'])
def analyze_simple():
    """
    最简单的分析接口，测试用
    """
    try:
        data = request.json
        print(f"收到数据: {data}")
        
        # 提取加速度数据
        sensor_data = data.get('sensor_data', {})
        
        acc_x = float(sensor_data.get('acc_x', 0))
        acc_y = float(sensor_data.get('acc_y', 0))
        acc_z = float(sensor_data.get('acc_z', 0))
        
        # 计算合加速度
        magnitude = math.sqrt(acc_x**2 + acc_y**2 + acc_z**2)
        
        # 判断状态
        if magnitude < 1.0:
            state = "静止"
        elif magnitude <3.0:
            state = "行走"
        else:
            state = "剧烈运动"
        
        return jsonify({
            "success": True,
            "message": "分析成功",
            "data": {
                "acceleration_magnitude": round(magnitude, 4),
                "motion_state": state,
                "raw_values": {"acc_x": acc_x, "acc_y": acc_y, "acc_z": acc_z}
            },
            "server_info": {
                "host": "localhost",
                "python_version": "3.x",
                "endpoint": "simple"
            },
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 400

@app.route('/api/analyze/advanced', methods=['POST'])
def analyze_advanced():
    """
    更复杂的分析（可选）
    """
    try:
        data = request.json
        
        # 这里可以添加更复杂的分析逻辑
        # 比如使用numpy进行FFT分析等
        
        return jsonify({
            "success": True,
            "message": "高级分析功能",
            "features": ["频谱分析", "模式识别", "趋势预测"],
            "status": "开发中",
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 400
    
@app.route('/api/analyze/tennis', methods=['POST'])
def analyze_tennis():
    """
    网球击球分析接口
    接收CSV格式的网球训练数据进行击球检测
    """
    try:
        data = request.json
        print(f"🎾 收到请求，数据键: {list(data.keys()) if data else '无数据'}")
        
        if not data or 'csv_content' not in data:
            return jsonify({
                "success": False,
                "error": "未提供CSV内容",
                "timestamp": datetime.now().isoformat()
            }), 400
        
        csv_content = data['csv_content']
        print(f"🎾 CSV内容长度: {len(csv_content)} 字符")
        print(f"🎾 CSV前100字符: {csv_content[:100]}")
        
        # 获取可选参数
        threshold = float(data.get('threshold', 300.0))
        slice_len = int(data.get('slice_len', 200))
        
        print(f"🎾 使用参数: threshold={threshold}, slice_len={slice_len}")
        
        # 尝试导入和分析
        try:
            # 动态导入，提供更多调试信息
            module_path = os.path.join(analyzers_dir, 'tennis_stroke_analyzer.py')
            print(f"📂 尝试导入模块: {module_path}")
            print(f"📂 模块文件存在: {os.path.exists(module_path)}")
            
            # 清除可能的缓存
            import importlib
            if 'tennis_stroke_analyzer' in sys.modules:
                del sys.modules['tennis_stroke_analyzer']
            
            # 尝试导入
            from tennis_stroke_analyzer import analyze_tennis_strokes
            print("✅ 成功导入网球分析模块")
            
            # 进行分析
            print("🎾 开始分析数据...")
            result = analyze_tennis_strokes(
                csv_content, 
                threshold=threshold, 
                slice_len=slice_len, 
                plot=False
            )
            
            print(f"🎾 分析完成，结果: {result.get('success', False)}")
            print(f"🎾 检测到击球数: {len(result.get('strokes', []))}")
            
            return jsonify(result)
            
        except ImportError as ie:
            print(f"❌ 导入错误: {str(ie)}")
            print(f"📁 当前sys.path:")
            for p in sys.path:
                print(f"   - {p}")
            return jsonify({
                "success": False,
                "error": f"网球击球分析模块导入失败: {str(ie)}",
                "timestamp": datetime.now().isoformat()
            }), 500
        except Exception as module_error:
            print(f"❌ 模块执行错误: {str(module_error)}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False,
                "error": f"网球击球分析执行失败: {str(module_error)}",
                "timestamp": datetime.now().isoformat()
            }), 500
            
    except Exception as e:
        print(f"❌ 接口处理错误: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "success": False,
            "error": f"请求处理失败: {str(e)}",
            "timestamp": datetime.now().isoformat()
        }), 500
    
@app.route('/api/recordings/upload', methods=['POST'])
def upload_recording():
    """
    接收并存储录制数据接口
    自动触发网球分析
    """
    try:
        data = request.json
        print(f"📤 收到录制数据上传请求")
        print(f"   设备: {data.get('device_name', '未知')}")
        print(f"   MAC: {data.get('device_mac', '未知')}")
        print(f"   录制时长: {data.get('recording_duration', 0)}秒")
        
        if not data or 'csv_content' not in data:
            return jsonify({
                "success": False,
                "error": "未提供CSV数据",
                "timestamp": datetime.now().isoformat()
            }), 400
        
        # 生成唯一ID和文件名
        session_id = str(uuid.uuid4())[:8]
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"session_{timestamp}_{session_id}"
        
        # 保存原始数据
        raw_data_path = os.path.join(UPLOAD_FOLDER, f"{filename}.json")
        csv_data_path = os.path.join(UPLOAD_FOLDER, f"{filename}.csv")
        
        # 保存JSON元数据
        metadata = {
            "session_id": session_id,
            "filename": filename,
            "device_name": data.get('device_name', 'unknown'),
            "device_mac": data.get('device_mac', 'unknown'),
            "recording_duration": data.get('recording_duration', 0),
            "data_points": data.get('data_points', 0),
            "upload_timestamp": datetime.now().isoformat(),
            "file_size": len(data.get('csv_content', ''))
        }
        
        with open(raw_data_path, 'w', encoding='utf-8') as f:
            json.dump({
                "metadata": metadata,
                "raw_data": data  # 包含所有原始数据
            }, f, indent=2, ensure_ascii=False)
        
        # 保存CSV数据
        csv_content = data['csv_content']
        with open(csv_data_path, 'w', encoding='utf-8') as f:
            f.write(csv_content)
        
        print(f"💾 数据已保存: {filename}")
        print(f"   - JSON: {raw_data_path}")
        print(f"   - CSV: {csv_data_path}")
        
        # 自动触发网球分析（异步处理）
        analysis_result = None
        try:
            # 调用现有的网球分析功能
            from tennis_stroke_analyzer import analyze_tennis_strokes
            analysis_result = analyze_tennis_strokes(
                csv_content,
                threshold=float(data.get('threshold', 300.0)),
                slice_len=int(data.get('slice_len', 200)),
                plot=False
            )
            
            # 保存分析结果
            analysis_path = os.path.join(UPLOAD_FOLDER, f"{filename}_analysis.json")
            with open(analysis_path, 'w', encoding='utf-8') as f:
                json.dump(analysis_result, f, indent=2, ensure_ascii=False)
            
            print(f"🎾 分析完成，结果已保存")
            
        except Exception as analysis_error:
            print(f"⚠️  分析过程中出错: {analysis_error}")
            analysis_result = {
                "success": False,
                "error": f"分析失败: {str(analysis_error)}",
                "note": "数据已保存，但分析失败"
            }
        
        # 准备响应
        response_data = {
            "success": True,
            "message": "录制数据接收成功",
            "session_id": session_id,
            "filename": filename,
            "metadata": metadata,
            "analysis": analysis_result,
            "files": {
                "raw_data": raw_data_path,
                "csv_data": csv_data_path,
                "analysis": analysis_path if analysis_result and analysis_result.get('success') else None
            },
            "timestamp": datetime.now().isoformat()
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        print(f"❌ 上传处理错误: {str(e)}")
        import traceback
        traceback.print_exc()
        
        return jsonify({
            "success": False,
            "error": f"上传处理失败: {str(e)}",
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/api/recordings/list', methods=['GET'])
def list_recordings():
    """
    列出所有录制的数据会话
    """
    try:
        recordings = []
        
        for filename in os.listdir(UPLOAD_FOLDER):
            if filename.endswith('.json') and '_analysis' not in filename:
                filepath = os.path.join(UPLOAD_FOLDER, filename)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        
                    recordings.append({
                        "filename": filename.replace('.json', ''),
                        "device": data.get('metadata', {}).get('device_name', 'unknown'),
                        "duration": data.get('metadata', {}).get('recording_duration', 0),
                        "data_points": data.get('metadata', {}).get('data_points', 0),
                        "timestamp": data.get('metadata', {}).get('upload_timestamp', ''),
                        "file_size": data.get('metadata', {}).get('file_size', 0)
                    })
                except:
                    continue
        
        # 按时间倒序排序
        recordings.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        
        return jsonify({
            "success": True,
            "recordings": recordings,
            "total": len(recordings),
            "storage_path": UPLOAD_FOLDER,
            "timestamp": datetime.now().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

@app.route('/api/recordings/<session_id>', methods=['GET'])
def get_recording(session_id):
    """
    获取特定录制会话的详细信息
    """
    try:
        # 查找匹配的文件
        for filename in os.listdir(UPLOAD_FOLDER):
            if session_id in filename:
                filepath = os.path.join(UPLOAD_FOLDER, filename)
                
                if filename.endswith('.json') and '_analysis' not in filename:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                    
                    # 查找对应的分析文件
                    analysis_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_analysis.json")
                    analysis_data = None
                    
                    if os.path.exists(analysis_path):
                        with open(analysis_path, 'r', encoding='utf-8') as f:
                            analysis_data = json.load(f)
                    
                    return jsonify({
                        "success": True,
                        "session_id": session_id,
                        "raw_data": data,
                        "analysis": analysis_data,
                        "timestamp": datetime.now().isoformat()
                    })
        
        return jsonify({
            "success": False,
            "error": f"未找到会话 {session_id}",
            "timestamp": datetime.now().isoformat()
        }), 404
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    # 启用详细日志
    logging.getLogger('werkzeug').setLevel(logging.DEBUG)

    print("=" * 50)
    print("传感器分析服务器启动中...")
    print("访问地址: http://localhost:5000")
    print("健康检查: http://localhost:5000/api/health")
    print("简单分析: POST http://localhost:5000/api/analyze/simple")
    print("=" * 50)
    
    # 运行服务器
    app.run(host='0.0.0.0', port=5000, debug=True)
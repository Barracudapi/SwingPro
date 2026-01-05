//
//  ServerAnalysisManager.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/8.
//


import Foundation
import Combine

class ServerAnalysisManager: ObservableObject {
    static let shared = ServerAnalysisManager()
    
    // 服务器配置 - 使用你的IP
    private let serverIP = "10.32.112.180"  // 顾心怡的电脑IP
    private let serverPort = 5000
    private var baseURL: String {
        return "http://\(serverIP):\(serverPort)/api"
    }
    
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0  // 10秒超时
        configuration.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - 测试服务器连接
    func testConnection(completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "\(baseURL)/health") else {
            completion(false, "URL无效")
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "连接失败: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "无效的服务器响应")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    completion(true, "✅ 服务器连接成功")
                } else {
                    completion(false, "❌ 服务器响应异常 (状态码: \(httpResponse.statusCode))")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - 分析传感器数据（主要方法）
    func analyzeSensorData(_ data: [String: Any],
                          completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/analyze/simple") else {
            let error = NSError(domain: "ServerAnalysis", code: 100,
                              userInfo: [NSLocalizedDescriptionKey: "无效的服务器URL"])
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpBody = jsonData
            
            print("📤 发送分析请求到服务器...")
            print("数据大小: \(jsonData.count) 字节")
            
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            // 处理响应
            if let error = error {
                print("❌ 网络请求失败: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "ServerAnalysis", code: 101,
                                  userInfo: [NSLocalizedDescriptionKey: "服务器未返回数据"])
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 打印原始响应（调试用）
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 服务器响应: \(responseString)")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success {
                    print("✅ 服务器分析成功")
                    DispatchQueue.main.async {
                        completion(.success(json ?? [:]))
                    }
                } else {
                    let errorMsg = json?["error"] as? String ?? "未知错误"
                    let error = NSError(domain: "ServerAnalysis", code: 102,
                                      userInfo: [NSLocalizedDescriptionKey: errorMsg])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
                
            } catch {
                print("❌ JSON解析失败: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - 离线分析（服务器不可用时）
    func analyzeOffline(_ data: [String: Any]) -> [String: Any] {
        print("⚠️ 使用离线分析（服务器不可用）")
        
        guard let sensorData = data["sensor_data"] as? [String: Any] else {
            return [
                "success": false,
                "error": "数据格式错误",
                "analysis_type": "offline_fallback"
            ]
        }
        
        let accX = Double(sensorData["acc_x"] as? String ?? "0") ?? 0
        let accY = Double(sensorData["acc_y"] as? String ?? "0") ?? 0
        let accZ = Double(sensorData["acc_z"] as? String ?? "0") ?? 0
        
        let magnitude = sqrt(accX * accX + accY * accY + accZ * accZ)
        
        let status: String
        if magnitude < 0.2 {
            status = "静止"
        } else if magnitude < 1.0 {
            status = "轻微移动"
        } else {
            status = "移动中"
        }
        
        return [
            "success": true,
            "acceleration_magnitude": magnitude,
            "motion_state": status,
            "analysis_type": "offline_swift",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "note": "离线分析结果（服务器不可用）"
        ]
    }
    
    // Stroke Detect for single IMU sensor
    func analyzeTennisStroke(csvContent: String,
                            threshold: Double = 300.0,
                            sliceLength: Int = 200,
                            completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        guard let url = URL(string: "\(baseURL)/analyze/tennis") else {
            completion(.failure(NSError(domain: "ServerAnalysis", code: 300,
                                      userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0  // 网球分析可能需要更多时间
        
        let requestData: [String: Any] = [
            "csv_content": csvContent,
            "threshold": threshold,
            "slice_len": sliceLength
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestData)
            request.httpBody = jsonData
            
            print("🎾 发送网球击球分析请求...")
            
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            // 处理响应...
            if let error = error {
                print("❌ 网球分析网络错误: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "TennisAnalysis", code: 301,
                                  userInfo: [NSLocalizedDescriptionKey: "无响应数据"])
                completion(.failure(error))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success {
                    print("✅ 网球击球分析成功")
                    completion(.success(json ?? [:]))
                } else {
                    let errorMsg = json?["error"] as? String ?? "未知错误"
                    let error = NSError(domain: "TennisAnalysis", code: 302,
                                      userInfo: [NSLocalizedDescriptionKey: errorMsg])
                    completion(.failure(error))
                }
                
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: 录制数据上传
    func uploadRecordingData(_ data: [String: Any],
                            completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        let urlString = "\(baseURL)/recordings/upload"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "ServerAnalysis", code: 400,
                              userInfo: [NSLocalizedDescriptionKey: "无效的URL"])
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpBody = jsonData
            
            print("📤 上传录制数据...")
            print("数据大小: \(jsonData.count) 字节")
            
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            // 处理响应...
            if let error = error {
                print("❌ 上传失败: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 打印HTTP响应状态
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 HTTP状态码: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ 无响应数据")
                let error = NSError(domain: "ServerAnalysis", code: 401,
                                  userInfo: [NSLocalizedDescriptionKey: "服务器未返回数据"])
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 打印原始响应字符串（调试用）
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 服务器原始响应:")
                print("\(responseString)")
                print("📥 响应结束")
            }
    
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success {
                    print("✅ 录制数据上传成功")
                    print("服务器返回结果详情:")
                    if let json = json {
                        for (key, value) in json {
                            print("   - \(key): \(value)")
                        }
                    }
                    DispatchQueue.main.async {
                        completion(.success(json ?? [:]))
                    }
                } else {
                    let errorMsg = json?["error"] as? String ?? "未知错误"
                    // 打印更多错误信息
                    if let json = json {
                        print("❌ 错误详情:")
                        for (key, value) in json {
                            print("   - \(key): \(value)")
                        }
                    }
                    let error = NSError(domain: "ServerAnalysis", code: 402,
                                      userInfo: [NSLocalizedDescriptionKey: errorMsg])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
}

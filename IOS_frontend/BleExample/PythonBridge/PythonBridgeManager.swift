//
//  PythonBridgeManager.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/8.
//


import Foundation
import PythonKit

class PythonBridgeManager {
    static let shared = PythonBridgeManager()
    
    private var isPythonReady = false
    private let sys = Python.import("sys")
    
    private init() {
        setupPythonEnvironment()
    }
    
    private func setupPythonEnvironment() {
        // 1. 添加Python脚本路径
        if let bundlePath = Bundle.main.resourcePath {
            let pythonScriptsPath = bundlePath + "/PythonScripts"
            sys.path.append(pythonScriptsPath)
            print("添加Python路径: \(pythonScriptsPath)")
        }
        
        // 2. 检查Python环境
        do {
            let python = try Python.attemptImport("python")
            print("Python版本: \(Python.version)")
            isPythonReady = true
        } catch {
            print("Python环境初始化失败: \(error)")
            isPythonReady = false
        }
    }
    
    func analyzeSensorData(_ data: [String: Any]) -> [String: Any]? {
        guard isPythonReady else {
            print("Python环境未就绪")
            return nil
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let analysisModule = try Python.attemptImport("AnalyzeExample")
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                
                let result = analysisModule.analyze_live_data(jsonString)
                
                // 极简方案：直接将Python对象转为字符串，然后解析JSON
                if let resultString = String(result) {
                    print("Python返回的字符串: \(resultString)")
                    
                    // 尝试解析为JSON
                    if let jsonData = resultString.data(using: .utf8),
                       let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        
                        print("成功解析JSON字典: \(jsonDict)")
                        
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PythonAnalysisCompleted"),
                                object: nil,
                                userInfo: jsonDict
                            )
                        }
                    }
                }
                
            } catch {
                print("Python分析失败: \(error)")
            }
        }
        
        return nil
    }
}


//
//  SensorAnalyzer.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/8.
//


import Foundation
import WitSDK

class SensorAnalyzer {
    static let shared = SensorAnalyzer()
    
    // 将设备数据转换为Python可分析的格式
    func prepareDataForAnalysis(device: Bwt901ble) -> [String: Any] {
        var dataDict: [String: Any] = [:]
        
        // 提取传感器数据
        let sensorData: [String: String] = [
            "acc_x": device.getDeviceData(WitSensorKey.AccX) ?? "0",
            "acc_y": device.getDeviceData(WitSensorKey.AccY) ?? "0",
            "acc_z": device.getDeviceData(WitSensorKey.AccZ) ?? "0",
            "gyro_x": device.getDeviceData(WitSensorKey.GyroX) ?? "0",
            "gyro_y": device.getDeviceData(WitSensorKey.GyroY) ?? "0",
            "gyro_z": device.getDeviceData(WitSensorKey.GyroZ) ?? "0",
            "angle_x": device.getDeviceData(WitSensorKey.AngleX) ?? "0",
            "angle_y": device.getDeviceData(WitSensorKey.AngleY) ?? "0",
            "angle_z": device.getDeviceData(WitSensorKey.AngleZ) ?? "0",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // 设备信息
        let deviceInfo: [String: String] = [
            "name": device.name ?? "Unknown",
            "mac": device.mac ?? "Unknown",
            "is_open": device.isOpen ? "true" : "false"
        ]
        
        dataDict["sensor_data"] = sensorData
        dataDict["device_info"] = deviceInfo
        
        return dataDict
    }
}

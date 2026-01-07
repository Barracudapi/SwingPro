//
//  BluetoothSenorManager.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI
import Combine
import CoreBluetooth
import WitSDK

// MARK: - Bluetooth Sensor Manager (替换原有的 SensorManager)

class BluetoothSensorManager: NSObject, ObservableObject {
    @Published var isConnected: Bool = false
    @Published var currentSpeed: Int = 0
    @Published var currentSwingType: String = "--"
    @Published var sessionSwings: Int = 0
    
    // 实时IMU数据
    @Published var imuData: IMUData = IMUData()
    @Published var deviceList: [Bwt901ble] = []
    
    // 录制相关属性
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordedDataCount: Int = 0
    
    // 扫描状态
    @Published var isScanning: Bool = false
    
    // WitSDK 蓝牙管理器
    private var bluetoothManager: WitBluetoothManager = WitBluetoothManager.instance
    
    private var serverManager = ServerAnalysisManager.shared

    // 当前连接的设备
    private var currentDevice: Bwt901ble?
    
    // 数据记录器
    private var dataRecorder = DataRecorder()
    
    // 录制开始时间
    private var recordingStartTime: Date?
    
    // 用于更新录制时长的计时器
    private var recordingTimer: Timer?
    
    // MARK: 初始化
    override init() {
        self.bluetoothManager = WitBluetoothManager.instance
        super.init()
        setupBluetooth()
    }
    
    // MARK: 蓝牙设置
    private func setupBluetooth() {
        // 注册为蓝牙事件观察者
        bluetoothManager.registerEventObserver(observer: self)
    }
    
    // MARK: 开始扫描设备
    func startScanning() {
        guard !isScanning else { return }
        
        print("开始扫描蓝牙设备...")
        removeAllDevices()
        
        bluetoothManager.startScan()
        isScanning = true
        
        // 3秒后自动停止扫描
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.stopScanning()
        }
    }
    
    // MARK: 停止扫描
    func stopScanning() {
        guard isScanning else { return }
        
        bluetoothManager.stopScan()
        isScanning = false
        print("停止扫描蓝牙设备")
    }
    
    // MARK: 连接设备并自动配置
    func connectToDevice(_ device: Bwt901ble) {
        do {
            try device.openDevice()
            device.registerListenKeyUpdateObserver(obj: self)
            currentDevice = device
            isConnected = true
            
            print("成功连接设备: \(device.name ?? "未知设备")")
            
            // 设备连接成功后自动进行配置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.autoConfigureDevice(device)
            }
            
            // 开始获取数据流
            startDataStream()
            
        } catch {
            print("连接设备失败: \(error)")
        }
    }
    
    // MARK: 自动配置设备（连接后执行）
    private func autoConfigureDevice(_ device: Bwt901ble) {
        print("开始自动配置设备: \(device.name ?? "未知设备")")
        
        // 执行加计校准
        performAccelerometerCalibration(device)
        
        // 设置200Hz回传速率
        setBackRate200Hz(device)
        
        // 开始磁场校准
        startFieldCalibration(device)

        // 等待3秒让磁场校准完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 结束磁场校准
            self.endFieldCalibration(device)
            print("设备自动配置完成")
        }
    }
    
    // MARK: 加计校准
    private func performAccelerometerCalibration(_ device: Bwt901ble) {
        do {
            // 解锁寄存器
            try device.unlockReg()
            // 加计校准
            try device.appliedCalibration()
            print("  加计校准完成")
            // 保存设置
            try device.saveReg()
        } catch {
            print("加计校准失败: \(error)")
        }
    }
    
    // MARK: 设置200Hz回传速率
    private func setBackRate200Hz(_ device: Bwt901ble) {
        do {
            // 解锁寄存器
            try device.unlockReg()
            // 设置200Hz回传
            try device.writeRge([0xff, 0xaa, 0x03, 0x0A, 0x00], 10)
            print("  200Hz回传已设置")
            
            // 保存设置
            try device.saveReg()
        } catch {
            print("设置回传速率失败: \(error)")
        }
    }
    
    // MARK: 开始磁场校准
    private func startFieldCalibration(_ device: Bwt901ble) {
        guard let device = currentDevice else {
            print("没有连接设备，无法进行磁场校准")
            return
        }
        do {
            // 解锁寄存器
            try device.unlockReg()
            // 开始磁场校准
            try device.startFieldCalibration()
            print("  磁场校准已开始")
            // 保存设置
            try device.saveReg()
        } catch {
            print("开始磁场校准失败: \(error)")
        }
    }
    
    // MARK: 结束磁场校准
    private func endFieldCalibration(_ device: Bwt901ble) {
        guard let device = currentDevice else {
            print("没有连接设备，无法结束磁场校准")
            return
        }
        do {
            // 解锁寄存器
            try device.unlockReg()
            // 结束磁场校准
            try device.endFieldCalibration()
            print("  磁场校准已结束")
            // 保存设置
            try device.saveReg()
        } catch {
            print("结束磁场校准失败: \(error)")
        }
    }

    // MARK: 断开连接
    func disconnect() {
        if let device = currentDevice {
            device.closeDevice()
        }
        currentDevice = nil
        isConnected = false
        stopDataStream()
        
        print("设备已断开连接")
    }
    
    // MARK: 获取当前设备名称
    var currentDeviceName: String {
        return currentDevice?.name ?? "未连接设备"
    }

    // MARK: 获取当前设备地址
    var currentDeviceMac: String {
        return currentDevice?.mac ?? "未知MAC"
    }
    
    // MARK: 移除所有设备
    private func removeAllDevices() {
        for device in deviceList {
            device.closeDevice()
        }
        deviceList.removeAll()
    }
    
    // MARK: 数据流记录
    private var timer: Timer?
    
    private func startDataStream() {
        // 200Hz = 5ms
        timer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { _ in
            self.updateData()
        }
    }
    
    private func stopDataStream() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateData() {
        if let device = currentDevice {
            // 从真实设备读取数据
            imuData.accX = Double(device.getDeviceData(WitSensorKey.AccX) ?? "0") ?? 0
            imuData.accY = Double(device.getDeviceData(WitSensorKey.AccY) ?? "0") ?? 0
            imuData.accZ = Double(device.getDeviceData(WitSensorKey.AccZ) ?? "0") ?? 0
            
            imuData.gyroX = Double(device.getDeviceData(WitSensorKey.GyroX) ?? "0") ?? 0
            imuData.gyroY = Double(device.getDeviceData(WitSensorKey.GyroY) ?? "0") ?? 0
            imuData.gyroZ = Double(device.getDeviceData(WitSensorKey.GyroZ) ?? "0") ?? 0
            
            imuData.angleX = Double(device.getDeviceData(WitSensorKey.AngleX) ?? "0") ?? 0
            imuData.angleY = Double(device.getDeviceData(WitSensorKey.AngleY) ?? "0") ?? 0
            imuData.angleZ = Double(device.getDeviceData(WitSensorKey.AngleZ) ?? "0") ?? 0
            
            imuData.temperature = Double(device.getDeviceData(WitSensorKey.Temperature) ?? "25") ?? 25.0
            imuData.battery = Double(device.getDeviceData(WitSensorKey.ElectricQuantityPercentage) ?? "100") ?? 100.0
            
            // 如果正在录制，添加到记录器
            if isRecording {
                dataRecorder.addDataRecord(device: device, timestamp: Date())
                recordedDataCount += 1
            }
        } else {
            // 模拟数据，放平时的稳定值
            imuData.accX = 0.01
            imuData.accY = 0.02
            imuData.accZ = 1.00
            imuData.gyroX = 0.0
            imuData.gyroY = 0.0
            imuData.gyroZ = 0.0
            imuData.angleX = 0.5
            imuData.angleY = -0.3
            imuData.angleZ = 1.2
            
            // 模拟录制时的数据计数
            if isRecording {
                recordedDataCount += 1
            }
        }
    }
    
    // MARK: 开始录制
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordingStartTime = Date()
        recordedDataCount = 0
        dataRecorder.startRecording()
        
        // 启动录制时长更新计时器
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        print("开始录制 - Recording started")
    }
    
    // MARK: 停止录制
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        dataRecorder.stopRecording()
        
        // 停止计时器
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        print("停止录制 - Recording stopped")
        print("录制时长: \(formatDuration(recordingDuration))")
        print("总数据条数: \(recordedDataCount)")
        
        // 重置录制时长
        recordingDuration = 0
        recordingStartTime = nil
    }
    
    // MARK: 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: 上传录制数据（不保存到本地）
    func uploadRecordingDataDirectly(completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        guard !dataRecorder.recordedData.isEmpty else {
//            let error = NSError(domain: "BluetoothSensorManager", code: 200,
//                              userInfo: [NSLocalizedDescriptionKey: "没有录制数据可上传"])
//            completion(.failure(error))
//            return
//        }
        
        guard let csvContent = dataRecorder.getCSVContent() else {
            let error = NSError(domain: "BluetoothSensorManager", code: 201,
                              userInfo: [NSLocalizedDescriptionKey: "无法获取CSV内容"])
            completion(.failure(error))
            return
        }
        
        let stats = dataRecorder.getRecordingStats()
        
        // 构建上传数据
        let uploadData: [String: Any] = [
            "device_name": currentDeviceName,
            "device_mac": currentDeviceMac,
            "recording_duration": recordingDuration,
            "data_points": recordedDataCount,
            "csv_content": csvContent,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "stats": stats
        ]
        
        print("📤 直接上传录制数据到服务器...")
        print("   - 数据大小: \(csvContent.count) 字符")
        print("   - 数据条数: \(recordedDataCount)")
        print("   - 录制时长: \(formatDuration(recordingDuration))")
        
        // 上传到服务器
        uploadToServer(data: uploadData, completion: completion)
    }

    // MARK: 上传到服务器（核心方法）
    private func uploadToServer(data: [String: Any],
                              completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        serverManager.uploadRecordingData(data) { result in
            switch result {
            case .success(let response):
                print("✅ 数据上传成功")
                completion(.success(response))
                
            case .failure(let error):
                print("❌ 上传失败: \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: 处理上传结果
    private func handleUploadResult(result: Result<[String: Any], Error>,
                                   data: [String: Any],
                                   completion: @escaping (Result<[String: Any], Error>) -> Void) {
        switch result {
        case .success(let response):
            print("✅ 数据上传成功")
            completion(.success(response))
            
        case .failure(let error):
            print("❌ 上传失败，尝试备用接口: \(error)")
            
            // 如果失败，使用离线分析
            let offlineResult = serverManager.analyzeOffline(data)
            print("⚠️ 使用离线分析结果")
            completion(.success(offlineResult))
        }
    }

    // MARK: 停止录制并上传（合并操作）
    func stopRecordingAndUpload(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard isRecording else {
            let error = NSError(domain: "BluetoothSensorManager", code: 202,
                                userInfo: [NSLocalizedDescriptionKey: "没有正在进行的录制"])
            completion(.failure(error))
            return
        }
        
        print("⏹️ 停止录制并准备上传数据...")
        
        // 停止录制
        stopRecording()
        
        // 直接上传（不保存到本地）
        uploadRecordingDataDirectly(completion: completion)
    }
}

// MARK: - 扩展：实现蓝牙事件观察者

extension BluetoothSensorManager: IBluetoothEventObserver {
    func onFoundBle(bluetoothBLE: BluetoothBLE?) {
        if let ble = bluetoothBLE, !deviceList.contains(where: { $0.mac == ble.mac }) {
            let newDevice = Bwt901ble(bluetoothBLE: ble)
            deviceList.append(newDevice)
            print("发现新设备: \(ble.peripheral.name ?? "未知") - MAC: \(ble.mac ?? "未知")")
        }
    }
    
    func onConnected(bluetoothBLE: BluetoothBLE?) {
        print("设备连接成功: \(bluetoothBLE?.peripheral.name ?? "未知")")
    }
    
    func onConnectionFailed(bluetoothBLE: BluetoothBLE?) {
        print("设备连接失败: \(bluetoothBLE?.peripheral.name ?? "未知")")
    }
    
    func onDisconnected(bluetoothBLE: BluetoothBLE?) {
        print("设备断开连接: \(bluetoothBLE?.peripheral.name ?? "未知")")
        isConnected = false
    }
}

// MARK: - 扩展：实现数据记录观察者

extension BluetoothSensorManager: IBwt901bleRecordObserver {
    func onRecord(_ bwt901ble: Bwt901ble) {
        // 这里可以处理真实传感器数据
        if dataRecorder.isRecording {
            dataRecorder.addDataRecord(device: bwt901ble, timestamp: Date())
        }
    }
}

// MARK: - IMU Data Structure

struct IMUData {
    var accX: Double = 0.0
    var accY: Double = 0.0
    var accZ: Double = 0.0
    var gyroX: Double = 0.0
    var gyroY: Double = 0.0
    var gyroZ: Double = 0.0
    var angleX: Double = 0.0
    var angleY: Double = 0.0
    var angleZ: Double = 0.0
    var temperature: Double = 25.0
    var battery: Double = 100.0
}

// MARK: - Data recorder

class DataRecorder: ObservableObject {
    
    // 记录状态
    @Published var isRecording = false
    
    // 记录开始时间
    private var startTime: Date?
    
    // 记录的数据
    private var recordedData: [String] = []
    
    // 文件管理器
    private let fileManager = FileManager.default
    
    // 记录计数器，避免重复记录
    private var recordCount = 0
    
    // MARK: 开始记录
    func startRecording() {
        isRecording = true
        startTime = Date()
        recordedData.removeAll()
        recordCount = 0
        
        // 添加CSV文件头
        let header = "Timestamp,DeviceName,Mac,AX,AY,AZ,GX,GY,GZ,AngX,AngY,AngZ,HX,HY,HZ,Electric,Temp"
        recordedData.append(header)
        
        print("开始记录数据 - Start recording data")
    }
    
    // MARK: 停止记录
    func stopRecording() {
        isRecording = false
        print("停止记录数据 - Stop recording data")
    }
    
    // MARK: 添加数据记录
    func addDataRecord(device: Bwt901ble, timestamp: Date) {
        guard isRecording else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timeString = dateFormatter.string(from: timestamp)
        
        let record = "\(timeString)," +
        "\(device.name ?? "")," +
        "\(device.mac ?? "")," +
        "\(device.getDeviceData(WitSensorKey.AccX) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.AccY) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.AccZ) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.GyroX) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.GyroY) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.GyroZ) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.AngleX) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.AngleY) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.AngleZ) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.MagX) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.MagY) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.MagZ) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.ElectricQuantityPercentage) ?? "0")," +
        "\(device.getDeviceData(WitSensorKey.Temperature) ?? "0")"
        
        recordedData.append(record)
    }
    
    // MARK: 保存数据到文件
    func saveDataToFile() -> URL? {
        guard !recordedData.isEmpty, let startTime = startTime else {
            print("没有数据可保存 - No data to save")
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "sensor_data_\(dateFormatter.string(from: startTime)).csv"
        
        // 获取文档目录
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            let dataString = recordedData.joined(separator: "\n")
            try dataString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("数据已保存到: \(fileURL.path)")
            return fileURL
        } catch {
            print("保存文件失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: 获取CSV内容（不保存到文件）
    func getCSVContent() -> String? {
        guard !recordedData.isEmpty else {
            return nil
        }
        return recordedData.joined(separator: "\n")
    }
    
    // MARK: 获取记录的数据行数
    func getRecordCount() -> Int {
        return max(0, recordedData.count - 1) // 减去标题行
    }
    
    // MARK: 获取当前缓存的数据条数（实时）
    func getCurrentRecordCount() -> Int {
        return recordedData.count
    }
    
    // MARK: 获取记录时长
    func getRecordingDuration() -> TimeInterval {
        guard let startTime = startTime, isRecording else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // MARK: 获取数据统计
    func getRecordingStats() -> [String: Any] {
        return [
            "data_points": max(0, recordedData.count - 1), // 减去标题行
            "duration": getRecordingDuration(),
            "csv_size": recordedData.joined(separator: "\n").utf8.count
        ]
    }
    
    // MARK: 清理数据
    func clearData() {
        recordedData.removeAll()
        recordCount = 0
        startTime = nil
    }
}

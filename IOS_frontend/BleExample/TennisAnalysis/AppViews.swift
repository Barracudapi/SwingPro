//
//  AppView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI
import Combine
import Charts // IMPORT CRITICAL FOR GRAPHS
import WitSDK
import CoreBluetooth

// TODO: Deal with the color setting if user is in Dark Mode. (Now some text will be invisible.)
// TODO: Now when testing on phone, the loading time is kind of long.

// MARK: - 1. Home Menu Page

struct HomeMenuView: View {
    // @ObservedObject var sensorManager: SensorManager
    @ObservedObject var sensorManager: BluetoothSensorManager
    @State private var showTrackingSession = false
    @State private var showDeviceList = false
    @State private var showRealTimeData = false
    
    // Server state variables
    @State private var serverAvailable = false
    @State private var serverStatus = "Checking server connection..."
    @State private var isServerConnecting = false
    @State private var serverAnalysisResult: String? = nil
    @State private var lastServerUpdate: Date? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.offWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Welcome back,")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Champion")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.tennisBlue)
                            }
                            Spacer()
                            
//                            // Sensor Status Badge
//                            HStack(spacing: 6) {
//                                Circle()
//                                    .fill(sensorManager.isConnected ? Color.tennisGreen : Color.red)
//                                    .frame(width: 8, height: 8)
//                                Text(sensorManager.isConnected ? "Sensor Ready" : "Disconnected")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            .padding(8)
//                            .background(Color.white)
//                            .cornerRadius(20)
//                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Main Action Card
                        Button(action: {
                            if sensorManager.isConnected {
                                showTrackingSession = true
                                sensorManager.startRecording()
                            } else {
                                showDeviceList = true
                            }

                        }) {
                            ZStack {
                                LinearGradient(gradient: Gradient(colors: [
                                    sensorManager.isConnected ? Color.tennisGreen : Color.tennisBlue,
                                    sensorManager.isConnected ? Color.tennisGreen.opacity(0.8) : Color.tennisBlue.opacity(0.8)
                                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Start Session")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text(sensorManager.isConnected ?
                                             "Track speed, spin, and classification live." :
                                             "Connect to your IMU sensor to get started.")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack {
                                            Text(sensorManager.isConnected ? "START TRACKING" : "CONNECT NOW")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 12)
                                                .background(Color.white)
                                                .foregroundColor(.tennisBlue)
                                                .cornerRadius(20)
                                        }
                                        .padding(.top, 5)
                                    }
                                    Spacer()
                                    Image(systemName: sensorManager.isConnected ? "figure.tennis" : "antenna.radiowaves.left.and.right")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                        .foregroundColor(.white.opacity(0.2))
                                }
                                .padding(25)
                            }
                            .frame(height: 180)
                            .cornerRadius(25)
                            .shadow(color: Color.tennisBlue.opacity(0.3), radius: 10, x: 0, y: 10)
                        }
                        .padding(.horizontal)
                        
                        // Sensor Connection Status Card（After Connected）
                        if sensorManager.isConnected {
                            IMUConnectionStatusView(sensorManager: sensorManager)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .scale))
                            
                            // Real-time IMU Data Show（After Connected）
                            RealTimeIMUView(imuData: $sensorManager.imuData)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.horizontal)
                        }

                        // Server Connection Status Card (使用 State 变量)
                        ServerConnectionView(
                            serverAvailable: $serverAvailable,
                            serverStatus: $serverStatus,
                            isServerConnecting: $isServerConnecting,
                            onReconnect: reconnectServer
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale))
                        
//                        // Server Analysis Results (if available)
//                        if let result = serverAnalysisResult, sensorManager.isConnected {
//                            ServerAnalysisView(analysisResult: result)
//                                .padding(.horizontal)
//                                .transition(.move(edge: .top).combined(with: .opacity))
//                        }

                        Text("Recent Stats")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Stat Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            StatCard(title: "Avg Speed", value: "72 mph", icon: "speedometer")
                            StatCard(title: "Forehands", value: "65%", icon: "arrow.up.right.circle")
                            StatCard(title: "Backhands", value: "35%", icon: "arrow.down.left.circle")
                            StatCard(title: "Play Time", value: "4h 20m", icon: "clock")
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTrackingSession) {
                TrackingSessionView(sensorManager: sensorManager)
            }
            .sheet(isPresented: $showDeviceList) {
                DeviceListView(sensorManager: sensorManager,
                               showRealTimeData: $showRealTimeData)
            }
            .onAppear {
                // 检查服务器连接状态
                checkServerConnection()
            }
        }
    }
    
    private func checkServerConnection() {
        isServerConnecting = true
        serverStatus = "Checking connection..."
        
        ServerAnalysisManager.shared.testConnection { success, message in
            DispatchQueue.main.async {
                self.isServerConnecting = false
                self.serverAvailable = success
                self.serverStatus = message
                self.lastServerUpdate = Date()
                print("服务器状态: \(message)")
            }
        }
    }
    
    private func reconnectServer() {
        checkServerConnection()
    }
    
    private func performAnalysis() {
        // 如果需要进行分析，这里可以调用
        // ServerAnalysisManager.shared.analyzeSensorData(...)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.tennisGreen)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.tennisBlue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


// MARK: - 2. 设备列表视图 Device List
struct DeviceListView: View {
    @ObservedObject var sensorManager: BluetoothSensorManager
    @Binding var showRealTimeData: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Available Sensors")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button("Scan") {
                        sensorManager.startScanning()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                if sensorManager.deviceList.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Sensors Found")
                            .font(.headline)
                        Text("Make sure your IMU sensor is turned on and in range.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Scan Again") {
                            sensorManager.startScanning()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top)
                    }
                    .padding()
                } else {
                    List(sensorManager.deviceList) { device in
                        DeviceRowView(device: device) {
                            sensorManager.connectToDevice(device)
                            
                            // 连接成功后关闭sheet并显示实时数据
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                presentationMode.wrappedValue.dismiss()
                                withAnimation {
                                    showRealTimeData = true
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Simulate connection for testing
                Button("Simulate Connection (Test)") {
                    sensorManager.connectToDevice(Bwt901ble(bluetoothBLE: nil))
                    presentationMode.wrappedValue.dismiss()
                    withAnimation {
                        showRealTimeData = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                // 进入界面时自动开始扫描
                sensorManager.startScanning()
            }
        }
    }
}


struct DeviceRowView: View {
    let device: Bwt901ble
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name ?? "Unknown Device")
                    .font(.headline)
                Text(device.mac ?? "Unknown MAC")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button("Connect") {
                onConnect()
            }
            .buttonStyle(.bordered)
            .scaleEffect(0.9)
        }
        .padding(.vertical, 8)
    }
}


// MARK: - 3. 实时IMU数据显示组件 Real-time IMU Data Component
struct RealTimeIMUView: View {
    @Binding var imuData: IMUData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sensor.tag.radiowaves.forward.fill")
                    .foregroundColor(.tennisBlue)
                Text("Live IMU Data")
                    .font(.headline)
                    .foregroundColor(.tennisBlue)
                Spacer()
                Text("Real-time")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Data Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                // Acceleration Data
                DataCell(title: "Acc X", value: String(format: "%.2f", imuData.accX), unit: "g")
                DataCell(title: "Acc Y", value: String(format: "%.2f", imuData.accY), unit: "g")
                DataCell(title: "Acc Z", value: String(format: "%.2f", imuData.accZ), unit: "g")
                
                // Gyroscope Data
                DataCell(title: "Gyro X", value: String(format: "%.0f", imuData.gyroX), unit: "°/s")
                DataCell(title: "Gyro Y", value: String(format: "%.0f", imuData.gyroY), unit: "°/s")
                DataCell(title: "Gyro Z", value: String(format: "%.0f", imuData.gyroZ), unit: "°/s")
                
                // Angle Data
                DataCell(title: "Angle X", value: String(format: "%.1f", imuData.angleX), unit: "°")
                DataCell(title: "Angle Y", value: String(format: "%.1f", imuData.angleY), unit: "°")
                DataCell(title: "Angle Z", value: String(format: "%.1f", imuData.angleZ), unit: "°")
                
                // System Data
                DataCell(title: "Temp", value: String(format: "%.1f", imuData.temperature), unit: "°C")
                DataCell(title: "Battery", value: String(format: "%.0f", imuData.battery), unit: "%")
            }
            .padding(.vertical, 5)
            
            // Status Indicator
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Streaming active • Update: 5ms")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}


// MARK: - 4. 数据单元格 Data Cell
struct DataCell: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.tennisBlue)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.offWhite)
        .cornerRadius(8)
    }
}


// MARK: - 5. 服务器连接状态组件 Server Connection Status Component

struct ServerConnectionView: View {
    @Binding var serverAvailable: Bool
    @Binding var serverStatus: String
    @Binding var isServerConnecting: Bool
    var onReconnect: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with status
            HStack {
                HStack(spacing: 10) {
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        if isServerConnecting {
                            Circle()
                                .stroke(statusColor, lineWidth: 2)
                                .frame(width: 16, height: 16)
                                .scaleEffect(1.5)
                                .opacity(0.6)
                                .animation(
                                    Animation.easeInOut(duration: 1)
                                        .repeatForever(autoreverses: false),
                                    value: isServerConnecting
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Python Server")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(serverStatus)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                // Expand/Collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(6)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                
                // Reconnect button (only when not connected and not connecting)
                if !serverAvailable && !isServerConnecting {
                    Button(action: {
                        onReconnect()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.tennisBlue))
                    }
                    .transition(.scale)
                }
            }
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Server details
                    HStack {
                        Image(systemName: serverAvailable ? "server.rack" : "exclamationmark.triangle")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Server Status")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(serverAvailable ? "Connected to Python AI Server" : "Server Unavailable")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    
                    // Connection details
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analysis Mode")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(serverAvailable ? "Real-time AI Analysis" : "Local Processing Only")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    
                    // Action buttons
                    if serverAvailable {
                        HStack {
                            Button(action: {
                                // Test server connection
                                ServerAnalysisManager.shared.testConnection { success, message in
                                    DispatchQueue.main.async {
                                        self.serverAvailable = success
                                        self.serverStatus = message
                                    }
                                    print("Server test: \(message)")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "wifi")
                                        .font(.caption)
                                    Text("Test Connection")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 5)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var statusColor: Color {
        if isServerConnecting {
            return .orange
        } else if serverAvailable {
            return .tennisGreen
        } else {
            return .red
        }
    }
}


// MARK: - 6. IMU连接状态组件 IMU Connection Status Component

struct IMUConnectionStatusView: View {
    @ObservedObject var sensorManager: BluetoothSensorManager
    @State private var showDisconnectAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with connection info
            HStack {
                HStack(spacing: 8) {
                    // Animated connection indicator
                    ZStack {
                        Circle()
                            .fill(Color.tennisGreen)
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .stroke(Color.tennisGreen, lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .scaleEffect(1.5)
                            .opacity(0.6)
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: false),
                                value: sensorManager.isConnected
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(sensorManager.currentDeviceName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Disconnect button
                Button(action: {
                    showDisconnectAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.caption)
                        Text("Disconnect")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Device info in smaller font
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(.gray)
                VStack{
                    Text("MAC: \(sensorManager.currentDeviceMac)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("Battery: \(String(format: "%.0f", sensorManager.imuData.battery))%")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .alert("Confirm Disconnect", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                sensorManager.disconnect()
            }
        } message: {
            Text("Are you sure you want to disconnect from \(sensorManager.currentDeviceName) ？")
        }
    }
}


#Preview {
    AuthenticationView()
}

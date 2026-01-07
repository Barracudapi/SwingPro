//
//  TrackingSessionView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/11.
//


import SwiftUI

// MARK: - Tracking Session View (The Active State)
// TODO: record funciton here

struct TrackingSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var sensorManager: BluetoothSensorManager
    
    @State private var hasAutoStarted = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var uploadStatus: String = ""
    @State private var uploadResult: [String: Any]? = nil
    @State private var showUploadResult = false
    @State private var shouldUploadOnExit = true // 控制是否退出时上传
    
    var body: some View {
        ZStack {
            Color.tennisBlue.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        //                        // 停止录制并退出
                        //                        if sensorManager.isRecording {
                        //                            sensorManager.stopRecording()
                        //                        }
                        //                        presentationMode.wrappedValue.dismiss()
                        // 用户点击X号，停止录制并上传
                        exitSessionWithUpload()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Text("Live Session")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.tennisGreen)
                }
                .padding()
                
                // 上传状态显示
                if isUploading {
                    UploadProgressView(progress: uploadProgress, status: uploadStatus)
                        .padding(.horizontal)
                        .transition(.move(edge: .top))
                }
                
                // 录制时长和总条目数显示
                if sensorManager.isRecording {
                    HStack(spacing: 12) {
                        // 录制时长
                        HStack(spacing: 4) {
                            Image(systemName: "record.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(formatDuration(sensorManager.recordingDuration))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .monospacedDigit()
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // 分隔点
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 3, height: 3)
                        
                        // 实时速度
                        HStack(spacing: 4) {
                            Image(systemName: "number.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.tennisGreen)
                            Text("Data Points")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text("\(sensorManager.recordedDataCount)")
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                        }
                    }
                    .padding(.bottom, 5)
                    .transition(.opacity)
                }
                
                Spacer()
                
                if !sensorManager.isConnected {
                    // Connecting State
                    VStack(spacing: 20) {
                        //                        ProgressView()
                        //                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        //                            .scaleEffect(1.5)
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Sensor Disconnected")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Button("Reconnection") {
                            sensorManager.startScanning()
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                } else {
                    // Live Data View
                    VStack(spacing: 40) {
                        
                        // Swing Classification
                        VStack {
                            Text("LAST SHOT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(sensorManager.currentSwingType)
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .transition(.scale)
                                .id("Type" + "\(sensorManager.sessionSwings)")
                        }
                        
                        // Speed Circle
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 20)
                                .frame(width: 250, height: 250)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(sensorManager.currentSpeed) / 140.0)
                                .stroke(Color.tennisGreen, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 250, height: 250)
                                .animation(.spring(), value: sensorManager.currentSpeed)
                            
                            VStack {
                                Text("\(sensorManager.currentSpeed)")
                                    .font(.system(size: 80, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                Text("MPH")
                                    .font(.headline)
                                    .foregroundColor(.tennisGreen)
                            }
                        }
                        
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(sensorManager.sessionSwings)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Total Swings")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            VStack {
                                Text("1150")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Spin RPM")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                
                Spacer()
                
                if sensorManager.isConnected {
                    VStack(spacing: 10) {
                        // End Session（will not disconet the sensor）
                        Button(action: {
                            //                            // 停止录制并退出
                            //                            if sensorManager.isRecording {
                            //                                sensorManager.stopRecording()
                            //                            }
                            //                            presentationMode.wrappedValue.dismiss()
                            // 点击后停止录制并上传
                            exitSessionWithUpload()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                Text("End Session & Upload")
                                    .fontWeight(.bold)
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(15)
                        }
                        
                        // Disconet the Sensor (will not upload)
                        Button(action: {
                            shouldUploadOnExit = false // 标记不要上传
                            if sensorManager.isRecording {
                                sensorManager.stopRecording()
                            }
                            sensorManager.disconnect()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Disconnect")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(15)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // 进入界面时自动开始录制
            autoStartRecording()
        }
        .onDisappear {
            //            // 安全起见，在界面消失时也停止录制
            //            if sensorManager.isRecording {
            //                print("⚠️ 界面消失时自动停止录制")
            //                sensorManager.stopRecording()
            //            }
            // TODO: 界面消失时,是否需要上传??
            handleViewDisappear()
        }
        .alert("Analysis Result", isPresented: $showUploadResult) {
            Button("OK") {
                uploadResult = nil
                presentationMode.wrappedValue.dismiss()
            }
            Button("View Details") {
                // TODO: 可以跳转到详情页面
                uploadResult = nil
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            if let result = uploadResult {
                var strokes = 0
                if let analysis = result["analysis"] as? [String: Any],
                   let data = analysis["data"] as? [String: Any],
                   let detected = data["strokes_detected"] as? Int {
                    strokes = detected
                }
                
                let message = result["message"] as? String ?? "Analysis completed"
                
                return Text("""
                \(message)
                
                Detected strokes: \(strokes)
                Upload successful!
                """)
            } else {
                return Text("No results available")
            }
        }
    }
    
    // 自动开始录制
    private func autoStartRecording() {
        guard !hasAutoStarted else { return }
        
        if sensorManager.isConnected && !sensorManager.isRecording {
            sensorManager.startRecording()
            print("✅ 自动开始录制")
            print("   - isRecording: \(sensorManager.isRecording)")
            print("   - 传感器已连接: \(sensorManager.isConnected)")
            print("   - 设备名称: \(sensorManager.currentDeviceName)")
        } else if !sensorManager.isConnected {
            print("⚠️ 无法开始录制：传感器未连接")
        } else if sensorManager.isRecording {
            print("ℹ️ 录制已在进行中")
        }
        
        hasAutoStarted = true
    }
    
    // 格式化时长
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 退出Session并上传
    private func exitSessionWithUpload() {
        guard sensorManager.isRecording else {
            // 如果没有录制，直接退出
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        // 开始上传流程
        startUploadProcess()
    }
    
    // 开始上传流程
    private func startUploadProcess() {
        isUploading = true
        uploadProgress = 0
        uploadStatus = "Stopping recording..."
        
        // 停止录制并上传
        sensorManager.stopRecordingAndUpload { result in
            DispatchQueue.main.async {
                self.isUploading = false
                self.uploadProgress = 1.0
                
                switch result {
                case .success(let response):
                    self.uploadStatus = "✅ Upload complete!"
                    self.uploadResult = response
                    
                    // 延迟1秒后显示结果
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showUploadResult = true
                    }
                    
                case .failure(let error):
                    self.uploadStatus = "❌ Upload failed"
                    self.uploadResult = [
                        "success": false,
                        "error": error.localizedDescription,
                        "message": "Data saved locally. Please try again later."
                    ]
                    
                    // 上传失败也显示提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showUploadResult = true
                    }
                }
            }
        }
        
        // 模拟上传进度
        simulateUploadProgress()
    }
    
    // 界面消失时的处理
    private func handleViewDisappear() {
        // 如果正在上传，不要停止
        if isUploading {
            print("⚠️ 正在上传数据，保持后台上传...")
            return
        }
        
        // 如果正在录制且应该上传，则上传
        if sensorManager.isRecording && shouldUploadOnExit {
            print("⚠️ 界面消失时自动停止录制并上传")
            startUploadProcess()
        } else if sensorManager.isRecording {
            // 只停止录制，不上传
            sensorManager.stopRecording()
            print("⚠️ 界面消失时停止录制（不上传）")
        }
    }
    
    // 模拟上传进度
    private func simulateUploadProgress() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            guard self.isUploading else {
                timer.invalidate()
                return
            }
            
            if self.uploadProgress < 0.9 {
                self.uploadProgress += 0.1
                let percent = Int(self.uploadProgress * 100)
                
                // 更新状态文本
                if percent < 30 {
                    self.uploadStatus = "Preparing data... \(percent)%"
                } else if percent < 70 {
                    self.uploadStatus = "Uploading to server... \(percent)%"
                } else {
                    self.uploadStatus = "Processing analysis... \(percent)%"
                }
            }
        }
    }
}


// MARK: - Upload Progress View 上传进度视图

struct UploadProgressView: View {
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "icloud.and.arrow.up.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .tennisGreen))
                .background(Color.white.opacity(0.2))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.blue.opacity(0.3))
        .cornerRadius(10)
    }
}

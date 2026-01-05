//
//  欢迎您使用维特智能蓝牙5.0示例程序
//  1.为了方便您使用，本程序只有这一个代码文件
//  2.本程序适用于维特智能蓝牙5.0倾角传感器
//  3.本程序将演示如何获得传感器的数据和控制传感器
//  4.如果您有疑问可以查看程序配套说明文档，或者咨询我们技术人员
//
//  Welcome to the Witte Smart Bluetooth 5.0 sample program
//  1. For your convenience, this program has only this code file
//  2. This program is suitable for Witte Smart Bluetooth 5.0 inclination sensor
//  3. This program will demonstrate how to obtain sensor data and control the sensor
//  4. If you have any questions, you can check the program supporting documentation, or consult our technical staff
//
//  Created by huangyajun on 2022/8/26.
//


import SwiftUI
import CoreBluetooth
import WitSDK


// **********************************************************
// MARK: App主视图
// MARK: App main view
// **********************************************************
@main
struct AppMainView : App {
    
    // MARK: tab页面枚举
    // MARK: tab page enumeration
    enum Tab {
        case connect
        case home
        case dataFiles // 新增的数据文件页面
    }
    
    // MARK: 当前选择的tab页面
    // MARK: The currently selected tab page
    @State private var selection: Tab = .home
    
    // MARK: App上下文
    // MARK: App the context
    var appContext:AppContext = AppContext()
    
    // MARK: UI页面
    // MARK: UI Page
    var body: some Scene {
        WindowGroup {
            if (UIDevice.current.userInterfaceIdiom == .phone){
                TabView(selection: $selection) {
                    NavigationView {
                        ConnectView(appContext)
                            
                    }
                    .tabItem {
                        Label {
                            Text("连接设备 Connect the device", comment: "在这连接设备 Connect device here")
                        } icon: {
                            Image(systemName: "list.bullet")
                        }
                    }
                    .tag(Tab.connect)
                    
                    NavigationView {
                        HomeView(appContext)
                    }
                    .tabItem {
                        Label {
                            Text("设备数据 device data", comment: "在这查看设备的数据 View device data here")
                        } icon: {
                            Image(systemName: "heart.fill")
                        }
                    }
                    .tag(Tab.home)
                                    
                    // 新增的数据文件页面
                    NavigationView {
                        DataFilesView(viewModel: appContext)
                    }
                    .tabItem {
                        Label {
                            Text("数据文件 data files", comment: "在这查看数据文件 View data files here")
                        } icon: {
                            Image(systemName: "doc.text")
                        }
                    }
                    .tag(Tab.dataFiles)
                }
            } else {
                NavigationView{
                    List{
                        NavigationLink() {
                            ConnectView(appContext)
                        } label: {
                            Label("连接设备 Connect the device", systemImage: "list.bullet")
                        }
                        
                        NavigationLink() {
                            HomeView(appContext)
                        } label: {
                            Label("主页面 main page", systemImage: "heart")
                        }
                    }
                }
            }
        }
    }
}


// **********************************************************
// MARK: 数据记录器
// MARK: Data recorder
// **********************************************************
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
    
    // MARK: 获取记录的数据行数
    func getRecordCount() -> Int {
        return max(0, recordedData.count - 1) // 减去标题行
    }
    
    // MARK: 获取记录时长
    func getRecordingDuration() -> TimeInterval {
        guard let startTime = startTime, isRecording else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
}


// **********************************************************
// MARK: 数据文件查看视图
// MARK: Data files view
// **********************************************************
struct DataFilesView: View {
    
    @ObservedObject var viewModel: AppContext
    @State private var dataFiles: [URL] = []
    @State private var selectedFile: URL?
    @State private var fileContent: String = ""
    @State private var showingDeleteAlert = false
    @State private var fileToDelete: URL?
    @State private var isRefreshing = false
    @State private var showingTennisDetails = false
    
    // MARK: 添加初始化方法
    init(viewModel: AppContext) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            // 标题和刷新按钮
            HStack {
                Text("文件管理 Files Management")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                Button(action: refreshFileList) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                }
                .padding()
                .disabled(isRefreshing)
            }
            
            // 🎾 网球分析结果显示区域（如果有结果）
            if !viewModel.tennisAnalysisResult.isEmpty && viewModel.tennisAnalysisResult != "未分析" {
                TennisAnalysisResultView(viewModel: viewModel,
                                         showingDetails: $showingTennisDetails)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: viewModel.tennisAnalysisResult)
            }
            
            if dataFiles.isEmpty {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("没有找到数据文件")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("请先在主页面记录数据")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                List {
                    ForEach(dataFiles, id: \.self) { fileURL in
                        FileRowView(
                            fileURL: fileURL,
                            viewModel: viewModel,
                            onSelect: { showFileContent(fileURL) },
                            onDelete: { confirmDelete(fileURL) },
                            onAnalyzeTennis: { analyzeTennisStroke(fileURL) }
                        )
                    }
                }
            }
            
            // 文件内容显示区域
            if selectedFile != nil {
                VStack {
                    HStack {
                        Text("文件内容:")
                            .font(.headline)
                        Spacer()
                        Button("关闭") {
                            selectedFile = nil
                            fileContent = ""
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        Text(fileContent)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            refreshFileList()
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let file = fileToDelete {
                    deleteFile(file)
                }
            }
        } message: {
            Text("确定要删除这个文件吗？此操作无法撤销。")
        }
        .sheet(isPresented: $showingTennisDetails) {
            TennisAnalysisDetailView(viewModel: viewModel)
        }
    }
    
    private func refreshFileList() {
        isRefreshing = true
        dataFiles = viewModel.getAllDataFiles()
        isRefreshing = false
    }
    
    private func showFileContent(_ fileURL: URL) {
        selectedFile = fileURL
        fileContent = viewModel.readFileContent(fileURL) ?? "无法读取文件内容"
    }
    
    private func confirmDelete(_ fileURL: URL) {
        fileToDelete = fileURL
        showingDeleteAlert = true
    }
    
    private func deleteFile(_ fileURL: URL) {
        if viewModel.deleteFile(fileURL) {
            refreshFileList()
            if selectedFile == fileURL {
                selectedFile = nil
                fileContent = ""
            }
        }
    }
    
    private func analyzeTennisStroke(_ fileURL: URL) {
        print("开始网球击球分析: \(fileURL.lastPathComponent)")
        viewModel.analyzeTennisStroke(fileURL)
    }
    
}

// 🎾 网球分析结果组件
struct TennisAnalysisResultView: View {
    @ObservedObject var viewModel: AppContext
    @Binding var showingDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tennis.racket")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("网球击球分析结果")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                // 关闭按钮
                Button(action: {
                    withAnimation {
                        viewModel.tennisAnalysisResult = "未分析"
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                
                // 详情按钮
                Button("详情") {
                    showingDetails = true
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.9)
            }
            
            if viewModel.isAnalyzingTennis {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("分析中...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
            } else {
                ScrollView {
                    Text(viewModel.tennisAnalysisResult)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.light)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 5)
    }
}

// 🎾 网球分析详情视图
struct TennisAnalysisDetailView: View {
    @ObservedObject var viewModel: AppContext
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("网球击球分析详情")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 10)
                    
                    // 分析结果
                    Text(viewModel.getLastTennisAnalysisDetails())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    // 原始数据预览
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分析参数:")
                            .font(.headline)
                        
                        if let analysisInfo = viewModel.lastTennisAnalysis["analysis_info"] as? [String: Any] {
                            ForEach(Array(analysisInfo.keys.sorted()), id: \.self) { key in
                                HStack {
                                    Text(key + ":")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(verbatim: "\(analysisInfo[key] ?? "N/A")")
                                        .font(.caption)
                                        .bold()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}


// **********************************************************
// MARK: 文件行视图
// MARK: File row view
// **********************************************************
struct FileRowView: View {
    let fileURL: URL
    let viewModel: AppContext
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onAnalyzeTennis: () -> Void
    
    
    private var fileInfo: (String, String, Int) {
        return viewModel.getFileInfo(fileURL)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileInfo.0)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(verbatim: "大小: \(fileInfo.1) | 数据行: \(fileInfo.2)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // 操作按钮行
            HStack(spacing: 10) {
                // 查看按钮
                Button(action: onSelect) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text("查看")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                // 🎾 网球分析按钮
                Button(action: onAnalyzeTennis) {
                    HStack(spacing: 4) {
                        Image(systemName: "tennis.racket")
                            .font(.caption)
                        Text("网球分析")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(6)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(viewModel.isAnalyzingTennis)
                
                Spacer()
                
                // 删除按钮
                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("删除")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(6)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 5)
        .background(Color.gray.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}



// **********************************************************
// MARK: App上下文
// MARK: App the context
// **********************************************************
class AppContext: ObservableObject ,IBluetoothEventObserver, IBwt901bleRecordObserver{
    
    // 获得蓝牙管理器
    // Get bluetooth manager
    var bluetoothManager:WitBluetoothManager = WitBluetoothManager.instance
    
    // 数据记录器
    let dataRecorder = DataRecorder()
    
    // 是否扫描设备中
    // Whether to scan the device
    @Published
    var enableScan = false
    
    // 蓝牙5.0传感器对象
    // Bluetooth 5.0 sensor object
    @Published
    var deviceList:[Bwt901ble] = [Bwt901ble]()
    
    // 要显示的设备数据
    // Device data to display
    @Published
    var deviceData:String = "未连接设备 device not connected"
    
    // 添加服务器相关属性
    @Published var serverAvailable = false
    @Published var serverStatus = "检查服务器连接..."
    @Published var pythonAnalysisResult = "等待分析..."
    @Published var isAnalyzing = false
    
    // 网球击球检测分析相关属性
    @Published var tennisAnalysisResult: String = "未分析"
    @Published var isAnalyzingTennis: Bool = false
    @Published var lastTennisAnalysis: [String: Any] = [:]
    
    // 分析计数器
    private var analysisCounter = 0
    private let analysisFrequency = 3  // 每3个数据点分析一次
    
    init(){
        // 当前扫描状态
        // Current scan status
        self.enableScan = self.bluetoothManager.isScaning
        // 开启自动刷新线程
        // start auto refresh thread
        startRefreshThread()
        
        // 检查服务器连接
        checkServerConnection()
    }
    
    // MARK: 开始扫描设备
    // MARK: Start scanning for devices
    func scanDevices() {
        print("开始扫描周围蓝牙设备 Start scanning for surrounding bluetooth devices")
        // 移除所有的设备，在这里会关闭所有设备并且从列表中移除
        // Remove all devices, here all devices are turned off and removed from the list
        removeAllDevice()
        // 注册蓝牙事件观察者
        // Registering a Bluetooth event observer
        self.bluetoothManager.registerEventObserver(observer: self)
        // 开启蓝牙扫描
        // Turn on bluetooth scanning
        self.bluetoothManager.startScan()
    }
    
    // MARK: 如果找到低功耗蓝牙传感器会调用这个方法
    // MARK: This method is called if a Bluetooth Low Energy sensor is found
    func onFoundBle(bluetoothBLE: BluetoothBLE?) {
        if isNotFound(bluetoothBLE) {
            print("\(String(describing: bluetoothBLE?.peripheral.name)) 找到一个蓝牙设备 found a bluetooth device")
            self.deviceList.append(Bwt901ble(bluetoothBLE: bluetoothBLE))
        }
    }
    
    // 判断设备还未找到
    // Judging that the device has not been found
    func isNotFound(_ bluetoothBLE: BluetoothBLE?) -> Bool{
        for device in deviceList {
            if device.mac == bluetoothBLE?.mac {
                return false
            }
        }
        return true
    }
    
    // MARK: 当连接成功时会在这里通知您
    // MARK: You will be notified here when the connection is successful
    func onConnected(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) 连接成功")
    }
    
    // MARK: 当连接失败时会在这里通知您
    // MARK: Notifies you here when the connection fails
    func onConnectionFailed(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) 连接失败")
    }
    
    // MARK: 当连接断开时会在这里通知您
    // MARK: You will be notified here when the connection is lost
    func onDisconnected(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) 连接断开")
    }
    
    // MARK: 停止扫描设备
    // MARK: Stop scanning for devices
    func stopScan(){
        // 删除蓝牙事件观察器
        self.bluetoothManager.removeEventObserver(observer: self)
        // 移除监听新找到的传感器
        self.bluetoothManager.stopScan()
    }
    
    // MARK: 打开设备
    // MARK: Turn on the device
    func openDevice(bwt901ble: Bwt901ble?){
        print("打开设备 MARK: Turn on the device")
        
        do {
            try bwt901ble?.openDevice()
            // 监听数据
            // Monitor data
            bwt901ble?.registerListenKeyUpdateObserver(obj: self)
        }
        catch{
            print("打开设备失败 Failed to open device")
        }
    }
    
    // MARK: 移除所有设备
    // MARK: Remove all devices
    func removeAllDevice(){
        for item in deviceList {
            closeDevice(bwt901ble: item)
        }
        deviceList.removeAll()
    }
    
    // MARK: 关闭设备
    // MARK: Turn off the device
    func closeDevice(bwt901ble: Bwt901ble?){
        print("关闭设备 Turn off the device")
        bwt901ble?.closeDevice()
    }
    
    // MARK: 当需要记录传感器的数据时会在这里通知您
    // MARK: You will be notified here when data from the sensor needs to be recorded
    func onRecord(_ bwt901ble: Bwt901ble) {
        // 您可以在这里获得传感器的数据  You can get sensor data here
        // let deviceData =  getDeviceDataToString(bwt901ble)
        
        // 打印到控制台,您也可以在这里把数据记录到您的文件中  Prints to the console, where you can also log the data to your file
        // print(deviceData)
        
        if dataRecorder.isRecording {
            dataRecorder.addDataRecord(device: bwt901ble, timestamp: Date())
        }
        
        // 【新增】实时服务器分析
        // performRealTimeAnalysis(bwt901ble)
    }
    
    // MARK: 开启自动执行线程
    // MARK: Enable automatic execution thread
    func startRefreshThread(){
        // 启动一个线程 start a thread
        let thread = Thread(target: self,
                            selector: #selector(refreshView),
                            object: nil)
        thread.start()
    }
    
    // MARK: 刷新视图线程,会在这里刷新传感器数据显示在页面上
    // MARK: Refresh the view thread, which will refresh the sensor data displayed on the page here
    @objc func refreshView (){
        // 一直运行这个线程
        // Keep running this thread
        while true {
            // 每秒刷新5次
            // Refresh 5 times per second
            Thread.sleep(forTimeInterval: 1 / 5)
            // 临时保存传感器数据
            // Temporarily save sensor data
            var tmpDeviceData:String = ""
            // 打印每一个设备的数据
            // Print the data of each device
            for device in deviceList {
                if (device.isOpen){
                    // 获得设备的数据，并且拼接为字符串
                    // Get the data of the device and concatenate it into a string
                    let deviceData =  getDeviceDataToString(device)
                    tmpDeviceData = "\(tmpDeviceData)\r\n\(deviceData)"
                }
            }
            
            // 刷新ui
            // Refresh ui
            DispatchQueue.main.async {
                self.deviceData = tmpDeviceData
            }
            
        }
    }
    
    // MARK: 获得设备的数据，并且拼接为字符串
    // MARK: Get the data of the device and concatenate it into a string
    func getDeviceDataToString(_ device:Bwt901ble) -> String {
        var s = ""
        s  = "\(s)name:\(device.name ?? "")\r\n"
        s  = "\(s)mac:\(device.mac ?? "")\r\n"
        s  = "\(s)version:\(device.getDeviceData(WitSensorKey.VersionNumber) ?? "")\r\n"
        s  = "\(s)AX:\(device.getDeviceData(WitSensorKey.AccX) ?? "") g\r\n"
        s  = "\(s)AY:\(device.getDeviceData(WitSensorKey.AccY) ?? "") g\r\n"
        s  = "\(s)AZ:\(device.getDeviceData(WitSensorKey.AccZ) ?? "") g\r\n"
        s  = "\(s)GX:\(device.getDeviceData(WitSensorKey.GyroX) ?? "") °/s\r\n"
        s  = "\(s)GY:\(device.getDeviceData(WitSensorKey.GyroY) ?? "") °/s\r\n"
        s  = "\(s)GZ:\(device.getDeviceData(WitSensorKey.GyroZ) ?? "") °/s\r\n"
        s  = "\(s)AngX:\(device.getDeviceData(WitSensorKey.AngleX) ?? "") °\r\n"
        s  = "\(s)AngY:\(device.getDeviceData(WitSensorKey.AngleY) ?? "") °\r\n"
        s  = "\(s)AngZ:\(device.getDeviceData(WitSensorKey.AngleZ) ?? "") °\r\n"
        s  = "\(s)HX:\(device.getDeviceData(WitSensorKey.MagX) ?? "") μt\r\n"
        s  = "\(s)HY:\(device.getDeviceData(WitSensorKey.MagY) ?? "") μt\r\n"
        s  = "\(s)HZ:\(device.getDeviceData(WitSensorKey.MagZ) ?? "") μt\r\n"
        s  = "\(s)Electric:\(device.getDeviceData(WitSensorKey.ElectricQuantityPercentage) ?? "") %\r\n"
        s  = "\(s)Temp:\(device.getDeviceData(WitSensorKey.Temperature) ?? "") °C\r\n"
        return s
    }
    
    // MARK: 加计校准
    // MARK: Addition calibration
    func appliedCalibration(){
        for device in deviceList {
            
            do {
                // 解锁寄存器
                // Unlock register
                try device.unlockReg()
                // 加计校准
                // Addition calibration
                try device.appliedCalibration()
                // 保存
                // save
                try device.saveReg()
                
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 开始磁场校准
    // MARK: Start magnetic field calibration
    func startFieldCalibration(){
        for device in deviceList {
            do {
                // 解锁寄存器
                // Unlock register
                try device.unlockReg()
                // 开始磁场校准
                // Start magnetic field calibration
                try device.startFieldCalibration()
                // 保存
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 结束磁场校准
    // MARK: End magnetic field calibration
    func endFieldCalibration(){
        for device in deviceList {
            do {
                // 解锁寄存器
                // Unlock register
                try device.unlockReg()
                // 结束磁场校准
                // End magnetic field calibration
                try device.endFieldCalibration()
                // 保存
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 读取03寄存器
    // MARK: Read the 03 register
    func readReg03(){
        for device in deviceList {
            do {
                // 读取03寄存器，等待200ms，如果没读到可以把读取时间延长或多读几次
                // Read the 03 register and wait for 200ms. If it is not read out, you can extend the reading time or read it several times
                try device.readRge([0xff ,0xaa, 0x27, 0x03, 0x00], 200, {
                    let reg03value = device.getDeviceData("03")
                    // 输出结果到控制台
                    // Output the result to the console
                    print("\(String(describing: device.mac)) reg03value: \(String(describing: reg03value))")
                })
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 设置50hz回传
    // MARK: Set 50hz postback
    func setBackRate50hz(){
        for device in deviceList {
            do {
                // 解锁寄存器
                // unlock register
                try device.unlockReg()
                // 设置50hz回传,并等待10ms
                // Set 50hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x08, 0x00], 10)
                // 保存
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 设置10hz回传
    // MARK: Set 10hz postback
    func setBackRate10hz(){
        for device in deviceList {
            do {
                // 解锁寄存器
                // unlock register
                try device.unlockReg()
                // 设置10hz回传,并等待10ms
                // Set 10hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x06, 0x00], 100)
                // 保存
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 设置200hz回传
    // MARK: Set 200hz postback
    func setBackRate200hz(){
        for device in deviceList {
            do {
                // 解锁寄存器
                // unlock register
                try device.unlockReg()
                // 设置200hz回传,并等待10ms
                // Set 10hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x0A, 0x00], 10)
                // 保存
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
    // MARK: 开始记录数据
    func startDataRecording() {
        dataRecorder.startRecording()
    }
    
    // MARK: 停止记录数据并保存
    func stopDataRecording() {
        dataRecorder.stopRecording()
        if let fileURL = dataRecorder.saveDataToFile() {
            print("数据已保存到: \(fileURL.path)")
            // 这里可以添加分享文件的功能
        }
    }
    
    // MARK: 获取记录状态
    func isRecording() -> Bool {
        return dataRecorder.isRecording
    }
    
    // MARK: 获取记录信息
    func getRecordingInfo() -> String {
        if dataRecorder.isRecording {
            let duration = Int(dataRecorder.getRecordingDuration())
            let recordCount = dataRecorder.getRecordCount()
            return "记录中 - \(duration)秒 - \(recordCount)个数据点"
        } else {
            return "未记录"
        }
    }
    
    // MARK: 获取所有已保存的数据文件
    func getAllDataFiles() -> [URL] {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsPath,
                                                          includingPropertiesForKeys: [.creationDateKey],
                                                          options: .skipsHiddenFiles)
            // 过滤出CSV文件并按创建时间排序
            return files
                .filter { $0.pathExtension == "csv" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            print("获取文件列表失败: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: 读取文件内容
    func readFileContent(_ fileURL: URL) -> String? {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            print("读取文件失败: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: 删除文件
    func deleteFile(_ fileURL: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("删除文件失败: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: 获取文件信息
    func getFileInfo(_ fileURL: URL) -> (String, String, Int) {
        let fileName = fileURL.lastPathComponent
        var fileSize: String = "未知"
        var lineCount: Int = 0
        
        do {
            // 获取文件大小
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let size = attributes[.size] as? Int {
                if size < 1024 {
                    fileSize = "\(size) B"
                } else if size < 1024 * 1024 {
                    fileSize = "\(size / 1024) KB"
                } else {
                    fileSize = "\(size / (1024 * 1024)) MB"
                }
            }
            
            // 获取行数
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            lineCount = max(0, lines.count - 1) // 减去标题行，确保不为负数
        } catch {
            print("获取文件信息失败: \(error.localizedDescription)")
            // 使用默认值，已经初始化过了
        }
        
        return (fileName, fileSize, lineCount)
    }
    
    // MARK: - 检查服务器连接
    private func checkServerConnection() {
        ServerAnalysisManager.shared.testConnection { [weak self] success, message in
            DispatchQueue.main.async {
                self?.serverAvailable = success
                self?.serverStatus = message
                print("服务器状态: \(message)")
            }
        }
    }

    // MARK: - 实时分析（连接到你的Python服务器）
    private func performRealTimeAnalysis(_ device: Bwt901ble) {
        analysisCounter += 1
        
        // 控制分析频率，避免太频繁
        if analysisCounter % analysisFrequency == 0 {
            let sensorData = prepareSensorDataForAnalysis(device: device)
            
            // 在后台线程执行分析
            DispatchQueue.global(qos: .userInitiated).async {
                self.isAnalyzing = true
                
                if self.serverAvailable {
                    self.analyzeWithServer(sensorData)
                } else {
                    self.analyzeOffline(sensorData)
                }
            }
        }
    }
    
    // MARK: - 准备传感器数据
    private func prepareSensorDataForAnalysis(device: Bwt901ble) -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        return [
            "sensor_data": [
                "acc_x": device.getDeviceData(WitSensorKey.AccX) ?? "0",
                "acc_y": device.getDeviceData(WitSensorKey.AccY) ?? "0",
                "acc_z": device.getDeviceData(WitSensorKey.AccZ) ?? "0",
                "gyro_x": device.getDeviceData(WitSensorKey.GyroX) ?? "0",
                "gyro_y": device.getDeviceData(WitSensorKey.GyroY) ?? "0",
                "gyro_z": device.getDeviceData(WitSensorKey.GyroZ) ?? "0",
                "angle_x": device.getDeviceData(WitSensorKey.AngleX) ?? "0",
                "angle_y": device.getDeviceData(WitSensorKey.AngleY) ?? "0",
                "angle_z": device.getDeviceData(WitSensorKey.AngleZ) ?? "0"
            ],
            "device_info": [
                "name": device.name ?? "Unknown",
                "mac": device.mac ?? "Unknown",
                "connected": device.isOpen
            ],
            "timestamp": dateFormatter.string(from: Date())
        ]
    }
    
    // MARK: - 使用服务器分析
    private func analyzeWithServer(_ data: [String: Any]) {
        ServerAnalysisManager.shared.analyzeSensorData(data) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let analysisResult):
                    self.handleAnalysisResult(analysisResult)
                case .failure(let error):
                    print("服务器分析失败，切换到离线模式: \(error)")
                    self.serverAvailable = false
                    self.serverStatus = "服务器连接失败，使用离线分析"
                    
                    // 失败时使用离线分析
                    let offlineResult = ServerAnalysisManager.shared.analyzeOffline(data)
                    self.handleAnalysisResult(offlineResult)
                }
                
                self.isAnalyzing = false
            }
        }
    }
    
    // MARK: - 离线分析
    private func analyzeOffline(_ data: [String: Any]) {
        let offlineResult = ServerAnalysisManager.shared.analyzeOffline(data)
        
        DispatchQueue.main.async {
            self.handleAnalysisResult(offlineResult)
            self.isAnalyzing = false
        }
    }
    
    // MARK: - 处理分析结果
    private func handleAnalysisResult(_ result: [String: Any]) {
        if let success = result["success"] as? Bool, success {
            // 从服务器返回的数据结构
            if let data = result["data"] as? [String: Any] {
                // 服务器返回的格式
                let magnitude = data["acceleration_magnitude"] as? Double ?? 0
                let state = data["motion_state"] as? String ?? "未知"
                
                self.pythonAnalysisResult = """
                🎯 服务器分析结果:
                运动状态: \(state)
                合加速度: \(String(format: "%.3f", magnitude)) g
                分析类型: 云端Python分析
                时间: \(result["timestamp"] as? String ?? "")
                """
            } else {
                // 直接返回的格式
                let magnitude = result["acceleration_magnitude"] as? Double ?? 0
                let state = result["motion_state"] as? String ?? "未知"
                let analysisType = result["analysis_type"] as? String ?? "未知"
                
                self.pythonAnalysisResult = """
                📊 分析结果 (\(analysisType)):
                运动状态: \(state)
                合加速度: \(String(format: "%.3f", magnitude)) g
                时间: \(result["timestamp"] as? String ?? "")
                """
            }
        } else {
            let errorMsg = result["error"] as? String ?? "未知错误"
            self.pythonAnalysisResult = "❌ 分析失败: \(errorMsg)"
        }
    }
    
    // MARK: - 手动触发重新连接
    func reconnectServer() {
        serverStatus = "重新连接中..."
        isAnalyzing = true
        
        ServerAnalysisManager.shared.testConnection { [weak self] success, message in
            DispatchQueue.main.async {
                self?.serverAvailable = success
                self?.serverStatus = message
                self?.isAnalyzing = false
            }
        }
    }
    
    // MARK: 分析网球击球数据
        func analyzeTennisStroke(_ fileURL: URL) {
            guard let csvContent = self.readFileContent(fileURL) else {
                tennisAnalysisResult = "❌ 无法读取CSV文件"
                return
            }
            
            isAnalyzingTennis = true
            tennisAnalysisResult = "🎾 正在分析网球击球数据..."
            
            print("开始网球击球分析，文件: \(fileURL.lastPathComponent)")
            print("CSV内容长度: \(csvContent.count) 字符")
            
            // 使用你已有的ServerAnalysisManager
            // 确保ServerAnalysisManager中有analyzeTennisStroke方法
            ServerAnalysisManager.shared.analyzeTennisStroke(csvContent: csvContent) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isAnalyzingTennis = false
                    
                    switch result {
                    case .success(let analysisResult):
                        self.handleTennisAnalysisResult(analysisResult, fileName: fileURL.lastPathComponent)
                        self.lastTennisAnalysis = analysisResult
                        
                    case .failure(let error):
                        self.tennisAnalysisResult = "❌ 分析失败: \(error.localizedDescription)"
                        print("网球分析错误详情: \(error)")
                    }
                }
            }
        }
        
        // MARK: 处理网球分析结果
        private func handleTennisAnalysisResult(_ result: [String: Any], fileName: String) {
            if let success = result["success"] as? Bool, success {
                if let data = result["data"] as? [String: Any] {
                    let strokesDetected = data["strokes_detected"] as? Int ?? 0
                    let timestamps = data["timestamps"] as? [Int] ?? []
                    
                    // 获取详细分析信息
                    var analysisDetails = ""
                    if let strokeAnalysis = data["stroke_analysis"] as? [[String: Any]], !strokeAnalysis.isEmpty {
                        analysisDetails = "\n\n击球详情:"
                        for (index, stroke) in strokeAnalysis.prefix(3).enumerated() {
                            if let type = stroke["estimated_type"] as? String,
                               let power = stroke["stroke_power"] as? Double {
                                analysisDetails += "\n  \(index+1). \(type) (强度: \(String(format: "%.1f", power)))"
                            }
                        }
                        if strokeAnalysis.count > 3 {
                            analysisDetails += "\n  ... 还有\(strokeAnalysis.count - 3)次击球"
                        }
                    }
                    
                    tennisAnalysisResult = """
                    🎾 网球击球分析完成 (\(fileName))
                    
                    检测到击球次数: \(strokesDetected) 次
                    击球时间点: \(timestamps.map { "\($0)" }.joined(separator: ", "))
                    
                    统计信息:
                    - 数据点总数: \(data["total_data_points"] as? Int ?? 0)
                    - 数据时长: \(String(format: "%.1f", data["data_duration_seconds"] as? Double ?? 0)) 秒
                    - 平均间隔: \(data["average_interval"] as? String ?? "N/A")\(analysisDetails)
                    
                    分析完成时间: \(result["timestamp"] as? String ?? "")
                    """
                    
                    // 在控制台打印详细信息用于调试
                    print("网球分析成功: \(result)")
                    
                } else {
                    tennisAnalysisResult = "✅ 分析完成，但数据结构异常"
                }
            } else {
                let errorMsg = result["error"] as? String ?? "未知错误"
                tennisAnalysisResult = "❌ 分析失败: \(errorMsg)"
            }
        }
        
        // MARK: 获取上一次网球分析的详细结果
        func getLastTennisAnalysisDetails() -> String {
            guard let success = lastTennisAnalysis["success"] as? Bool, success,
                  let data = lastTennisAnalysis["data"] as? [String: Any] else {
                return "无详细分析数据"
            }
            
            var details = "详细分析结果:\n\n"
            
            // 基本信息
            if let strokesDetected = data["strokes_detected"] as? Int {
                details += "击球次数: \(strokesDetected)\n"
            }
            
            // 时间戳
            if let timestamps = data["timestamps"] as? [Int] {
                details += "击球时间点: \(timestamps)\n"
            }
            
            // 统计信息
            if let stats = data["statistics"] as? [String: Any] {
                details += "\n统计信息:\n"
                for (key, value) in stats {
                    details += "  \(key): \(value)\n"
                }
            }
            
            // 每次击球的分析
            if let strokeAnalysis = data["stroke_analysis"] as? [[String: Any]] {
                details += "\n每次击球分析:\n"
                for (index, stroke) in strokeAnalysis.enumerated() {
                    details += "\n  击球 #\(index + 1):\n"
                    for (key, value) in stroke {
                        details += "    \(key): \(value)\n"
                    }
                }
            }
            
            return details
        }
}

// **********************************************************
// MARK: Home视图开始
// MARK: Home view start
// **********************************************************
struct HomeView: View {
    
    // App上下文
    // App the context
    @ObservedObject var viewModel:AppContext
    
    // MARK: 构造方法
    // MARK: Constructor
    init(_ viewModel:AppContext) {
        // 视图模型
        // View model
        self.viewModel = viewModel
    }
    
    // MARK: UI界面
    // MARK: UI page
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .center, spacing: 20) {
                
                // 控制设备区域
                VStack(alignment: .center, spacing: 15) {
                    Text("控制设备 Control device")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    // 按钮网格布局
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        Button("加计校准 Acc cali") {
                            viewModel.appliedCalibration()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .frame(height: 50)
                        
                        Button("开始磁场校准 Start mag cali") {
                            viewModel.startFieldCalibration()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .frame(height: 50)
                        
                        Button("结束磁场校准 Stop mag cali") {
                            viewModel.endFieldCalibration()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .frame(height: 50)
                        
                        Button("读取03寄存器 Read 03 reg") {
                            viewModel.readReg03()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .frame(height: 50)
                        
                        Button("设置50hz回传 Set 50hz rate") {
                            viewModel.setBackRate50hz()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .frame(height: 50)
                        
                        Button("设置200hz回传 Set 200hz rate") {
                            viewModel.setBackRate200hz()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .frame(height: 50)
                    }
                    .padding(.horizontal)
                }
                
                // 数据记录控制区域
                VStack(alignment: .center, spacing: 15) {
                    Text("数据记录 Data Recording")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if viewModel.isRecording() {
                        VStack(spacing: 10) {
                            Button("停止记录 Stop Recording") {
                                viewModel.stopDataRecording()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                            
                            Text(viewModel.getRecordingInfo())
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 10) {
                            Button("开始记录 Start Recording") {
                                viewModel.startDataRecording()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                            
                            Text(viewModel.getRecordingInfo())
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    Button("查看数据文件 View Data Files") {
                        // 这里可以添加导航到数据文件页面的逻辑
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
                }
                .padding(.horizontal)
                
                // 🆕 新增：服务器状态显示
                ServerStatusView(viewModel: viewModel)
                
                // 🆕 新增：Python分析结果显示区域
                PythonAnalysisView(viewModel: viewModel)
                
                // 设备数据显示区域
                VStack(alignment: .center, spacing: 15) {
                    Text("设备数据 Device data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading) {
                        Text(self.viewModel.deviceData)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.light)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}

// 🆕 服务器状态组件
struct ServerStatusView: View {
    @ObservedObject var viewModel: AppContext
    
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("服务器状态")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                // 状态指示灯
                Circle()
                    .fill(viewModel.serverAvailable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: viewModel.serverAvailable ? .green : .red, radius: 3)
                
                Text(viewModel.serverStatus)
                    .font(.subheadline)
                    .foregroundColor(viewModel.serverAvailable ? .green : .red)
                
                Spacer()
                
                // 重新连接按钮
                if !viewModel.serverAvailable {
                    Button("重连") {
                        viewModel.reconnectServer()
                    }
                    .buttonStyle(.bordered)
                    .scaleEffect(0.9)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .padding(.horizontal)
    }
}

// 🆕 Python分析结果显示组件
struct PythonAnalysisView: View {
    @ObservedObject var viewModel: AppContext
    
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Python实时分析")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                
                // 分析结果显示
                Text(viewModel.pythonAnalysisResult)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.light)
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                
                // 分析统计信息
                HStack {
                    Image(systemName: viewModel.serverAvailable ? "server.rack" : "iphone.gen3")
                        .foregroundColor(.gray)
                    Text(viewModel.serverAvailable ? "云端Python分析" : "本地离线分析")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if viewModel.serverAvailable {
                        Image(systemName: "wifi")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
        .padding(.horizontal)
    }
}

// 自定义按钮样式
extension View {
    func borderedButtonStyle() -> some View {
        self
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(AppContext())
    }
}


// **********************************************************
// MARK: 接视图开始
// MARK: Start with the view
// **********************************************************
struct ConnectView: View {
    
    // App上下文
    // App the context
    @ObservedObject var viewModel:AppContext
    
    // MARK: 构造方法
    // MARK: Constructor
    init(_ viewModel:AppContext) {
        // 视图模型
        // View model
        self.viewModel = viewModel
    }
    
    // MARK: UI页面
    // MARK: UI page
    var body: some View {
        ZStack(alignment: .leading) {
            VStack{
                Toggle(isOn: $viewModel.enableScan){
                    Text("开启扫描周围设备 Turn on scanning for surrounding devices")
                }.onChange(of: viewModel.enableScan) { value in
                    if value {
                        viewModel.scanDevices()
                    }else{
                        viewModel.stopScan()
                    }
                }.padding(10)
                ScrollViewReader { proxy in
                    List{
                        ForEach (self.viewModel.deviceList){ device in
                            Bwt901bleView(device, viewModel)
                        }
                    }
                }
            }
        }.navigationBarHidden(true)
    }
}


struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView(AppContext())
    }
}

// **********************************************************
// MARK: 显示蓝牙5.0传感器的视图
// MARK: View showing Bluetooth 5.0 sensor
// **********************************************************
struct Bwt901bleView: View{
    
    // bwt901ble实例
    // bwt901ble instance
    @ObservedObject var device:Bwt901ble
    
    // App上下文
    // App the context
    @ObservedObject var viewModel:AppContext
    
    // MARK: 构造方法
    // MARK: Constructor
    init(_ device:Bwt901ble,_ viewModel:AppContext){
        self.device = device
        self.viewModel = viewModel
    }
    
    // MARK: UI页面
    // MARK: UI page
    var body: some View {
        VStack {
            Toggle(isOn: $device.isOpen) {
                VStack {
                    Text("\(device.name ?? "")")
                        .font(.headline)
                    Text("\(device.mac ?? "")")
                        .font(.subheadline)
                }
            }.onChange(of: device.isOpen) { value in
                if value {
                    viewModel.openDevice(bwt901ble: device)
                }else{
                    viewModel.closeDevice(bwt901ble: device)
                }
            }
            .padding(10)
        }
    }
}

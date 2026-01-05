//
//  SensorDataModel.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI
import Combine

// MARK: - Data Models

// Structure for a past tennis session
struct SessionRecord: Identifiable {
    let id = UUID()
    let date: Date
    let avgSpeed: Int
    let maxSpeed: Int
    let shotCount: Int
    let typeBreakdown: [SwingTypeData]
}

struct SwingTypeData: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
    let color: Color
}

// Mock Data Generator for Graphs
class HistoryManager: ObservableObject {
    @Published var recentSessions: [SessionRecord] = []
    
    init() {
        generateMockData()
    }
    
    func generateMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate last 7 days of data
        self.recentSessions = (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let avg = Int.random(in: 65...85)
            
            return SessionRecord(
                date: date,
                avgSpeed: avg,
                maxSpeed: avg + Int.random(in: 10...30),
                shotCount: Int.random(in: 100...300),
                typeBreakdown: [
                    SwingTypeData(type: "Forehand", count: Int.random(in: 50...100), color: .tennisBlue),
                    SwingTypeData(type: "Backhand", count: Int.random(in: 30...60), color: .tennisGreen),
                    SwingTypeData(type: "Serve", count: Int.random(in: 10...40), color: .orange)
                ]
            )
        }.reversed() // Sort by oldest to newest for graphs
    }
}

// MARK: - Simulated IMU Sensor Data Manager

class SensorManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var currentSpeed: Int = 0
    @Published var currentSwingType: String = "--"
    @Published var sessionSwings: Int = 0
    
    private var timer: AnyCancellable?
    
    func connectSensor() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.isConnected = true
                self.startDataStream()
            }
        }
    }
    
    func disconnectSensor() {
        withAnimation {
            self.isConnected = false
            self.timer?.cancel()
            self.currentSpeed = 0
            self.currentSwingType = "--"
        }
    }
    
    private func startDataStream() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.simulateSwing()
            }
    }
    
    private func simulateSwing() {
        let speeds = Int.random(in: 55...125)
        let types = ["Topspin Forehand", "Slice Backhand", "Flat Serve", "Volley", "Kick Serve"]
        
        withAnimation(.spring()) {
            self.currentSpeed = speeds
            self.currentSwingType = types.randomElement() ?? "Forehand"
            self.sessionSwings += 1
        }
    }
}


//
//  ContentView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI

// MARK: - Theme & Extensions

extension Color {
    static let tennisBlue = Color(red: 0x3D / 255.0, green: 0x62 / 255.0, blue: 0x8C / 255.0)
    static let tennisGreen = Color(red: 0x6B / 255.0, green: 0x94 / 255.0, blue: 0x5C / 255.0)
    static let offWhite = Color(red: 0xF5 / 255.0, green: 0xF5 / 255.0, blue: 0xFA / 255.0)
}


// MARK: - Main Entry Views

struct ContentView: View {
    @State private var showMainApp = false
    
    var body: some View {
        if showMainApp {
            MainTabView()
                .transition(.move(edge: .trailing))
        } else {
            StartScreen(showMainApp: $showMainApp)
        }
    }
}

struct StartScreen: View {
    @Binding var showMainApp: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.tennisGreen.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "figure.tennis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .foregroundColor(.tennisBlue)
                }
                
                VStack(spacing: 10) {
                    Text("ProSwing")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.tennisBlue)
                    
                    Text("Master your game with live IMU analytics.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        showMainApp = true
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.tennisBlue)
                        .cornerRadius(15)
                        .shadow(color: Color.tennisBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

struct MainTabView: View {
    // @StateObject var sensorManager = SensorManager()
    @StateObject var sensorManager = BluetoothSensorManager()
    @StateObject var historyManager = HistoryManager() // Initialize History
    
    var body: some View {
        TabView {
            HomeMenuView(sensorManager: sensorManager)
                .tabItem {
                    Label("Tracker", systemImage: "tennisball.fill")
                }
            
            // NEW ANALYTICS TAB
            AnalyticsView(historyManager: historyManager)
                .tabItem {
                    Label("Stats", systemImage: "chart.xyaxis.line")
                }
            
            TutorialsView()
                .tabItem {
                    Label("Learn", systemImage: "play.tv.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.tennisBlue)
    }
}

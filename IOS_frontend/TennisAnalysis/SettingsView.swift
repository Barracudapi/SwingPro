//
//  SettingsView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI

// MARK: -  Settings View
struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var useMetric = false
    @State private var autoSave = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sensor Configuration")) {
                    NavigationLink("Calibrate Sensor") {
                        Text("Calibration Step 1...").padding()
                    }
                    NavigationLink("Sensor Firmware") {
                        Text("Version 1.0.4").padding()
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                    Toggle("Use Metric (km/h)", isOn: $useMetric)
                    Toggle("Auto-Save Sessions", isOn: $autoSave)
                }
                
                Section(header: Text("Account")) {
                    Button("Export Data") { }
                    Button("Sign Out") { }
                        .foregroundColor(.red)
                }
                
                Section(footer: Text("ProSwing App v1.0")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

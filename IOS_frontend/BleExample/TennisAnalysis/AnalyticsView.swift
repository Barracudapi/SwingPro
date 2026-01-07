//
//  AnalyticsView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI
import Charts

// MARK: - Analytics View

struct AnalyticsView: View {
    @ObservedObject var historyManager: HistoryManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // 1. Speed Trend Graph
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Swing Speed History")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Last 7 Sessions • Avg vs Max")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Chart {
                            ForEach(historyManager.recentSessions) { session in
                                // Area chart for Average speed
                                AreaMark(
                                    x: .value("Date", session.date, unit: .day),
                                    y: .value("Avg Speed", session.avgSpeed)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.tennisBlue.opacity(0.6), Color.tennisBlue.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                                
                                // Line for Average
                                LineMark(
                                    x: .value("Date", session.date, unit: .day),
                                    y: .value("Avg Speed", session.avgSpeed)
                                )
                                .foregroundStyle(Color.tennisBlue)
                                .interpolationMethod(.catmullRom)
                                .symbol(Circle())
                                
                                // Line for Max
                                LineMark(
                                    x: .value("Date", session.date, unit: .day),
                                    y: .value("Max Speed", session.maxSpeed)
                                )
                                .foregroundStyle(Color.tennisGreen)
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            }
                        }
                        .frame(height: 220)
                        // Legend
                        HStack {
                            Circle().fill(Color.tennisBlue).frame(width: 8)
                            Text("Average").font(.caption).foregroundColor(.gray)
                            Spacer()
                            Circle().fill(Color.tennisGreen).frame(width: 8)
                            Text("Max Burst").font(.caption).foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 5)
                    
                    // 2. Swing Classification Breakdown (Donut Chart)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stroke Distribution")
                            .font(.headline)
                        
                        HStack {
                            // The Chart
                            Chart(historyManager.recentSessions.last?.typeBreakdown ?? []) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2.0
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(5)
                            }
                            .frame(height: 150)
                            
                            Spacer()
                            
                            // Custom Legend
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(historyManager.recentSessions.last?.typeBreakdown ?? []) { item in
                                    HStack {
                                        RoundedRectangle(cornerRadius: 2).fill(item.color).frame(width: 12, height: 12)
                                        Text(item.type).font(.caption).bold()
                                        Spacer()
                                        Text("\(item.count)").font(.caption).foregroundColor(.gray)
                                    }
                                }
                            }
                            .frame(width: 120)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 5)
                    
                    // 3. Volume/Intensity Bar Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Volume & Intensity")
                            .font(.headline)
                        
                        Chart {
                            ForEach(historyManager.recentSessions) { session in
                                BarMark(
                                    x: .value("Date", session.date, unit: .day),
                                    y: .value("Shots", session.shotCount)
                                )
                                .foregroundStyle(Color.tennisBlue.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: 5)
                }
                .padding()
            }
            .background(Color.offWhite.ignoresSafeArea())
            .navigationTitle("Analytics")
        }
    }
}

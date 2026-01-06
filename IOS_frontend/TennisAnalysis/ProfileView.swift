//
//  ProfileView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI

// MARK: -  Profile View
struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.tennisBlue.opacity(0.8))
                            .padding()
                            .background(Circle().fill(Color.white).shadow(radius: 5))
                        
                        Text("Alex Federer")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Semi-Pro • Right Handed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical)
                    
                    // Stats Section
                    VStack(alignment: .leading) {
                        Text("Career Statistics")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileRow(key: "Total Sessions", value: "42")
                            Divider()
                            ProfileRow(key: "Highest Speed", value: "128 MPH")
                            Divider()
                            ProfileRow(key: "Total Shots", value: "14,205")
                            Divider()
                            ProfileRow(key: "Favorite Shot", value: "Forehand Cross")
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    }
                    
                    // Equipment
                    VStack(alignment: .leading) {
                        Text("My Gear")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "tennis.racket")
                            Text("Pro Staff RF97")
                            Spacer()
                            Text("Edit")
                                .foregroundColor(.tennisBlue)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            .background(Color.offWhite.ignoresSafeArea())
            .navigationTitle("Profile")
        }
    }
}

struct ProfileRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.tennisBlue)
        }
        .padding()
    }
    
   
}

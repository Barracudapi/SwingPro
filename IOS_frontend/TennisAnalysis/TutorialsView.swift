//
//  TutorialsView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//


import SwiftUI

// MARK: - Tutorials View
struct TutorialsView: View {
    let tutorials = [
        ("Perfect Forehand", "Learn the modern ATP forehand grip and swing path.", "tennis_forehand"),
        ("Kick Serve 101", "Add massive spin to your second serve.", "tennis_serve"),
        ("Net Mastery", "Improve your volleys and overheads.", "tennis_volley"),
        ("Footwork Drills", "Move faster and recover quicker.", "tennis_footwork")
    ]
    
    var body: some View {
        NavigationView {
            List(tutorials, id: \.0) { tutorial in
                HStack(spacing: 15) {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 60)
                            .cornerRadius(8)
                        Image(systemName: "play.fill")
                            .foregroundColor(.tennisBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(tutorial.0)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(tutorial.1)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Academy")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

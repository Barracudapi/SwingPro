//
//  SettingsView.swift
//  WitSDK
//
//  Created by 顾心怡 on 2025/12/9.
//

import SwiftUI
import Combine
// MARK: - Settings ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

// MARK: - Settings Viewz

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    // Auth state
    @Binding var showSignInView: Bool
    
    var body: some View {
        List {
            Button("Log Out") {
                Task {
                    do {
                        try viewModel.signOut()
                        showSignInView = true
                    } catch {
                        print(error)
                    }
                }
                
            }
        }.navigationBarTitle("Settings")
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(showSignInView: .constant(false))
        }
    }
}

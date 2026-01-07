//
//  SignInEmailView.swift
//  BleExample
//
//  Created by Harrold Tok on 07/01/2026.
//

import SwiftUI
import Combine

@MainActor
final class SignInEmailViewModel: ObservableObject {

    @Published var email = ""
    @Published var password = ""
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            print("no email or password found.")
            return
        }
        
        Task {
            do {
                let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                print("success")
                print(returnedUserData)
            } catch {
                print("Error: \(error)")
            }
        }
    }

}

struct SignInEmailView: View {

    @StateObject private var viewModel = SignInEmailViewModel()

    var body: some View {
        VStack {
            TextField("Email...", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)

            SecureField("Password...", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.4))
                .cornerRadius(10)

            Button {
                viewModel.signIn()
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.tennisBlue)
                    .cornerRadius(15)
                    .shadow(
                        color: Color.tennisBlue.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )

            }
        }
        .padding()
        .navigationTitle("Sign In With Email")
    }
}

struct SignInEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignInEmailView()
        }
    }
}

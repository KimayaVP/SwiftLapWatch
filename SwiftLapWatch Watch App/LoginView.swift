//
//  LoginView.swift
//  SwiftLapWatch Watch App
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var linkCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.pool.swim")
                .font(.system(size: 40))
                .foregroundColor(.cyan)
            
            Text("SwiftLap")
                .font(.headline)
            
            Text("Enter your 6-digit code from the website")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Code", text: $linkCode)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
            Button(action: linkWatch) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Link Watch")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .disabled(linkCode.count < 6 || isLoading)
        }
        .padding()
    }
    
    func linkWatch() {
        isLoading = true
        errorMessage = nil
        
        APIService.linkWithCode(linkCode) { success, swimmerId, error in
            DispatchQueue.main.async {
                isLoading = false
                if success, let id = swimmerId {
                    APIService.storeSwimmerId(id)
                    isLoggedIn = true
                } else {
                    errorMessage = error ?? "Invalid code"
                }
            }
        }
    }
}

//
//  CloudKitSignInView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 18/03/2025.
//

//
//  CloudKitSignInView.swift
//  FamilyCar
//
//  Created on 17/03/2025.
//

import SwiftUI

struct CloudKitSignInView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    
    var body: some View {
        VStack(spacing: 20) {
            // App Logo
            Image(systemName: "car.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            // App Title
            Text("Family Car Usage App")
                .font(.largeTitle)
                .bold()
            
            // App Description
            Text("Keep track of your family's vehicles together")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if cloudKitManager.isLoading {
                // Loading indicator
                ProgressView("Checking iCloud status...")
                    .scaleEffect(1.2)
                    .padding()
            } else {
                VStack(spacing: 15) {
                    // Sign-in explanation
                    Text("To sync your car data across family devices, please sign in to iCloud")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Sign-in button
                    Button(action: {
                        // Try to sign in again
                        cloudKitManager.checkUserStatus()
                    }) {
                        HStack {
                            Image(systemName: "icloud.fill")
                            Text("Sign in with iCloud")
                        }
                        .frame(minWidth: 200)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Error display
                    if let error = cloudKitManager.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    // Help text
                    Text("You'll need to be signed into iCloud on this device.\nGo to Settings > Apple ID > iCloud to sign in.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Version info
            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            // Check if the user is signed in when the view appears
            cloudKitManager.checkUserStatus()
        }
    }
}

#Preview {
    CloudKitSignInView()
        .environmentObject(CloudKitManager())
}

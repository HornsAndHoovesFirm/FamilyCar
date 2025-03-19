//
//  CloudKitSignInView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 18/03/2025.
//

import SwiftUI
import CloudKit

struct CloudKitSignInView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 25) {
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
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Checking iCloud status...")
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 20) {
                    // Sign-in explanation
                    Text("To sync your car data across family devices, please sign in to iCloud")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Sign-in button
                    Button(action: {
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
                    
                    // Settings button for troubleshooting
                    Button(action: {
                        showingSettings = true
                    }) {
                        Text("Open iOS Settings")
                            .underline()
                            .foregroundColor(.blue)
                    }
                    
                    // Error display
                    if let error = cloudKitManager.error {
                        VStack(spacing: 10) {
                            Text("There was a problem with iCloud sign-in:")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(error.localizedDescription)
                                .font(.body)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .padding(.horizontal)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Help text
            Text("You'll need to be signed into iCloud on this device.\nGo to Settings > Apple ID > iCloud to sign in.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Version info
            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 10)
        }
        .padding()
        .onAppear {
            // Check if the user is signed in when the view appears
            cloudKitManager.checkUserStatus()
        }
        .sheet(isPresented: $showingSettings) {
            // This implementation allows opening iOS Settings
            SettingsLinkView()
        }
    }
}

// Helper view to open iOS Settings
struct SettingsLinkView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // Using a timer because openURL might not work immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// Preview
#Preview {
    VStack(spacing: 20) {
        Image(systemName: "car.2.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .foregroundColor(.blue)
        
        Text("Family Car Usage App")
            .font(.largeTitle)
            .bold()
        
        Text("Keep track of your family's vehicles together")
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        
        Spacer()
        
        VStack(spacing: 15) {
            Text("To sync your car data across family devices, please sign in to iCloud")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {}) {
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
        }
        
        Spacer()
        
        Text("Version 1.0.0")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
    .padding()
}

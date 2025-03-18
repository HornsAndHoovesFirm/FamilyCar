//
//  FamilyCarApp.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 12/03/2025.
//  Updated for CloudKit integration on 17/03/2025.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct FamilyCarApp: App {
    // CloudKit manager instance as an environment object
    @StateObject private var cloudKitManager = CloudKitManager()
    
    var body: some Scene {
        WindowGroup {
            if cloudKitManager.isSignedIn {
                ContentView()
                    .environmentObject(cloudKitManager)
            } else {
                CloudKitSignInView()
                    .environmentObject(cloudKitManager)
            }
        }
        .modelContainer(for: [CarProfile.self, CarDocument.self], inMemory: false, isAutosaveEnabled: true) { result in
            switch result {
            case .success(_):
                print("Successfully created model container")
                // Optionally, you could add sample data here for testing
                // if container is empty
            case .failure(let error):
                print("Failed to create model container: \(error)")
                // Handle the error more gracefully instead of crashing
                // This could include showing an error UI or attempting recovery
            }
        }
    }
}

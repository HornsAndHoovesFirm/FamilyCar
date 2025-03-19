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
    @StateObject private var cloudKitManager = CloudKitManager(
        containerIdentifier: "iCloud.com.HornsAndHooves.FamilyCar"
    )
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitManager)
        }
        .modelContainer(for: [CarProfile.self, CarDocument.self]) { result in
            switch result {
            case .success(let container):
                print("Successfully created model container")
                
                // If inMemory is false, we're using persistent storage
                if !container.configurations.contains(where: { $0.isStoredInMemoryOnly }) {
                    #if DEBUG
                    // Add sample data in debug builds if the container is empty
                    Task {
                        await addSampleDataIfNeeded(to: container)
                    }
                    #endif
                }
                
            case .failure(let error):
                print("Failed to create model container: \(error)")
                // Handle the error more gracefully instead of crashing
                // This could include showing an error UI or attempting recovery
            }
        }
    }
    
    // Add sample data if the container is empty
    @MainActor
    private func addSampleDataIfNeeded(to container: ModelContainer) async {
        // Check if we already have cars
        var descriptor = FetchDescriptor<CarProfile>()
        descriptor.fetchLimit = 1
        
        do {
            let existingCars = try container.mainContext.fetch(descriptor)
            
            // If we don't have any cars, add sample data
            if existingCars.isEmpty {
                // Create sample cars directly
                let sedan = CarProfile(
                    make: "Toyota",
                    model: "Camry",
                    year: 2022,
                    licensePlate: "ABC123",
                    nickname: "Family Sedan",
                    color: "Blue",
                    vin: "1HGCM82633A123456",
                    fuelType: .gasoline,
                    engineSize: "2.5L",
                    transmissionType: .automatic,
                    purchaseDate: Date(timeIntervalSince1970: 1640995200), // Jan 1, 2022
                    firstRoadDate: Date(timeIntervalSince1970: 1641254400)  // Jan 4, 2022
                )
                
                let suv = CarProfile(
                    make: "Honda",
                    model: "CR-V",
                    year: 2021,
                    licensePlate: "XYZ789",
                    nickname: "Adventure Wagon",
                    color: "Red",
                    vin: "5YJSA1E40FF103456",
                    fuelType: .hybrid,
                    engineSize: "1.5L Turbo",
                    transmissionType: .cvt,
                    purchaseDate: Date(timeIntervalSince1970: 1609459200), // Jan 1, 2021
                    firstRoadDate: Date(timeIntervalSince1970: 1609718400)  // Jan 4, 2021
                )
                
                // Add cars to context
                container.mainContext.insert(sedan)
                container.mainContext.insert(suv)
                
                // Save the context after adding sample data
                try container.mainContext.save()
                print("Added sample car data to the container")
            }
        } catch {
            print("Error checking for existing data: \(error)")
        }
    }
}

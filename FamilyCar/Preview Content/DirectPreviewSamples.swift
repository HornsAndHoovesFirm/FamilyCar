//
//  DirectPreviewSamples.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 19/03/2025.
//

import Foundation
import SwiftUI

// Sample car data that doesn't rely on SwiftData
struct PreviewCar {
    var make: String
    var model: String
    var year: Int
    var licensePlate: String
    var nickname: String?
    var color: String
    var vin: String
    var fuelType: String
    var engineSize: String
    var transmissionType: String
    var purchaseDate: Date
    var firstRoadDate: Date
    var hasDocument: Bool
}

// Sample family member data that doesn't rely on SwiftData
struct PreviewFamilyMember {
    var id: String
    var name: String
    var role: String
    var deviceID: String
}

// Create preview samples
struct DirectPreviewSamples {
    static let cars = [
        PreviewCar(
            make: "Toyota",
            model: "Camry",
            year: 2022,
            licensePlate: "ABC123",
            nickname: "Family Sedan",
            color: "Blue",
            vin: "1HGCM82633A123456",
            fuelType: "Gasoline",
            engineSize: "2.5L",
            transmissionType: "Automatic",
            purchaseDate: Date(timeIntervalSince1970: 1640995200), // Jan 1, 2022
            firstRoadDate: Date(timeIntervalSince1970: 1641254400),  // Jan 4, 2022
            hasDocument: true
        ),
        PreviewCar(
            make: "Honda",
            model: "CR-V",
            year: 2021,
            licensePlate: "XYZ789",
            nickname: "Adventure Wagon",
            color: "Red",
            vin: "5YJSA1E40FF103456",
            fuelType: "Hybrid",
            engineSize: "1.5L Turbo",
            transmissionType: "CVT",
            purchaseDate: Date(timeIntervalSince1970: 1609459200), // Jan 1, 2021
            firstRoadDate: Date(timeIntervalSince1970: 1609718400),  // Jan 4, 2021
            hasDocument: false
        )
    ]
    
    static let familyMembers = [
        PreviewFamilyMember(
            id: "1",
            name: "John Smith",
            role: "Owner",
            deviceID: "device1"
        ),
        PreviewFamilyMember(
            id: "2",
            name: "Jane Smith",
            role: "Admin",
            deviceID: "device2"
        )
    ]
    
    // MockCloudKitManager that doesn't depend on real CloudKit
    static let cloudKitManager: CloudKitManager = {
        let manager = CloudKitManager()
        manager.isSignedIn = true
        manager.userName = "Preview User"
        manager.userID = "preview-user-id"
        manager.isLoading = false
        manager.error = nil
        return manager
    }()
}

// Preview wrappers for different views

// Preview for car row
struct CarRowPreview: View {
    var body: some View {
        List {
            Text("Sample Car Row")
                .font(.headline)
            Text("Toyota Camry 2022")
                .foregroundColor(.secondary)
            Text("License: ABC123")
                .font(.caption)
        }
    }
}

// Preview for car detail
struct CarDetailPreview: View {
    var body: some View {
        List {
            Section("Basic Information") {
                LabeledContent("Make", value: "Toyota")
                LabeledContent("Model", value: "Camry")
                LabeledContent("Year", value: "2022")
                LabeledContent("License Plate", value: "ABC123")
                LabeledContent("Nickname", value: "Family Sedan")
                LabeledContent("Color", value: "Blue")
            }
            
            Section("Technical Details") {
                LabeledContent("VIN", value: "1HGCM82633A123456")
                LabeledContent("Fuel Type", value: "Gasoline")
                LabeledContent("Engine Size", value: "2.5L")
                LabeledContent("Transmission", value: "Automatic")
            }
            
            Section("Documents") {
                HStack {
                    Text("License Document")
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("2022 Toyota Camry")
    }
}

// Preview for car list
struct CarListPreview: View {
    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading) {
                    Text("2022 Toyota Camry")
                        .font(.headline)
                    Text("Family Sedan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("2021 Honda CR-V")
                        .font(.headline)
                    Text("Adventure Wagon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Family Cars")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Label("Add Car", systemImage: "plus")
                    }
                }
            }
        }
    }
}

// Preview for document picker
struct DocumentPickerPreview: View {
    var body: some View {
        List {
            Section("Current Document") {
                VStack(alignment: .leading) {
                    Text("vehicle_license.pdf")
                        .font(.headline)
                    Text("Uploaded: Jan 1, 2022")
                        .font(.caption)
                }
                
                Button("View Document") {
                    // Preview only
                }
                
                Button("Delete Document", role: .destructive) {
                    // Preview only
                }
            }
            
            Button("Select Document") {
                // Preview only
            }
        }
        .navigationTitle("Car Documents")
    }
}

// Preview for family members
struct FamilyMembersPreview: View {
    var body: some View {
        List {
            Section(header: Text("Your Information")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Preview User")
                            .font(.headline)
                        Text("Owner")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("You")
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                }
            }
            
            Section(header: Text("Family Members")) {
                ForEach(DirectPreviewSamples.familyMembers, id: \.id) { member in
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text(member.name)
                                .font(.headline)
                            Text(member.role)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Family Members")
    }
}

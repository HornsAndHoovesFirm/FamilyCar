//
//  PreviewData.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 13/03/2025.
//

import Foundation
import SwiftData

extension CarProfile {
    static func sampleCars() -> [CarProfile] {
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
        
        let electric = CarProfile(
            make: "Tesla",
            model: "Model 3",
            year: 2023,
            licensePlate: "EV2023",
            nickname: nil,
            color: "White",
            vin: "5YJ3E1EA1PF123456",
            fuelType: .electric,
            engineSize: "Dual Motor",
            transmissionType: .automatic,
            purchaseDate: Date(timeIntervalSince1970: 1672531200), // Jan 1, 2023
            firstRoadDate: Date(timeIntervalSince1970: 1672790400)  // Jan 4, 2023
        )
        
        return [sedan, suv, electric]
    }
    
    static func sampleCarWithDocument() -> CarProfile {
        let car = sampleCars()[0]
        let documentData = Data("Sample PDF data".utf8)
        car.licenseDocument = CarDocument(
            fileName: "vehicle_license.pdf",
            documentData: documentData
        )
        return car
    }
}

extension ModelContainer {
    @MainActor
    static func previewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: CarProfile.self, CarDocument.self,
            configurations: config
        )
        
        // Add sample cars to the container
        for car in CarProfile.sampleCars() {
            container.mainContext.insert(car)
        }
        
        return container
    }
}

/*
// For CarRowView
#Preview {
    CarRowView(car: CarProfile.sampleCars()[0])
        .modelContainer(ModelContainer.previewContainer())
}

// For CarDetailView
#Preview {
    NavigationStack {
        CarDetailView(car: CarProfile.sampleCarWithDocument())
    }
    .modelContainer(ModelContainer.previewContainer())
}

// For CarListView
#Preview {
    CarListView()
        .modelContainer(ModelContainer.previewContainer())
}
*/

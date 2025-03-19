//
//  CarModel.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 13/03/2025.
//

import Foundation
import SwiftData

// Main car profile model
@Model
class CarProfile {
    // Basic Information with default values
    var make: String = ""
    var model: String = ""
    var year: Int = Calendar.current.component(.year, from: Date())
    var licensePlate: String = ""
    var nickname: String?
    var color: String = ""
    
    // Technical Details with default values
    var vin: String = ""
    var fuelType: FuelType = FuelType.gasoline
    var engineSize: String = ""
    var transmissionType: TransmissionType = TransmissionType.automatic
    
    // Ownership Information with default values
    var purchaseDate: Date = Date()
    var firstRoadDate: Date = Date()
    
    // Document with explicit relationship declaration
    @Relationship(deleteRule: .cascade)
    var licenseDocument: CarDocument?
    
    init(
        make: String,
        model: String,
        year: Int,
        licensePlate: String,
        nickname: String? = nil,
        color: String,
        vin: String,
        fuelType: FuelType,
        engineSize: String,
        transmissionType: TransmissionType,
        purchaseDate: Date,
        firstRoadDate: Date,
        licenseDocument: CarDocument? = nil
    ) {
        self.make = make
        self.model = model
        self.year = year
        self.licensePlate = licensePlate
        self.nickname = nickname
        self.color = color
        self.vin = vin
        self.fuelType = fuelType
        self.engineSize = engineSize
        self.transmissionType = transmissionType
        self.purchaseDate = purchaseDate
        self.firstRoadDate = firstRoadDate
        self.licenseDocument = licenseDocument
    }
}

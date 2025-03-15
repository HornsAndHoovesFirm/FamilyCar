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
    // Basic Information
    var make: String
    var model: String
    var year: Int
    var licensePlate: String
    var nickname: String?
    var color: String
    
    // Technical Details
    var vin: String
    var fuelType: FuelType
    var engineSize: String
    var transmissionType: TransmissionType
    
    // Ownership Information
    var purchaseDate: Date
    var firstRoadDate: Date
    
    // Document
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

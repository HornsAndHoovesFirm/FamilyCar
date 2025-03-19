//
//  CarDoumentModel.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 13/03/2025.
//

import Foundation
import SwiftData

// Document model for storing PDF
@Model
class CarDocument {
    // Make properties have default values
    var fileName: String = ""
    var documentData: Data = Data()
    var uploadDate: Date = Date()
    
    // Add the inverse relationship to CarProfile
    @Relationship(inverse: \CarProfile.licenseDocument)
    var car: CarProfile?
    
    init(fileName: String, documentData: Data, uploadDate: Date = Date()) {
        self.fileName = fileName
        self.documentData = documentData
        self.uploadDate = uploadDate
    }
}

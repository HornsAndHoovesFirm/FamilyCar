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
    var fileName: String
    var documentData: Data
    var uploadDate: Date
    
    init(fileName: String, documentData: Data, uploadDate: Date = Date()) {
        self.fileName = fileName
        self.documentData = documentData
        self.uploadDate = uploadDate
    }
}

//
//  CarEnumsModel.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 13/03/2025.
//

import Foundation
import SwiftData

// Enum for fuel types
enum FuelType: String, Codable, CaseIterable {
    case gasoline
    case diesel
    case electric
    case hybrid
}

// Enum for transmission types
enum TransmissionType: String, Codable, CaseIterable {
    case manual
    case automatic
    case semiAutomatic
    case cvt
}

// Add extensions to make these enums persistent with SwiftData
extension FuelType: Hashable {}
extension TransmissionType: Hashable {}

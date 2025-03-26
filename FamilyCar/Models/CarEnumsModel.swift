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
    
    // Display name for better UI presentation
    var displayName: String {
        switch self {
        case .manual:
            return "Manual"
        case .automatic:
            return "Automatic"
        case .semiAutomatic:
            return "Semi-Automatic"
        case .cvt:
            return "CVT (Continuously Variable)"
        }
    }
}

// Add extensions to make these enums persistent with SwiftData
extension FuelType: Hashable {}
extension TransmissionType: Hashable {}

// Extension for FuelType to provide friendly icons
extension FuelType {
    var iconName: String {
        switch self {
        case .electric:
            return "bolt.car.fill"
        case .hybrid:
            return "leaf.arrow.circlepath"
        case .diesel:
            return "fuelpump.fill"
        case .gasoline:
            return "car.fill"
        }
    }
}

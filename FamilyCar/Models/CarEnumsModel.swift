//
//  CarEnumsModel.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 13/03/2025.
//

import Foundation

// Enum for fuel types
enum FuelType: String, Codable {
    case gasoline
    case diesel
    case electric
    case hybrid
}

// Enum for transmission types
enum TransmissionType: String, Codable {
    case manual
    case automatic
    case semiAutomatic
    case cvt
}

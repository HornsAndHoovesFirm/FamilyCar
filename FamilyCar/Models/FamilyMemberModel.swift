//
//  FamilyMemberModel.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 18/03/2025.
//

import Foundation
import SwiftData

/// Represents a family member in the application
struct FamilyMember: Identifiable, Hashable {
    let id: String
    let name: String
    let role: String
    let deviceID: String
    
    // Additional properties could be added here
    var isActive: Bool = true
    var dateAdded: Date = Date()
    
    // Optional properties that might be useful later
    var email: String?
    var phoneNumber: String?
    var profileImageData: Data?
    
    // Default initializer
    init(id: String, name: String, role: String, deviceID: String) {
        self.id = id
        self.name = name
        self.role = role
        self.deviceID = deviceID
    }
    
    // Full initializer with all properties
    init(id: String, name: String, role: String, deviceID: String,
         isActive: Bool, dateAdded: Date, email: String? = nil,
         phoneNumber: String? = nil, profileImageData: Data? = nil) {
        self.id = id
        self.name = name
        self.role = role
        self.deviceID = deviceID
        self.isActive = isActive
        self.dateAdded = dateAdded
        self.email = email
        self.phoneNumber = phoneNumber
        self.profileImageData = profileImageData
    }
}

// MARK: - Role Enum
enum FamilyRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case admin = "Admin"
    case member = "Member"
    case viewer = "Viewer"
    
    var permissions: FamilyPermissions {
        switch self {
        case .owner:
            return FamilyPermissions(canAddCar: true, canEditCar: true, canDeleteCar: true,
                                   canAddMembers: true, canRemoveMembers: true)
        case .admin:
            return FamilyPermissions(canAddCar: true, canEditCar: true, canDeleteCar: true,
                                   canAddMembers: true, canRemoveMembers: false)
        case .member:
            return FamilyPermissions(canAddCar: true, canEditCar: true, canDeleteCar: false,
                                   canAddMembers: false, canRemoveMembers: false)
        case .viewer:
            return FamilyPermissions(canAddCar: false, canEditCar: false, canDeleteCar: false,
                                   canAddMembers: false, canRemoveMembers: false)
        }
    }
}

// MARK: - Permissions Structure
struct FamilyPermissions {
    let canAddCar: Bool
    let canEditCar: Bool
    let canDeleteCar: Bool
    let canAddMembers: Bool
    let canRemoveMembers: Bool
}

// MARK: - Extension for Sample Data
extension FamilyMember {
    static func sampleMembers() -> [FamilyMember] {
        return [
            FamilyMember(id: "1", name: "John Smith", role: "Owner", deviceID: "device1"),
            FamilyMember(id: "2", name: "Jane Smith", role: "Admin", deviceID: "device2"),
            FamilyMember(id: "3", name: "Alex Smith", role: "Member", deviceID: "device3")
        ]
    }
}

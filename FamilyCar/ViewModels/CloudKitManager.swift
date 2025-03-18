//
//  CloudKitManager.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 17/03/2025.
//

import Foundation
import CloudKit
import SwiftUI
import SwiftData

/// Manager class for handling CloudKit operations
class CloudKitManager: ObservableObject {
    // Reference to the CloudKit container
    let container: CKContainer
    
    // Published properties to track state
    @Published var isSignedIn = false
    @Published var userName: String = ""
    @Published var userID: String = ""
    @Published var isLoading = false
    @Published var error: Error?
    
    // Family members
    @Published var familyMembers: [FamilyMember] = []
    
    init(containerIdentifier: String = "iCloud.com.HornsAndHooves.FamilyCar") {
        self.container = CKContainer(identifier: containerIdentifier)
        checkUserStatus()
    }
    
    /// Check if the user is signed into iCloud
    func checkUserStatus() {
        isLoading = true
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    self.isSignedIn = false
                    return
                }
                
                switch status {
                case .available:
                    self.isSignedIn = true
                    self.fetchUserRecord()
                case .noAccount:
                    self.isSignedIn = false
                    print("No iCloud account found")
                case .restricted:
                    self.isSignedIn = false
                    print("iCloud account access is restricted")
                case .temporarilyUnavailable:
                    self.isSignedIn = false
                    print("iCloud account is temporarily unavailable")
                case .couldNotDetermine:
                    self.isSignedIn = false
                    print("Could not determine iCloud account status")
                @unknown default:
                    self.isSignedIn = false
                    print("Unknown iCloud account status")
                }
            }
        }
    }
    
    /// Fetch the current user's record
    private func fetchUserRecord() {
        container.fetchUserRecordID { [weak self] recordID, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    return
                }
                
                if let id = recordID {
                    self.userID = id.recordName
                    self.fetchUserName(recordID: id)
                }
            }
        }
    }
    
    /// Fetch the current user's name
    private func fetchUserName(recordID: CKRecord.ID) {
        // With the deprecation of discoverUserIdentity, we need to use a different approach
        // Fetch the user record directly
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    return
                }
                
                if let record = record {
                    // Try to get the user's name from the record
                    // The field names might vary based on your setup
                    if let name = record["displayName"] as? String {
                        self.userName = name
                    } else {
                        // If no name is available, use a generic name
                        self.userName = "Family Member"
                    }
                    
                    // Now that we have user info, fetch family members
                    self.fetchFamilyMembers()
                }
            }
        }
    }
    
    /// Fetch family members from CloudKit
    func fetchFamilyMembers() {
        isLoading = true
        
        // Create a query for family members
        let query = CKQuery(recordType: "FamilyMember", predicate: NSPredicate(value: true))
        
        // Use the newer API instead of the deprecated perform method
        container.privateCloudDatabase.fetch(
            withQuery: query,
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let (matchResults, _)):
                    self.familyMembers = matchResults.compactMap { (recordID, result) -> FamilyMember? in
                        switch result {
                        case .success(let record):
                            let name = record["name"] as? String ?? "Unknown"
                            let role = record["role"] as? String ?? "Member"
                            let deviceID = record["deviceID"] as? String ?? ""
                            
                            return FamilyMember(
                                id: record.recordID.recordName,
                                name: name,
                                role: role,
                                deviceID: deviceID
                            )
                        case .failure:
                            return nil
                        }
                    }
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }
    
    /// Add current user as a family member if not already added
    func addCurrentUserToFamily(role: String = "Member") {
        guard !userID.isEmpty else { return }
        
        // Check if user is already a family member
        if familyMembers.contains(where: { $0.deviceID == userID }) {
            return
        }
        
        isLoading = true
        
        let record = CKRecord(recordType: "FamilyMember")
        record["name"] = userName as CKRecordValue
        record["role"] = role as CKRecordValue
        record["deviceID"] = userID as CKRecordValue
        
        container.privateCloudDatabase.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    return
                }
                
                if let record = savedRecord {
                    let member = FamilyMember(
                        id: record.recordID.recordName,
                        name: self.userName,
                        role: role,
                        deviceID: self.userID
                    )
                    self.familyMembers.append(member)
                }
            }
        }
    }
    
    /// Share a CloudKit zone with family members
    func shareWithFamily(familyMemberIDs: [String], completion: @escaping (Bool) -> Void) {
        // Implementation will depend on your specific sharing requirements
        // This is a placeholder for the sharing functionality
        
        // You would create a CKShare, add permissions, and save it
        // Then share the URL with family members
        
        // Simplified implementation for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true)
        }
    }
}

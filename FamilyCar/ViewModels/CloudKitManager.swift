//
//  CloudKitManager.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 17/03/2025.
//

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
        // Use a more generic container identifier that you'd replace with your actual bundle ID
        self.container = CKContainer(identifier: containerIdentifier)
        
        // In a production app, do an initial check
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Skip for previews and set some sample data
            setupPreviewMode()
            return
        }
        #endif
        
        // Check if the user is signed in
        checkUserStatus()
    }
    
    // Setup preview mode with mock data
    private func setupPreviewMode() {
        self.isSignedIn = true
        self.userName = "Preview User"
        self.userID = "preview-user-id"
        self.error = nil
        self.isLoading = false
        self.familyMembers = FamilyMember.sampleMembers()
    }
    
    /// Check if the user is signed into iCloud
    func checkUserStatus() {
        isLoading = true
        
        // Reset error state
        error = nil
        
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
                case .noAccount, .restricted, .temporarilyUnavailable, .couldNotDetermine:
                    self.isSignedIn = false
                    self.error = NSError(domain: "CloudKitManager",
                                        code: Int(status.rawValue),
                                        userInfo: [NSLocalizedDescriptionKey: "iCloud account not available: \(status.rawValue)"])
                @unknown default:
                    self.isSignedIn = false
                    self.error = NSError(domain: "CloudKitManager",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Unknown iCloud account status"])
                }
            }
        }
    }
    
    /// Fetch the current user's record
    private func fetchUserRecord() {
        self.isLoading = true
        
        container.fetchUserRecordID { [weak self] recordID, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    self.isLoading = false
                    return
                }
                
                if let id = recordID {
                    self.userID = id.recordName
                    self.fetchUserName(recordID: id)
                } else {
                    self.isLoading = false
                    self.error = NSError(domain: "CloudKitManager",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Could not fetch user record ID"])
                }
            }
        }
    }
    
    /// Fetch the current user's name using non-deprecated methods
    private func fetchUserName(recordID: CKRecord.ID) {
        // Since discoverUserIdentity is deprecated in iOS 17, we'll use a different approach
        // We'll check if we can get the user record from the database
        
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    return
                }
                
                if let record = record {
                    // Try to extract user info from the record if available
                    // Note: The actual field name may vary depending on your CloudKit schema
                    if let name = record["displayName"] as? String {
                        self.userName = name
                    } else if let firstName = record["firstName"] as? String,
                             let lastName = record["lastName"] as? String {
                        self.userName = "\(firstName) \(lastName)"
                    } else {
                        // Default name if no user info is available
                        self.userName = "Family Member"
                    }
                } else {
                    self.userName = "Family Member"
                }
                
                // Now that we have user info, fetch family members
                self.fetchFamilyMembers()
            }
        }
    }
    
    /// Fetch family members from CloudKit
    func fetchFamilyMembers() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return // Skip for previews since we've already set up sample data
        }
        #endif
        
        isLoading = true
        
        // Create a query for family members
        let query = CKQuery(recordType: "FamilyMember", predicate: NSPredicate(value: true))
        
        // Query operation
        let operation = CKQueryOperation(query: query)
        
        var fetchedMembers: [FamilyMember] = []
        
        // Configure the operation
        operation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                let name = record["name"] as? String ?? "Unknown"
                let role = record["role"] as? String ?? "Member"
                let deviceID = record["deviceID"] as? String ?? ""
                
                let member = FamilyMember(
                    id: record.recordID.recordName,
                    name: name,
                    role: role,
                    deviceID: deviceID
                )
                fetchedMembers.append(member)
                
            case .failure(let error):
                print("Error fetching record: \(error)")
            }
        }
        
        operation.queryResultBlock = { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(_):
                    self.familyMembers = fetchedMembers
                case .failure(let error):
                    self.error = error
                }
            }
        }
        
        // Add the operation to the database
        container.privateCloudDatabase.add(operation)
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
        record["dateAdded"] = Date() as CKRecordValue
        
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
                        deviceID: self.userID,
                        isActive: true,
                        dateAdded: Date()
                    )
                    self.familyMembers.append(member)
                }
            }
        }
    }
    
    /// Remove a family member
    func removeFamilyMember(id: String) {
        // Find the member to remove
        guard let index = familyMembers.firstIndex(where: { $0.id == id }) else { return }
        
        // Remove from local array
        let member = familyMembers.remove(at: index)
        
        // Remove from CloudKit
        let recordID = CKRecord.ID(recordName: id)
        container.privateCloudDatabase.delete(withRecordID: recordID) { [weak self] (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error removing family member: \(error)")
                    // Add back to array if delete failed
                    self?.familyMembers.append(member)
                }
            }
        }
    }
}

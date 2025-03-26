//
//  CloudKitManager.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 17/03/2025.
//  Updated to fix Family Member registration
//

import Foundation
import CloudKit
import SwiftUI
import SwiftData
import UIKit  // Added for UIDevice access

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
    
    // Debug flag
    @Published var debugMessage: String = ""
    
    init(containerIdentifier: String = FamilyCarApp.containerIdentifier) {
        // Use container identifier from the app
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
            // Fixed dispatch pattern
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    self.isSignedIn = false
                    self.debugMessage = "Account status error: \(error.localizedDescription)"
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
                    self.debugMessage = "Account status: \(status.rawValue)"
                @unknown default:
                    self.isSignedIn = false
                    self.error = NSError(domain: "CloudKitManager",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Unknown iCloud account status"])
                    self.debugMessage = "Unknown account status"
                }
            }))
        }
    }
    
    /// Fetch the current user's record
    private func fetchUserRecord() {
        self.isLoading = true
        
        container.fetchUserRecordID { [weak self] recordID, error in
            // Fixed dispatch pattern
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    self.isLoading = false
                    self.debugMessage = "Failed to fetch user record: \(error.localizedDescription)"
                    return
                }
                
                if let id = recordID {
                    self.userID = id.recordName
                    self.fetchUserName(recordID: id)
                    self.debugMessage = "User ID: \(id.recordName)"
                } else {
                    self.isLoading = false
                    self.error = NSError(domain: "CloudKitManager",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Could not fetch user record ID"])
                    self.debugMessage = "No user record ID returned"
                }
            }))
        }
    }
    
    /// Fetch the current user's name using modern methods compatible with iOS 17+
    private func fetchUserName(recordID: CKRecord.ID) {
        // Set a default name immediately
        self.userName = "Family Member"
        self.debugMessage = "Retrieving user information..."
        
        // In iOS 17+, the recommended approach is to fetch user record directly
        // rather than using the deprecated discoverUserIdentity
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] (record, error) in
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                guard let self = self else { return }
                
                if let error = error {
                    self.debugMessage = "Error fetching user record: \(error.localizedDescription)"
                } else if let record = record {
                    // Try to extract user info from the record if available
                    if let firstName = record["firstName"] as? String,
                       let lastName = record["lastName"] as? String {
                        self.userName = "\(firstName) \(lastName)"
                    } else if let name = record["displayName"] as? String {
                        self.userName = name
                    } else if let email = record["email"] as? String {
                        self.userName = email.components(separatedBy: "@").first ?? "Family Member"
                    } else {
                        // If we can't get user info from CloudKit, try getting device name
                        let deviceName = UIDevice.current.name
                        if !deviceName.isEmpty && deviceName != "iPhone" && deviceName != "iPad" {
                            self.userName = "Owner of \(deviceName)"
                        }
                    }
                    
                    self.debugMessage = "Found user: \(self.userName)"
                }
                
                // Proceed to fetch family members regardless
                self.isLoading = false
                self.fetchFamilyMembers()
            }))
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
        self.debugMessage = "Fetching family members..."
        
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
            // Fixed dispatch pattern
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(_):
                    self.familyMembers = fetchedMembers
                    self.debugMessage = "Found \(fetchedMembers.count) family members"
                    
                    // If the current user isn't in the list yet, add them automatically
                    if !self.familyMembers.contains(where: { $0.deviceID == self.userID }) {
                        // Only if we have a valid user ID
                        if !self.userID.isEmpty {
                            self.addCurrentUserToFamily(role: "Owner")
                        }
                    }
                    
                case .failure(let error):
                    self.error = error
                    self.debugMessage = "Failed to fetch family members: \(error.localizedDescription)"
                    
                    // Try to create a direct user record if query failed
                    if !self.userID.isEmpty && self.familyMembers.isEmpty {
                        self.addCurrentUserToFamily(role: "Owner")
                    }
                }
            }))
        }
        
        // Add the operation to the database
        container.privateCloudDatabase.add(operation)
    }
    
    /// Add current user as a family member if not already added
    func addCurrentUserToFamily(role: String = "Owner") {
        guard !userID.isEmpty else {
            self.debugMessage = "Cannot add user - empty userID"
            return
        }
        
        // Check if user is already a family member
        if familyMembers.contains(where: { $0.deviceID == userID }) {
            self.debugMessage = "User is already a family member"
            // Still notify UI to refresh
            NotificationCenter.default.post(
                name: Notification.Name("FamilyMemberAdded"),
                object: nil
            )
            return
        }
        
        isLoading = true
        self.debugMessage = "Adding user as family member..."
        
        // Create new member immediately for local use
        let localMember = FamilyMember(
            id: UUID().uuidString,
            name: self.userName,
            role: role,
            deviceID: self.userID,
            isActive: true,
            dateAdded: Date()
        )
        
        // Add to local list immediately
        if !self.familyMembers.contains(where: { $0.deviceID == self.userID }) {
            self.familyMembers.append(localMember)
            self.debugMessage += " (added locally first)"
        }
        
        // Notify UI immediately that a member was added
        NotificationCenter.default.post(
            name: Notification.Name("FamilyMemberAdded"),
            object: nil
        )
        
        // Create CloudKit record
        let record = CKRecord(recordType: "FamilyMember")
        record["name"] = userName as CKRecordValue
        record["role"] = role as CKRecordValue
        record["deviceID"] = userID as CKRecordValue
        record["dateAdded"] = Date() as CKRecordValue
        
        // Save the record to CloudKit (but UI already updated)
        container.privateCloudDatabase.save(record) { [weak self] savedRecord, error in
            // Fixed dispatch pattern
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    self.debugMessage = "Failed to add user to CloudKit: \(error.localizedDescription)"
                    // No need to add locally again - already done above
                    return
                }
                
                if let record = savedRecord {
                    // Update the local member with the proper CloudKit ID
                    if let index = self.familyMembers.firstIndex(where: { $0.deviceID == self.userID }) {
                        self.familyMembers[index] = FamilyMember(
                            id: record.recordID.recordName,
                            name: self.userName,
                            role: role,
                            deviceID: self.userID,
                            isActive: true,
                            dateAdded: Date()
                        )
                    }
                    
                    self.debugMessage = "Successfully added user as family member to CloudKit"
                }
            }))
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
            // Fixed dispatch pattern
            DispatchQueue.main.async(execute: DispatchWorkItem(block: {
                if let error = error {
                    print("Error removing family member: \(error)")
                    // Add back to array if delete failed
                    self?.familyMembers.append(member)
                }
            }))
        }
    }
}

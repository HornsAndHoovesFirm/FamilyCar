//
//  CloudSyncHelper.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 18/03/2025.
//

import Foundation
import SwiftData
import CloudKit

/// Helper class for handling data synchronization and conflict resolution
class CloudSyncHelper: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private var modelContext: ModelContext?
    private let cloudKitManager: CloudKitManager
    
    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
        
        // Set up notification observers for CloudKit changes
        setupNotificationObservers()
    }
    
    /// Set the model context for this helper
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Set up notification observers for CloudKit changes
    private func setupNotificationObservers() {
        // Register for remote notification changes from CloudKit
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: NSNotification.Name.CKAccountChanged,
            object: nil
        )
    }
    
    /// Handle remote changes from CloudKit
    @objc private func handleRemoteChange() {
        DispatchQueue.main.async {
            // Refresh data when CloudKit notifies of changes
            self.syncData()
        }
    }
    
    /// Sync data with CloudKit
    func syncData() {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        // In a real implementation, this would handle the actual sync process
        // For now, we'll just simulate a sync delay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSyncing = false
            self.lastSyncDate = Date()
            
            // Notify the UI that sync has completed
            NotificationCenter.default.post(
                name: Notification.Name("CloudSyncCompleted"),
                object: nil
            )
        }
    }
    
    /// Handle conflict resolution
    func resolveConflicts(localItem: CarProfile, remoteItem: CarProfile) -> CarProfile {
        // This is a simple conflict resolution strategy
        // In a real app, you might implement more sophisticated strategies
        
        // For this example, we'll use a "latest wins" strategy
        // You could also merge the data or present a UI for user resolution
        
        // Check which item was modified more recently
        if let localModificationDate = getModificationDate(for: localItem),
           let remoteModificationDate = getModificationDate(for: remoteItem) {
            
            if localModificationDate > remoteModificationDate {
                return localItem // Local changes win
            } else {
                return remoteItem // Remote changes win
            }
        }
        
        // Default to remote changes if we can't determine
        return remoteItem
    }
    
    /// Get the modification date for a CarProfile
    private func getModificationDate(for item: CarProfile) -> Date? {
        // In a real app, you would track modification dates in your model
        // For now, we'll just return the current date
        return Date()
    }
}

// MARK: - SwiftData Extension for CloudKit Support
extension ModelContext {
    /// Save changes and sync to CloudKit
    func saveAndSync() throws {
        try save()
        
        // Notify CloudKit to sync changes
        // This is a simplified version - in a real app, you would implement
        // proper CloudKit record syncing here
        NotificationCenter.default.post(
            name: Notification.Name("ModelContextDidSave"),
            object: nil
        )
    }
}

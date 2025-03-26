//
//  ContentView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 12/03/2025.
//  Updated for CloudKit integration on 17/03/2025.
//  Updated to fix Family Member registration on 23/03/2025.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var selectedTab = 0
    @State private var showingSyncStatus = false
    @State private var showDebugInfo = false
    
    var body: some View {
        Group {
            if !cloudKitManager.isSignedIn {
                // Show sign-in view if not signed in
                CloudKitSignInView()
            } else {
                // Main app content
                TabView(selection: $selectedTab) {
                    // Cars tab
                    NavigationStack {
                        CarListView()
                    }
                    .tabItem {
                        Label("Cars", systemImage: "car.fill")
                    }
                    .tag(0)
                    
                    // Family tab
                    NavigationStack {
                        FamilyMembersView()
                    }
                    .tabItem {
                        Label("Family", systemImage: "person.3.fill")
                    }
                    .tag(1)
                    
                    // Settings tab
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(2)
                }
                .overlay(
                    // Show cloud sync status when active
                    VStack {
                        if showingSyncStatus {
                            VStack {
                                Spacer()
                                
                                HStack {
                                    Image(systemName: "icloud.and.arrow.up.fill")
                                    Text("Syncing with iCloud...")
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                                .padding(.bottom, 60) // Above tab bar
                            }
                            .transition(.move(edge: .bottom))
                        }
                        
                        // Debug information overlay
                        if showDebugInfo {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Debug Info:")
                                    .font(.headline)
                                
                                Text("User ID: \(cloudKitManager.userID)")
                                    .font(.caption)
                                
                                Text("User Name: \(cloudKitManager.userName)")
                                    .font(.caption)
                                
                                Text("Family Members: \(cloudKitManager.familyMembers.count)")
                                    .font(.caption)
                                
                                Text("Is Member: \(cloudKitManager.familyMembers.contains(where: { $0.deviceID == cloudKitManager.userID }) ? "Yes" : "No")")
                                    .font(.caption)
                                
                                if !cloudKitManager.debugMessage.isEmpty {
                                    Text("Status: \(cloudKitManager.debugMessage)")
                                        .font(.caption)
                                }
                                
                                Button("Add Self as Owner") {
                                    cloudKitManager.addCurrentUserToFamily(role: "Owner")
                                }
                                .padding(.vertical, 5)
                                
                                Button("Refresh Members") {
                                    cloudKitManager.fetchFamilyMembers()
                                }
                                .padding(.vertical, 5)
                                
                                Button("Hide Debug") {
                                    showDebugInfo = false
                                }
                                .padding(.vertical, 5)
                            }
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .animation(.easeInOut, value: showingSyncStatus)
                )
                .onAppear {
                    // If user has no record as family member, add them automatically
                    if cloudKitManager.familyMembers.isEmpty {
                        cloudKitManager.addCurrentUserToFamily(role: "Owner")
                    }
                }
                .onTapGesture(count: 3) {
                    // Triple tap anywhere to show debug info
                    showDebugInfo = true
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloudSyncStarted"))) { _ in
                    showingSyncStatus = true
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloudSyncCompleted"))) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSyncStatus = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FamilyMemberAdded"))) { _ in
                    // Show brief confirmation of member addition
                    withAnimation {
                        showingSyncStatus = true
                    }
                    
                    // Hide after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSyncStatus = false
                        }
                    }
                }
            }
        }
    }
}

// Settings View
struct SettingsView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var showingSignOutAlert = false
    @State private var showingSyncAlert = false
    @State private var showDebugInfo = false
    
    var body: some View {
        List {
            Section(header: Text("iCloud Account")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(cloudKitManager.userName)
                            .font(.headline)
                        Text("Signed in with iCloud")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack {
                        Text("Sign Out")
                        Spacer()
                        Image(systemName: "arrow.right.square")
                    }
                    .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Data Sync")) {
                HStack {
                    Text("iCloud Sync")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    showingSyncAlert = true
                }) {
                    HStack {
                        Text("Sync Now")
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            
            Section(header: Text("Family Sharing")) {
                NavigationLink {
                    FamilyMembersView()
                } label: {
                    HStack {
                        Text("Family Members")
                        Spacer()
                        Text("\(cloudKitManager.familyMembers.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Add direct "Add me" button for emergency purposes
                Button(action: {
                    cloudKitManager.addCurrentUserToFamily(role: "Owner")
                }) {
                    Label("Register as Family Owner", systemImage: "person.badge.plus")
                }
                .foregroundColor(.blue)
            }
            
            Section(header: Text("About")) {
                LabeledContent("App Version", value: "1.0.0")
                LabeledContent("Database", value: "CloudKit")
                
                // Debug toggle
                Button(action: {
                    showDebugInfo.toggle()
                }) {
                    Label(showDebugInfo ? "Hide Debug Info" : "Show Debug Info",
                          systemImage: showDebugInfo ? "bug.fill" : "bug")
                }
            }
            
            if showDebugInfo {
                Section(header: Text("Debug Information")) {
                    LabeledContent("User ID", value: cloudKitManager.userID)
                    LabeledContent("User Name", value: cloudKitManager.userName)
                    LabeledContent("Family Members", value: "\(cloudKitManager.familyMembers.count)")
                    LabeledContent("Is Member", value: cloudKitManager.familyMembers.contains(where: { $0.deviceID == cloudKitManager.userID }) ? "Yes" : "No")
                    
                    if !cloudKitManager.debugMessage.isEmpty {
                        Text("Status: \(cloudKitManager.debugMessage)")
                            .font(.caption)
                    }
                    
                    Button("Force Add as Owner") {
                        cloudKitManager.addCurrentUserToFamily(role: "Owner")
                    }
                    .foregroundColor(.blue)
                    
                    Button("Refresh Member List") {
                        cloudKitManager.fetchFamilyMembers()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                // In a real app, you would handle sign out here
                // For now, we just check status again
                cloudKitManager.isSignedIn = false
            }
        } message: {
            Text("Are you sure you want to sign out? Your data will remain in iCloud.")
        }
        .alert("Sync Data", isPresented: $showingSyncAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sync", role: .none) {
                // Trigger manual sync
                NotificationCenter.default.post(name: Notification.Name("CloudSyncStarted"), object: nil)
                
                cloudKitManager.fetchFamilyMembers()
                
                // Simulate sync completion after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    NotificationCenter.default.post(name: Notification.Name("CloudSyncCompleted"), object: nil)
                }
            }
        } message: {
            Text("This will sync your data with iCloud. Any changes made by family members will be downloaded.")
        }
    }
}

// Preview
#Preview {
    TabView {
        CarListPreview()
            .tabItem {
                Label("Cars", systemImage: "car.fill")
            }
        
        NavigationStack {
            FamilyMembersPreview()
        }
        .tabItem {
            Label("Family", systemImage: "person.3.fill")
        }
        
        NavigationStack {
            List {
                Section(header: Text("iCloud Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Preview User")
                                .font(.headline)
                            Text("Signed in with iCloud")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    LabeledContent("App Version", value: "1.0.0")
                    LabeledContent("Database", value: "CloudKit")
                }
            }
            .navigationTitle("Settings")
        }
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
    }
}

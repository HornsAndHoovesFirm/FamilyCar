//
//  ContentView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 12/03/2025.
//  Updated for CloudKit integration on 17/03/2025.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var selectedTab = 0
    @State private var showingSyncStatus = false
    
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
                    Group {
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
                    }
                    .animation(.easeInOut, value: showingSyncStatus)
                )
                .onAppear {
                    // If user has no record as family member, add them automatically
                    if cloudKitManager.familyMembers.isEmpty {
                        cloudKitManager.addCurrentUserToFamily(role: "Owner")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloudSyncStarted"))) { _ in
                    showingSyncStatus = true
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloudSyncCompleted"))) { _ in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSyncStatus = false
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
            }
            
            Section(header: Text("About")) {
                LabeledContent("App Version", value: "1.0.0")
                LabeledContent("Database", value: "CloudKit")
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

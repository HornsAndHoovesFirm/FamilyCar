//
//  FamilyMemberView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 18/03/2025.
//

import SwiftUI
import CloudKit

struct FamilyMembersView: View {
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    @State private var showingAddMember = false
    @State private var newMemberName = ""
    @State private var newMemberRole = "Member"
    @State private var isInviting = false
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var selectedMember: FamilyMember?
    @State private var showingMemberOptions = false
    
    let roles = ["Owner", "Admin", "Member", "Viewer"]
    
    var body: some View {
        List {
            // User's information section
            Section(header: Text("Your Information")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(cloudKitManager.userName)
                            .font(.headline)
                        
                        if let userMember = cloudKitManager.familyMembers.first(where: { $0.deviceID == cloudKitManager.userID }) {
                            Text(userMember.role)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not registered as family member")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    Text("You")
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                }
            }
            
            // Family members section
            Section(header: Text("Family Members")) {
                if cloudKitManager.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading members...")
                        Spacer()
                    }
                } else if cloudKitManager.familyMembers.isEmpty {
                    Text("No family members added yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(cloudKitManager.familyMembers) { member in
                        if member.deviceID != cloudKitManager.userID {
                            Button(action: {
                                selectedMember = member
                                showingMemberOptions = true
                            }) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                    
                                    VStack(alignment: .leading) {
                                        Text(member.name)
                                            .font(.headline)
                                        Text(member.role)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            // Actions section
            Section {
                Button(action: {
                    showingAddMember = true
                }) {
                    Label("Invite Family Member", systemImage: "person.badge.plus")
                }
                
                if !cloudKitManager.familyMembers.contains(where: { $0.deviceID == cloudKitManager.userID }) {
                    Button(action: {
                        // Add the current user as a family member if not already added
                        cloudKitManager.addCurrentUserToFamily(role: "Owner")
                    }) {
                        Label("Add Yourself as Owner", systemImage: "person.fill.checkmark")
                    }
                }
                
                Button(action: {
                    cloudKitManager.fetchFamilyMembers()
                }) {
                    Label("Refresh Member List", systemImage: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("Family Members")
        .overlay(
            Group {
                if cloudKitManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                }
            }
        )
        .sheet(isPresented: $showingAddMember) {
            NavigationStack {
                // Member invitation form
                Form {
                    Section(header: Text("Invite New Member")) {
                        TextField("Family Member Name", text: $newMemberName)
                            .autocorrectionDisabled()
                        
                        Picker("Role", selection: $newMemberRole) {
                            ForEach(roles, id: \.self) { role in
                                Text(role).tag(role)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Role Permissions:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let selectedRole = FamilyRole(rawValue: newMemberRole) {
                                let permissions = selectedRole.permissions
                                
                                Text("• \(permissions.canAddCar ? "Can" : "Cannot") add cars")
                                    .font(.caption)
                                Text("• \(permissions.canEditCar ? "Can" : "Cannot") edit cars")
                                    .font(.caption)
                                Text("• \(permissions.canDeleteCar ? "Can" : "Cannot") delete cars")
                                    .font(.caption)
                                Text("• \(permissions.canAddMembers ? "Can" : "Cannot") add family members")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    Section {
                        Button(action: inviteFamilyMember) {
                            if isInviting {
                                ProgressView()
                            } else {
                                Text("Generate Invitation Link")
                            }
                        }
                        .disabled(newMemberName.isEmpty || isInviting)
                    }
                }
                .navigationTitle("Add Family Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddMember = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .confirmationDialog(
            "Family Member Options",
            isPresented: $showingMemberOptions,
            presenting: selectedMember
        ) { member in
            Button("View Details") {
                // View member details (could navigate to detail view)
                print("View details for \(member.name)")
            }
            
            // Only offer remove option if user has appropriate permissions
            if let userRole = cloudKitManager.familyMembers.first(where: { $0.deviceID == cloudKitManager.userID })?.role,
               let role = FamilyRole(rawValue: userRole),
               role.permissions.canRemoveMembers {
                
                Button("Remove from Family", role: .destructive) {
                    // Remove member logic would go here
                    print("Remove \(member.name) from family")
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: { member in
            Text("Select an action for \(member.name)")
        }
        .onAppear {
            cloudKitManager.fetchFamilyMembers()
        }
        .refreshable {
            cloudKitManager.fetchFamilyMembers()
        }
    }
    
    func inviteFamilyMember() {
        isInviting = true
        
        // Generate a unique invitation code
        let inviteCode = UUID().uuidString
        
        // Create a URL with the invitation code
        // This URL would be handled by your app's universal link setup
        shareURL = URL(string: "https://yourapp.com/invite?code=\(inviteCode)&name=\(newMemberName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&role=\(newMemberRole.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        
        // In a real app, you would save this invitation in CloudKit
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isInviting = false
            showShareSheet = true
            
            // Reset form
            newMemberName = ""
            newMemberRole = "Member"
        }
    }
}

// ShareSheet to display iOS share options
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        FamilyMembersView()
            .environmentObject(CloudKitManager())
    }
}

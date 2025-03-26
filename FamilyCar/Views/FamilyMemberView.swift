//
//  FamilyMembersView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 18/03/2025.
//  Updated to fix Family Member registration on 23/03/2025.
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
    @State private var showingAddSelfAlert = false
    @State private var registeringAsSelf = false
    
    // Error handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    let roles = ["Owner", "Admin", "Member", "Viewer"]
    
    var isCurrentUserMember: Bool {
        cloudKitManager.familyMembers.contains { $0.deviceID == cloudKitManager.userID }
    }
    
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
                    
                    if isCurrentUserMember {
                        Text("You")
                            .font(.caption)
                            .padding(5)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(5)
                    } else {
                        Button("Register") {
                            showingAddSelfAlert = true
                        }
                        .font(.caption)
                        .padding(5)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(5)
                    }
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
                } else if cloudKitManager.familyMembers.filter({ $0.deviceID != cloudKitManager.userID }).isEmpty {
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
                
                if !isCurrentUserMember {
                    Button(action: {
                        showingAddSelfAlert = true
                    }) {
                        Label("Register as Family Owner", systemImage: "person.fill.checkmark")
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: {
                    cloudKitManager.fetchFamilyMembers()
                }) {
                    Label("Refresh Member List", systemImage: "arrow.clockwise")
                }
            }
            
            // Manual registration section if not already a member
            if !isCurrentUserMember {
                Section(header: Text("Manual Registration")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("You need to register yourself as a family member to use all features.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            registeringAsSelf = true
                            registerSelfAsOwner()
                        }) {
                            if registeringAsSelf {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 5)
                                    Text("Registering...")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            } else {
                                Text("Register Myself as Owner")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(registeringAsSelf)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Family Members")
        .overlay(
            Group {
                if cloudKitManager.isLoading && !registeringAsSelf {
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
                // View member details (could navigate to detail view in future)
                print("View details for \(member.name)")
            }
            
            // Only offer remove option if user has appropriate permissions
            if let userRole = cloudKitManager.familyMembers.first(where: { $0.deviceID == cloudKitManager.userID })?.role,
               let role = FamilyRole(rawValue: userRole),
               role.permissions.canRemoveMembers {
                
                Button("Remove from Family", role: .destructive) {
                    cloudKitManager.removeFamilyMember(id: member.id)
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: { member in
            Text("Select an action for \(member.name)")
        }
        .alert("Register as Family Owner", isPresented: $showingAddSelfAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Register", role: .none) {
                registerSelfAsOwner()
            }
        } message: {
            Text("This will register you as the Family Owner with full access to all app features. Continue?")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            cloudKitManager.fetchFamilyMembers()
        }
        .refreshable {
            cloudKitManager.fetchFamilyMembers()
        }
    }
    
    // Function to register self as owner
    private func registerSelfAsOwner() {
        registeringAsSelf = true
        
        // Ensure we have a user ID
        guard !cloudKitManager.userID.isEmpty else {
            registeringAsSelf = false
            errorMessage = "Unable to register: No user ID available. Please check your iCloud status in Settings."
            showError = true
            return
        }
        
        // Add self as owner
        cloudKitManager.addCurrentUserToFamily(role: "Owner")
        
        // Delay to allow operation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            registeringAsSelf = false
            
            // Check if registration was successful
            if cloudKitManager.familyMembers.contains(where: { $0.deviceID == cloudKitManager.userID }) {
                // Success - no need to do anything as UI will update
            } else {
                // Show error if still not registered
                errorMessage = "Registration failed. Please try again or check the Settings tab for additional options."
                showError = true
            }
        }
    }
    
    func inviteFamilyMember() {
        isInviting = true
        
        // First check if current user is a member
        if !isCurrentUserMember {
            isInviting = false
            errorMessage = "You need to register yourself as a family member before inviting others."
            showError = true
            return
        }
        
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

// Preview
#Preview {
    NavigationStack {
        FamilyMembersView()
            .environmentObject(DirectPreviewSamples.cloudKitManager)
    }
}

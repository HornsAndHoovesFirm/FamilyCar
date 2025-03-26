//
//  CarDetailView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 14/03/2025.
//

import SwiftUI
import SwiftData
import QuickLook

struct CarDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    
    @Bindable var car: CarProfile
    @State private var isEditMode = false
    @State private var documentPreviewURL: URL?
    @State private var showDocumentPreview = false
    @State private var showDeleteAlert = false
    @StateObject private var documentManager = DocumentManager()
    
    var body: some View {
        List {
            // Basic Information Section
            Section("Basic Information") {
                LabeledContent("Make", value: car.make)
                LabeledContent("Model", value: car.model)
                LabeledContent("Year", value: "\(String(car.year))")
                LabeledContent("License Plate", value: car.licensePlate)
                if let nickname = car.nickname {
                    LabeledContent("Nickname", value: nickname)
                }
                LabeledContent("Color", value: car.color)
            }
            
            // Technical Details Section
            Section("Technical Details") {
                LabeledContent("VIN", value: car.vin)
                LabeledContent("Fuel Type", value: car.fuelType.rawValue.capitalized)
                LabeledContent("Engine Size", value: car.engineSize)
                LabeledContent("Transmission", value: car.transmissionType.displayName)
            }
            
            // Ownership Information Section
            Section("Ownership Information") {
                LabeledContent("Purchase Date", value: car.purchaseDate.formatted(date: .long, time: .omitted))
                LabeledContent("First Road Date", value: car.firstRoadDate.formatted(date: .long, time: .omitted))
            }
            
            // Documents Section
            Section("Documents") {
                if let document = car.licenseDocument {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.fileName)
                            .font(.subheadline)
                        
                        Text("Uploaded: \(document.uploadDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    HStack {
                        Button {
                            if let tempURL = documentManager.createTemporaryFileForPreview(document: document) {
                                documentPreviewURL = tempURL
                                showDocumentPreview = true
                            }
                        } label: {
                            Label("View Document", systemImage: "eye")
                        }
                        
                        Spacer()
                        
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    NavigationLink {
                        DocumentPickerView(car: car)
                    } label: {
                        Label("Add License Document", systemImage: "doc.badge.plus")
                    }
                }
            }
            
            // Actions Section
            Section {
                Button(action: { isEditMode = true }) {
                    Label("Edit Car Details", systemImage: "pencil")
                }
            }
        }
        .navigationTitle("\(String(car.year)) \(car.make) \(car.model)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isEditMode = true }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isEditMode) {
            CarFormView(car: car)
        }
        .quickLookPreview($documentPreviewURL)
        .alert("Delete Document", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete the document
                documentManager.deleteDocument(from: car, in: modelContext)
                
                // Clean up preview URL if needed
                if let url = documentPreviewURL {
                    try? FileManager.default.removeItem(at: url)
                    documentPreviewURL = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete the license document? This action cannot be undone.")
        }
        .onDisappear {
            // Clean up any temporary files when view disappears
            if let url = documentPreviewURL {
                try? FileManager.default.removeItem(at: url)
                documentPreviewURL = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        CarDetailPreview()
    }
}

//
//  DocumentPickerView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 15/03/2025.
//

import SwiftUI
import SwiftData
//import UniformTypeIdentifiers
import QuickLook

struct DocumentPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var car: CarProfile
    @State private var showDocumentPicker = false
//    @State private var selectedDocumentURL: URL?
    @State private var documentPreviewURL: URL?
    @State private var showPreview = false
    
    // Reference to DocumentManager for handling document operations
    @StateObject private var documentManager = DocumentManager()

    var body: some View {
        List {
            Section("Current Document") {
                if let document = car.licenseDocument {
                    VStack(alignment: .leading) {
                        Text(document.fileName)
                            .font(.headline)
                        Text("Uploaded: \(document.uploadDate.formatted())")
                            .font(.caption)
                    }
                    
                    Button("View Document") {
                        documentPreviewURL = documentManager.createTemporaryFileForPreview(
                            document: document
                        )
                        showPreview = true
                    }
                    
                    Button("Delete Document", role: .destructive) {
                        documentManager.deleteDocument(from: car, in: modelContext)
                    }
                } else {
                    Text("No document attached")
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Select Document") {
                showDocumentPicker = true
            }
        }
        .navigationTitle("Car Documents")
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerRepresentable(
                onDocumentPicked: { url in
                    documentManager.loadDocument(from: url, for: car, in: modelContext)
                }
            )
        }
        .quickLookPreview($documentPreviewURL)
    }
}

#Preview {
    NavigationStack {
        DocumentPickerView(car: CarProfile.sampleCarWithDocument())
    }
    .modelContainer(ModelContainer.previewContainer())
}

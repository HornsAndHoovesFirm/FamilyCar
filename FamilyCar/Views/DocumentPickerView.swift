//
//  DocumentPickerView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 15/03/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import QuickLook

struct DocumentPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var car: CarProfile
    @State private var showDocumentPicker = false
    @State private var documentPreviewURL: URL?
    @State private var showPreview = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Reference to DocumentManager for handling document operations
    @StateObject private var documentManager = DocumentManager()

    var body: some View {
        List {
            Section("Current Document") {
                if let document = car.licenseDocument {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(document.fileName)
                            .font(.headline)
                        Text("Uploaded: \(document.uploadDate.formatted(date: .long, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        documentPreviewURL = documentManager.createTemporaryFileForPreview(
                            document: document
                        )
                        if documentPreviewURL != nil {
                            showPreview = true
                        } else {
                            alertMessage = "Could not create preview file for the document."
                            showAlert = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "eye")
                            Text("View Document")
                        }
                    }
                    
                    Button(role: .destructive) {
                        documentManager.deleteDocument(from: car, in: modelContext)
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Document")
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "doc.fill.badge.plus")
                            .foregroundColor(.secondary)
                        Text("No document attached")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                Button {
                    showDocumentPicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text(car.licenseDocument == nil ? "Add Document" : "Replace Document")
                    }
                }
            }
        }
        .navigationTitle("Car Documents")
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerRepresentable { url in
                do {
                    try documentManager.loadDocument(from: url, for: car, in: modelContext)
                } catch {
                    alertMessage = "Error loading document: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
        .quickLookPreview($documentPreviewURL)
        .alert("Document Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// UIViewControllerRepresentable for document picker
struct DocumentPickerRepresentable: UIViewControllerRepresentable {
    var onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerRepresentable
        
        init(_ parent: DocumentPickerRepresentable) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

// Preview
#Preview {
    NavigationStack {
        DocumentPickerPreview()
    }
}

//
//  DocumentManager.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 15/03/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Document Manager
class DocumentManager: ObservableObject {
    
    /// Creates a temporary file for previewing a document and returns its URL
    func createTemporaryFileForPreview(document: CarDocument) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        do {
            try document.documentData.write(to: tempURL)
            return tempURL
        } catch {
            print("Error creating temporary file: \(error)")
            return nil
        }
    }
    
    /// Deletes a document from a car profile
    func deleteDocument(from car: CarProfile, in modelContext: ModelContext) {
        if let doc = car.licenseDocument {
            modelContext.delete(doc)
            car.licenseDocument = nil
            try? modelContext.save()
        }
    }
    
    /// Loads a document from a URL and attaches it to a car profile
    func loadDocument(from url: URL, for car: CarProfile, in modelContext: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else {
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let documentData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            // Delete existing document if there is one
            if let existingDocument = car.licenseDocument {
                modelContext.delete(existingDocument)
            }
            
            // Create new document
            let newDocument = CarDocument(
                fileName: fileName,
                documentData: documentData
            )
            
            car.licenseDocument = newDocument
            try modelContext.save()
            
        } catch {
            print("Error loading document: \(error)")
        }
    }
}

// MARK: - Document Picker Representable
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

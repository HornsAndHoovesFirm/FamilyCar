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
    @State private var selectedDocumentURL: URL?
    @State private var documentPreviewURL: URL?
    @State private var showPreview = false
    
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
                        // Create a temporary file to preview
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
                        try? document.documentData.write(to: tempURL)
                        documentPreviewURL = tempURL
                        showPreview = true
                    }
                    
                    Button("Delete Document", role: .destructive) {
                        if let doc = car.licenseDocument {
                            modelContext.delete(doc)
                            car.licenseDocument = nil
                            try? modelContext.save()
                        }
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
            DocumentPicker(selectedURL: $selectedDocumentURL)
        }
        .onChange(of: selectedDocumentURL) { _, newURL in
            if let url = newURL {
                loadDocument(from: url)
            }
        }
        .quickLookPreview($documentPreviewURL)
    }
    
    private func loadDocument(from url: URL) {
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

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    
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
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedURL = url
        }
    }
}

#Preview {
    NavigationStack {
        DocumentPickerView(car: CarProfile.sampleCarWithDocument())
    }
    .modelContainer(ModelContainer.previewContainer())
}

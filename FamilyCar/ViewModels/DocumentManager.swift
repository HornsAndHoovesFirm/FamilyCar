//
//  DocumentManager.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 15/03/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Document Manager Errors
enum DocumentManagerError: Error, LocalizedError {
    case accessDenied
    case fileReadError
    case invalidFileType
    case saveError
    case createTempFileError
    case fileTooLarge(Int)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to the document was denied."
        case .fileReadError:
            return "Could not read the document data."
        case .invalidFileType:
            return "The selected file is not a valid PDF."
        case .saveError:
            return "Failed to save the document to the database."
        case .createTempFileError:
            return "Failed to create a temporary file for preview."
        case .fileTooLarge(let size):
            let sizeInMB = Double(size) / 1_048_576.0
            return "File size (\(String(format: "%.1f", sizeInMB)) MB) exceeds the maximum allowed size of 10 MB."
        }
    }
}

// MARK: - Document Manager
class DocumentManager: ObservableObject {
    // Maximum file size (10 MB)
    private let maxFileSize = 10 * 1_048_576
    
    /// Creates a temporary file for previewing a document and returns its URL
    func createTemporaryFileForPreview(document: CarDocument) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(document.fileName.pathExtension)
        
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
        guard let doc = car.licenseDocument else { return }
        
        // First remove the reference from the car
        car.licenseDocument = nil
        
        // Then delete the document entity
        modelContext.delete(doc)
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error deleting document: \(error)")
            // If save fails, restore the reference
            car.licenseDocument = doc
        }
    }
    
    /// Loads a document from a URL and attaches it to a car profile
    func loadDocument(from url: URL, for car: CarProfile, in modelContext: ModelContext) throws {
        // Verify we can access the file
        guard url.startAccessingSecurityScopedResource() else {
            throw DocumentManagerError.accessDenied
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Validate file type
        guard url.pathExtension.lowercased() == "pdf" else {
            throw DocumentManagerError.invalidFileType
        }
        
        do {
            // Get attributes to check file size
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int, fileSize > maxFileSize {
                throw DocumentManagerError.fileTooLarge(fileSize)
            }
            
            // Read the document data
            let documentData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            // Delete existing document if there is one
            if let existingDocument = car.licenseDocument {
                modelContext.delete(existingDocument)
            }
            
            // Create new document
            let newDocument = CarDocument(
                fileName: fileName,
                documentData: documentData,
                uploadDate: Date()
            )
            
            // Attach document to car
            car.licenseDocument = newDocument
            
            // Save changes
            try modelContext.save()
            
        } catch let error as DocumentManagerError {
            throw error
        } catch {
            print("Error loading document: \(error)")
            throw DocumentManagerError.fileReadError
        }
    }
}

// Extension to get file extension more safely
extension String {
    var pathExtension: String {
        (self as NSString).pathExtension.lowercased()
    }
}

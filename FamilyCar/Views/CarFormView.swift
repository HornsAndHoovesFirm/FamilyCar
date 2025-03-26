//
//  CarFormView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 14/03/2025.
//

import SwiftUI
import SwiftData

struct CarFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var cloudKitManager: CloudKitManager
    
    // If nil, we're creating a new car; otherwise, we're editing
    var existingCar: CarProfile?
    
    @State private var newlyCreatedCar: CarProfile?
    @State private var showDocumentPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasChanges = false
    @State private var showCancelAlert = false
    
    // Basic Information
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = Calendar.current.component(.year, from: Date())
    @State private var licensePlate: String = ""
    @State private var nickname: String = ""
    @State private var color: String = ""
    
    // Technical Details
    @State private var vin: String = ""
    @State private var fuelType: FuelType = .gasoline
    @State private var engineSize: String = ""
    @State private var transmissionType: TransmissionType = .automatic
    
    // Ownership Information
    @State private var purchaseDate: Date = Date()
    @State private var firstRoadDate: Date = Date()
    
    // Document attachment step
    @State private var showingDocumentStep = false
    
    // For form validation
    @State private var makeError: String?
    @State private var modelError: String?
    @State private var licensePlateError: String?
    @State private var vinError: String?
    
    init(car: CarProfile? = nil) {
        self.existingCar = car
        
        if let car = car {
            // Initialize with existing car values
            _make = State(initialValue: car.make)
            _model = State(initialValue: car.model)
            _year = State(initialValue: car.year)
            _licensePlate = State(initialValue: car.licensePlate)
            _nickname = State(initialValue: car.nickname ?? "")
            _color = State(initialValue: car.color)
            
            _vin = State(initialValue: car.vin)
            _fuelType = State(initialValue: car.fuelType)
            _engineSize = State(initialValue: car.engineSize)
            _transmissionType = State(initialValue: car.transmissionType)
            
            _purchaseDate = State(initialValue: car.purchaseDate)
            _firstRoadDate = State(initialValue: car.firstRoadDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            if showingDocumentStep, let car = newlyCreatedCar ?? existingCar {
                // Document attachment view
                DocumentPickerView(car: car)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
                    .navigationTitle("Add License Document")
            } else {
                // Car information form
                Form {
                    Section(header: Text("Basic Information")) {
                        VStack(alignment: .leading) {
                            TextField("Make", text: $make)
                                .onChange(of: make) { _, _ in
                                    validateMake()
                                    hasChanges = true
                                }
                            
                            if let error = makeError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            TextField("Model", text: $model)
                                .onChange(of: model) { _, _ in
                                    validateModel()
                                    hasChanges = true
                                }
                            
                            if let error = modelError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Stepper("Year: \(String(year))", value: $year, in: 1900...Calendar.current.component(.year, from: Date()) + 1)
                            .onChange(of: year) { _, _ in
                                hasChanges = true
                            }
                        
                        VStack(alignment: .leading) {
                            TextField("License Plate", text: $licensePlate)
                                .onChange(of: licensePlate) { _, _ in
                                    validateLicensePlate()
                                    hasChanges = true
                                }
                            
                            if let error = licensePlateError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        TextField("Nickname (Optional)", text: $nickname)
                            .onChange(of: nickname) { _, _ in
                                hasChanges = true
                            }
                        
                        TextField("Color", text: $color)
                            .onChange(of: color) { _, _ in
                                hasChanges = true
                            }
                    }
                    
                    Section(header: Text("Technical Details")) {
                        VStack(alignment: .leading) {
                            TextField("VIN", text: $vin)
                                .onChange(of: vin) { _, _ in
                                    validateVIN()
                                    hasChanges = true
                                }
                                .textInputAutocapitalization(.characters)
                                .disableAutocorrection(true)
                            
                            if let error = vinError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Picker("Fuel Type", selection: $fuelType) {
                            ForEach(FuelType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: fuelType) { _, _ in
                            hasChanges = true
                        }
                        
                        TextField("Engine Size", text: $engineSize)
                            .onChange(of: engineSize) { _, _ in
                                hasChanges = true
                            }
                        
                        Picker("Transmission", selection: $transmissionType) {
                            ForEach(TransmissionType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: transmissionType) { _, _ in
                            hasChanges = true
                        }
                    }
                    
                    Section(header: Text("Ownership Information")) {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                            .onChange(of: purchaseDate) { _, _ in
                                hasChanges = true
                            }
                        
                        DatePicker("First Road Date", selection: $firstRoadDate, displayedComponents: .date)
                            .onChange(of: firstRoadDate) { _, _ in
                                hasChanges = true
                            }
                    }
                    
                    // For existing cars, show documents section
                    if let car = existingCar {
                        Section("Documents") {
                            NavigationLink {
                                DocumentPickerView(car: car)
                            } label: {
                                HStack {
                                    Text("License Document")
                                    Spacer()
                                    if car.licenseDocument != nil {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    } else {
                                        Text("None")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(existingCar == nil ? "Add Car" : "Edit Car")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            if hasChanges {
                                showCancelAlert = true
                            } else {
                                dismiss()
                            }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(existingCar == nil ? "Save" : "Update") {
                            if validateForm() {
                                let car = saveCarProfile()
                                
                                if existingCar == nil {
                                    // If creating a new car, proceed to document step
                                    newlyCreatedCar = car
                                    showingDocumentStep = true
                                } else {
                                    // If editing, just dismiss
                                    // Notify about changes to sync with CloudKit if enabled
                                    NotificationCenter.default.post(
                                        name: Notification.Name("CloudSyncStarted"),
                                        object: nil
                                    )
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        NotificationCenter.default.post(
                                            name: Notification.Name("CloudSyncCompleted"),
                                            object: nil
                                        )
                                    }
                                    
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!isFormValid)
                    }
                }
                .alert("Unsaved Changes", isPresented: $showCancelAlert) {
                    Button("Discard", role: .destructive) {
                        dismiss()
                    }
                    Button("Keep Editing", role: .cancel) { }
                } message: {
                    Text("You have unsaved changes. Are you sure you want to discard them?")
                }
                .alert("Form Error", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !make.isEmpty && !model.isEmpty && !licensePlate.isEmpty &&
               !color.isEmpty && !vin.isEmpty && !engineSize.isEmpty &&
               makeError == nil && modelError == nil &&
               licensePlateError == nil && vinError == nil
    }
    
    private func validateForm() -> Bool {
        validateMake()
        validateModel()
        validateLicensePlate()
        validateVIN()
        
        // Check for any validation errors
        if makeError != nil || modelError != nil ||
           licensePlateError != nil || vinError != nil {
            alertMessage = "Please correct the errors in the form before saving."
            showAlert = true
            return false
        }
        
        return true
    }
    
    private func validateMake() {
        if make.isEmpty {
            makeError = "Make is required"
        } else if make.count < 2 {
            makeError = "Make must be at least 2 characters"
        } else {
            makeError = nil
        }
    }
    
    private func validateModel() {
        if model.isEmpty {
            modelError = "Model is required"
        } else if model.count < 2 {
            modelError = "Model must be at least 2 characters"
        } else {
            modelError = nil
        }
    }
    
    private func validateLicensePlate() {
        if licensePlate.isEmpty {
            licensePlateError = "License plate is required"
        } else if licensePlate.count < 3 {
            licensePlateError = "License plate must be at least 3 characters"
        } else {
            licensePlateError = nil
        }
    }
    
    private func validateVIN() {
        if vin.isEmpty {
            vinError = "VIN is required"
        } else if vin.count < 8 {
            vinError = "VIN must be at least 8 characters"
        } else {
            vinError = nil
        }
    }
    
    private func saveCarProfile() -> CarProfile {
        if let car = existingCar {
            // Update existing car
            car.make = make
            car.model = model
            car.year = year
            car.licensePlate = licensePlate
            car.nickname = nickname.isEmpty ? nil : nickname
            car.color = color
            car.vin = vin.uppercased() // Ensure VIN is uppercase
            car.fuelType = fuelType
            car.engineSize = engineSize
            car.transmissionType = transmissionType
            car.purchaseDate = purchaseDate
            car.firstRoadDate = firstRoadDate
            
            try? modelContext.save()
            return car
        } else {
            // Create new car
            let newCar = CarProfile(
                make: make,
                model: model,
                year: year,
                licensePlate: licensePlate,
                nickname: nickname.isEmpty ? nil : nickname,
                color: color,
                vin: vin.uppercased(), // Ensure VIN is uppercase
                fuelType: fuelType,
                engineSize: engineSize,
                transmissionType: transmissionType,
                purchaseDate: purchaseDate,
                firstRoadDate: firstRoadDate
            )
            modelContext.insert(newCar)
            try? modelContext.save()
            return newCar
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            Section(header: Text("Basic Information")) {
                Text("Make: Toyota")
                Text("Model: Camry")
                Text("Year: 2022")
                Text("License Plate: ABC123")
                Text("Nickname: Family Sedan")
                Text("Color: Blue")
            }
            
            Section(header: Text("Technical Details")) {
                Text("VIN: 1HGCM82633A123456")
                Text("Fuel Type: Gasoline")
                Text("Engine Size: 2.5L")
                Text("Transmission: Automatic")
            }
        }
        .navigationTitle("Add Car")
    }
}

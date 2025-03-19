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
    
    // If nil, we're creating a new car; otherwise, we're editing
    var existingCar: CarProfile?
    @State private var newlyCreatedCar: CarProfile?
    @State private var showDocumentPicker = false
    
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
                        TextField("Make", text: $make)
                        TextField("Model", text: $model)
                        Stepper("Year: \(String(year))", value: $year, in: 1900...Calendar.current.component(.year, from: Date()) + 1)
                        TextField("License Plate", text: $licensePlate)
                        TextField("Nickname (Optional)", text: $nickname)
                        TextField("Color", text: $color)
                    }
                    
                    Section(header: Text("Technical Details")) {
                        TextField("VIN", text: $vin)
                        Picker("Fuel Type", selection: $fuelType) {
                            Text("Gasoline").tag(FuelType.gasoline)
                            Text("Diesel").tag(FuelType.diesel)
                            Text("Electric").tag(FuelType.electric)
                            Text("Hybrid").tag(FuelType.hybrid)
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Engine Size", text: $engineSize)
                        
                        Picker("Transmission", selection: $transmissionType) {
                            Text("Manual").tag(TransmissionType.manual)
                            Text("Automatic").tag(TransmissionType.automatic)
                            Text("Semi-Automatic").tag(TransmissionType.semiAutomatic)
                            Text("CVT").tag(TransmissionType.cvt)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section(header: Text("Ownership Information")) {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        DatePicker("First Road Date", selection: $firstRoadDate, displayedComponents: .date)
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
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(existingCar == nil ? "Save" : "Update") {
                            let car = saveCarProfile()
                            
                            if existingCar == nil {
                                // If creating a new car, proceed to document step
                                newlyCreatedCar = car
                                showingDocumentStep = true
                            } else {
                                // If editing, just dismiss
                                dismiss()
                            }
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && !licensePlate.isEmpty &&
        !color.isEmpty && !vin.isEmpty && !engineSize.isEmpty
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
            car.vin = vin
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
                vin: vin,
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

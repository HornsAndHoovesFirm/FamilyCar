//
//  CarDetailView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 14/03/2025.
//

import SwiftUI
import SwiftData

struct CarDetailView: View {
    @Bindable var car: CarProfile
    @State private var isEditMode = false
    
    var body: some View {
        List {
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
            
            Section("Technical Details") {
                LabeledContent("VIN", value: car.vin)
                LabeledContent("Fuel Type", value: car.fuelType.rawValue.capitalized)
                LabeledContent("Engine Size", value: car.engineSize)
                LabeledContent("Transmission", value: car.transmissionType.rawValue.capitalized)
            }
            
            Section("Ownership Information") {
                LabeledContent("Purchase Date", value: car.purchaseDate.formatted(date: .long, time: .omitted))
                LabeledContent("First Road Date", value: car.firstRoadDate.formatted(date: .long, time: .omitted))
            }
            
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
    }
}

#Preview {
    NavigationStack {
        CarDetailPreview()
    }
}

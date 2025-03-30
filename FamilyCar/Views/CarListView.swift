//
//  CarListView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 13/03/2025.
//

import SwiftUI
import SwiftData

struct CarListView: View {
    @Environment(\.modelContext) private var modelContext
    //@Query(sort: \CarProfile.make) private var carProfiles: [CarProfile]
    @Query private var carProfiles: [CarProfile]

    init() {
        let sortDescriptor = SortDescriptor(\CarProfile.make)
        _carProfiles = Query(sort: [sortDescriptor])
    }
    
    @State private var showingAddCar = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(carProfiles) { car in
                    NavigationLink {
                        CarDetailView(car: car)
                    } label: {
                        CarRowView(car: car)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Family Cars")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCar = true }) {
                        Label("Add Car", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCar) {
                CarFormView() // No car passed, so it's in "create" mode
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(carProfiles[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    CarListPreview()
}

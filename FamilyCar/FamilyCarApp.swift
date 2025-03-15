//
//  FamilyCarApp.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 12/03/2025.
//

import SwiftUI
import SwiftData

@main
struct FamilyCarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CarProfile.self, CarDocument.self])
    }
}

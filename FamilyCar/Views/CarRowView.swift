//
//  CarRowView.swift
//  FamilyCar
//
//  Created by Oleg Chernobelsky on 14/03/2025.
//

import SwiftUI
import SwiftData

struct CarRowView: View {
    let car: CarProfile
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(String(car.year)) \(car.make) \(car.model)")
                    .font(.headline)
                Text(car.nickname ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(car.licensePlate)
                .font(.caption)
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    CarRowPreview()
}

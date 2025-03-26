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
    
    // Get color from string representation
    private func getColor(from colorString: String) -> Color {
        let lowerCasedColor = colorString.lowercased()
        
        switch lowerCasedColor {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "black": return .black
        case "white": return .white
        case "gray", "grey": return .gray
        case "brown": return .brown
        default: return .primary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Car icon badge with color
            ZStack {
                Circle()
                    .fill(getColor(from: car.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: car.fuelType.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(getColor(from: car.color))
            }
            
            // Car details
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(car.year)) \(car.make) \(car.model)")
                    .font(.headline)
                
                if let nickname = car.nickname, !nickname.isEmpty {
                    Text(nickname)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // License plate and document indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text(car.licensePlate)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                if car.licenseDocument != nil {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.fill")
                            .font(.caption2)
                        Text("License")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    CarRowPreview()
}

//
//  DraggableCircle.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 21/05/24.
//

import Foundation
import SwiftUI

/*struct DraggableCircle: View {
    @Binding var value: Double
    var goal: Double?
    var title: String
    var unit: String
    var color: Color
    @Binding var position: CGPoint
    var boundary: CGRect
    @Binding var showDeleteIcon: Bool
    var onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 120, height: 120)
                    .shadow(color: color.opacity(0.5), radius: 10, x: 5, y: 5)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(value / (goal ?? value), 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: -90))
                VStack {
                    Text(title)
                        .font(.caption).bold()
                        .foregroundColor(contrastColor(for: color))
                    if let goal = goal {
                        Text("\(Int(value))")
                            .font(.title).bold()
                            .foregroundColor(contrastColor(for: color))
                        Text("/\(Int(goal)) \(unit)")
                            .font(.caption).bold()
                            .foregroundColor(contrastColor(for: color))
                    } else {
                        Text("\(Int(value)) \(unit)")
                            .font(.caption).bold()
                            .foregroundColor(contrastColor(for: color))
                    }
                }
                if showDeleteIcon {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                onDelete()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .offset(x: -150, y: -50) // Adjusted offset to position the delete button correctly
                }
            }
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newLocation = value.location
                        if boundary.contains(newLocation) {
                            self.position = newLocation
                        }
                    }
                    .onEnded { _ in
                        showDeleteIcon = false
                    }
            )
            .onLongPressGesture {
                withAnimation {
                    showDeleteIcon.toggle()
                }
            }
        }
    }
    
    func contrastColor(for color: Color) -> Color {
        let components = color.cgColor?.components ?? [0.0, 0.0, 0.0]
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness < 0.5 ? .white : .black
    }
}*/

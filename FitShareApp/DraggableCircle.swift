//
//  DraggableCircle.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 20/05/24.
//

import Foundation
import SwiftUI

struct DraggableCircle: View {
    let title: String
    let progress: Double
    let goal: Double
    let onDelete: () -> Void
    @State private var isDragging = false
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: CGFloat(min(progress / goal, 1.0)))
                .stroke(AngularGradient(gradient: Gradient(colors: [.blue, .green]), center: .center), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 100, height: 100)

            VStack {
                Text(title)
                    .font(.caption)
                Text("\(Int(progress))/\(Int(goal))")
                    .font(.caption)
                    .bold()
            }
            
            if isDragging {
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .offset(x: 35, y: -35)
            }
        }
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.offset = value.translation
                    self.isDragging = true
                }
                .onEnded { _ in
                    self.isDragging = false
                }
        )
        .onLongPressGesture {
            self.isDragging.toggle()
        }
    }
}

struct DraggableCircle_Previews: PreviewProvider {
    static var previews: some View {
        DraggableCircle(title: "Steps", progress: 5000, goal: 10000, onDelete: {})
    }
}

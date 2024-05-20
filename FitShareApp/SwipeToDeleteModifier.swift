//
//  SwipeToDeleteModifier.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 19/05/24.
//

import Foundation
import SwiftUI

/*struct SwipeToDeleteModifier: ViewModifier {
    @Binding var isDeleted: Bool

    func body(content: Content) -> some View {
        content
            .background(SwipeGestureView(isDeleted: $isDeleted))
    }
}

struct SwipeGestureView: UIViewRepresentable {
    @Binding var isDeleted: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let swipeGesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isDeleted: $isDeleted)
    }

    class Coordinator: NSObject {
        @Binding var isDeleted: Bool

        init(isDeleted: Binding<Bool>) {
            _isDeleted = isDeleted
        }

        @objc func handleSwipe() {
            withAnimation {
                isDeleted = true
            }
        }
    }
}

extension View {
    func swipeToDelete(isDeleted: Binding<Bool>) -> some View {
        self.modifier(SwipeToDeleteModifier(isDeleted: isDeleted))
    }
}
*/

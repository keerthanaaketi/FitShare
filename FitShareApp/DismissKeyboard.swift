//
//  DismissKeyboard.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 21/05/24.
//

import Foundation
import SwiftUI

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboard())
    }
}

struct DismissKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                self.hideKeyboard()
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

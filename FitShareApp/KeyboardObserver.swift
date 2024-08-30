//
//  KeyboardObserver.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 21/05/24.
//

import Foundation
import Combine
import UIKit

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification))
            .sink { notification in
                if notification.name == UIResponder.keyboardWillShowNotification {
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        self.keyboardHeight = keyboardFrame.height
                    }
                } else {
                    self.keyboardHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}

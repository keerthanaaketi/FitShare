//
//  ScreenshotManager.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 16/03/24.
//

import Foundation
import SwiftUI

class ScreenshotManager {
    static let shared = ScreenshotManager()

    private init() {} // Private initializer for singleton

    func capture(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // slight delay to ensure UI is ready
            guard let window = UIApplication.shared.windows.first else {
                completion(nil)
                return
            }
            UIGraphicsBeginImageContextWithOptions(window.frame.size, false, 0.0)
            window.drawHierarchy(in: window.frame, afterScreenUpdates: true)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            completion(screenshot)
        }
    }
}

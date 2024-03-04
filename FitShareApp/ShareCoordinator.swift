//
//  ShareCoordinator.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 11/02/24.
//

import Foundation
import SwiftUI
class ShareCoordinator: NSObject, ObservableObject {
    @Published var isPresentingActivityViewController = false
    var screenshotImage: UIImage?
    
    func shareScreenshot() -> UIImage? {
            // Your logic to capture the screenshot and return the UIImage
            guard let window = UIApplication.shared.windows.first else {
                return nil
            }

            UIGraphicsBeginImageContextWithOptions(window.frame.size, false, 0.0)
            window.drawHierarchy(in: window.frame, afterScreenUpdates: true)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return screenshot
        }
    
    func takeScreenshot() -> UIImage? {
        guard let window = UIApplication.shared.windows.first else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, 0.0)
        window.drawHierarchy(in: window.frame, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }
}

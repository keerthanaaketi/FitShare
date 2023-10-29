//
//  CustomUserDefaults.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 16/09/23.
//

import Foundation
class CustomUserDefaults {
    static var shared = CustomUserDefaults()
    
    func setPushNotifications(enable: Bool) {
        let defaults = UserDefaults.standard
                
        defaults.set(enable, forKey: Constants.PUSH_NOTIFCATIONS)
        defaults.synchronize()
    }
    
    func getPushNotifications() -> Bool {
        let defaults = UserDefaults.standard
                
        defaults.synchronize()
        return defaults.bool(forKey: Constants.PUSH_NOTIFCATIONS)
    }
}

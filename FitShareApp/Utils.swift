//
//  Utils.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 15/09/23.
//

import Foundation
import UserNotifications

class Utils {
    static var shared = Utils()
    
    func requestUserNotifications(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                CustomUserDefaults.shared.setPushNotifications(enable: success)
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}

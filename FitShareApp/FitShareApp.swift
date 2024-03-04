//
//  WeightX2App.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 13/08/23.
//

import SwiftUI
import Firebase

@main
struct FitShareApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var phoneViewModel = PhoneViewModel()
    
    var body: some Scene {
        WindowGroup {
            //NavigationView {
               LaunchView(phoneViewModel: phoneViewModel, goalModel: GoalModel(), shareList: ShareList())
           // }
           /* ActivateAccountView(phoneViewModel: phoneViewModel)
                .sheet(isPresented: $phoneViewModel.showPhoneNumberEntry) {
                    ContentView(phoneViewModel: phoneViewModel)
                }*/
        }
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
      
    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(#function)")
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
    }
}

//
//  SettingsView.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 17/05/24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var phoneViewModel: PhoneViewModel
    @ObservedObject var goalModel: GoalModel
    @ObservedObject var shareList: ShareList
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: GoalSheet(goalModel: goalModel, phoneViewModel: phoneViewModel, shareList: shareList)) {
                    Text("Set Goals")
                }

                Button(action: {
                    // Perform sign out logic
                    phoneViewModel.signout()
                    UserDefaults.standard.set("false", forKey: "goalSet")
                    PhoneNumberView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(leading:
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                }
            )
        }
    }
}

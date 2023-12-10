//
//  ContentView.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 13/08/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
        @ObservedObject var phoneViewModel: PhoneViewModel
        @State private var phoneNumber: String = ""
    @ObservedObject var goalModel : GoalModel
    @ObservedObject var shareList: ShareList
    @State private var isNavigationActive = false

        var body: some View {
            VStack {
                if Auth.auth().currentUser != nil {
                    if let savedValue = UserDefaults.standard.string(forKey: "goalSet"), savedValue == "true"{
                        HomeScreenView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
                    }
                    else{
                        GoalSheet(goalModel: goalModel, phoneViewModel: phoneViewModel, shareList: ShareList())
                    }
                }
                else{
                    PhoneNumberView(phoneViewModel: phoneViewModel)
                        
                }
            }
            
        }
    }
struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}





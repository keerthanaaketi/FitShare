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
    
    
    @State private var isNavigationActive = false

        var body: some View {
            VStack {
                if let user = Auth.auth().currentUser {
                    HomeScreenView(phoneViewModel: phoneViewModel)
                }
                else{
                    PhoneNumberView(phoneViewModel: phoneViewModel)
                }
            }
            
        }
    }
/*struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView(phoneViewModel: <#PhoneViewModel#>)
    }
}*/





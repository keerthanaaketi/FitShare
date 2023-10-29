//
//  AuthViewModel.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 11/09/23.
//

import Foundation
import PromiseKit
import Firebase

class AuthViewModel: ObservableObject {
    func signUp(phoneNumber: String) -> Promise<String> {
        return AuthenticationService.signUp(phoneNumber: phoneNumber)
    }

    func signIn(verificationID: String, verificationCode: String) -> Promise<AuthDataResult> {
        return AuthenticationService.signIn(verificationID: verificationID, verificationCode: verificationCode)
    }

    func signOut(){
        AuthenticationService.signOut()
    }
}

//
//  AuthenticationService.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 15/09/23.
//

import Foundation
import Firebase
import PromiseKit

class AuthenticationService  {
    static func signUp(phoneNumber: String) -> Promise<String> {
        return Promise { seal in
            DispatchQueue.global(qos: .background).async {
                PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                    if error != nil {
                        seal.reject(FirebaseError.Error)
                        print("Firebase error: \(error)")
                        return
                    }
                    guard let verificationID = verificationID else {
                        seal.reject(FirebaseError.VerificatrionEmpty)
                        return
                    }
                    seal.fulfill(verificationID)
                }
            }
        }
    }
    
    static func signIn(verificationID: String, verificationCode: String) -> Promise<AuthDataResult> {
        return Promise { seal in
            let credential = PhoneAuthProvider.provider().credential(
              withVerificationID: verificationID,
              verificationCode: verificationCode
            )
            Auth.auth().signIn(with: credential) { authResult, error in
                if error != nil {
                    seal.reject(FirebaseError.Error)
                    return
                }
                guard let authResult = authResult else {
                    seal.reject(FirebaseError.VerificatrionEmpty)
                    return
                }
                seal.fulfill(authResult)
            }
        }
    }
    
    static func signOut() {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            }
            catch {
              print (error)
            }
        }
    }
}

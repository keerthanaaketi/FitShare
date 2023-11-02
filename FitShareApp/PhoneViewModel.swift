//
//  PhoneViewModel.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 15/09/23.
//

import Foundation
import PromiseKit

class PhoneViewModel: ObservableObject {
    //MARK: vars
    var authViewModel = AuthViewModel()
    var nowDate = Date()
    let referenceDate = Date(timeIntervalSinceNow:(1 * 5.0))
    @Published var verificationCode = ""
    @Published var verificationID = ""
    @Published var phoneNumber = ""
    @Published var countryCodeNumber = ""
    @Published var country = ""
    @Published var code = ""
    @Published var timerExpired = false
    @Published var timeStr = ""
    @Published var timeRemaining = 60
    @Published var showPhoneNumberEntry = false
    @Published var isVerifiedUser = false
    @Published var isSignedIn = false
    @Published var isVerificationCodeSent = false
    @Published  var isUserSignedOut = false
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    //MARK: init
    init() {
        getCountryCodeForLocale()
    }
    
    //MARK: functions
    func getCurrentRegionCode() {
        countryCodeNumber = Locale.current.regionCode!.uppercased()
    }
    
    func getCountryCodeForLocale() {
        var countryCodes = [CountryModel]()
        getCurrentRegionCode()
        let countryCodesPath = Bundle.main.path(forResource: "CountryCodes", ofType: "json")!
        
        do {
            let fileCountryCodes = try? String(contentsOfFile: countryCodesPath).data(using: .utf8)!
            let decoder = JSONDecoder()
            countryCodes = try decoder.decode([CountryModel].self, from: fileCountryCodes!)
        }
        catch {
            print(error)
        }
        country = countryCodes.filter { $0.code == countryCodeNumber }.first?.name ?? ""
        code = countryCodes.filter { $0.code == countryCodeNumber }.first?.code ?? ""
        countryCodeNumber = countryCodes.filter { $0.code == countryCodeNumber }.first?.dial_code ?? ""
    }
    
    func selectCountryCode(selectedCountry: CountryModel){
        countryCodeNumber = selectedCountry.dial_code
        country = selectedCountry.name
        code = selectedCountry.code
    }
    
    func stopTimer() {
        self.timer.upstream.connect().cancel()
    }
    
    func startTimer() {
        timeRemaining = 60
        timerExpired = false
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
        //Start new round of verification
        self.verificationCode = ""
        //requestVerificationID()
    }

    func countDownString() {
        guard (timeRemaining > 0) else {
            self.timer.upstream.connect().cancel()
            timerExpired = true
            timeStr = String(format: "%02d:%02d", 00,  00)
            return
        }
        
        timeRemaining -= 1
        timeStr = String(format: "%02d:%02d", 00, timeRemaining)
    }
    
    func getPin(at index: Int) -> String {
        guard self.verificationCode.count > index else {
            return ""
        }       
        let index = self.verificationCode.index(self.verificationCode.startIndex, offsetBy: index)
        let characterAtIndex = self.verificationCode[index]
        return String(characterAtIndex)
    }
    
    func limitText(_ upper: Int) {
        if verificationCode.count > upper {
            verificationCode = String(verificationCode.prefix(upper))
        }
    }
    
    func requestVerificationID() -> Promise<Void> {
        return Promise { seal in
            let backgroundQueue = DispatchQueue.global(qos: .background)
            firstly {
                authViewModel.signUp(phoneNumber: "\(self.countryCodeNumber)\("")\(self.phoneNumber)")
            }.done(on: DispatchQueue.main) { verificationID in
                self.verificationID = verificationID
                self.isVerificationCodeSent = true
                seal.fulfill(())
            }.catch { (error) in
                print(error.localizedDescription)
                self.isVerificationCodeSent = false
                seal.reject(error)
            }
        }
    }
    
    func authenticate() -> Promise<Void> {
        return Promise { seal in
            let backgroundQueue = DispatchQueue.global(qos: .background)
            
            firstly {
                authViewModel.signIn(verificationID: self.verificationID, verificationCode: self.verificationCode)
            }.done(on: backgroundQueue) { (AuthDataResult) in
                print("successfull signin")
                self.isVerifiedUser = true
                seal.fulfill(())
            }.catch { (error) in
                print(error.localizedDescription)
                self.isVerifiedUser = false
                seal.reject(error)
            }
        }
    }
    
    func signout() -> Promise<Void> {
        return Promise { seal in
            let backgroundQueue = DispatchQueue.global(qos: .background) 
                authViewModel.signOut()
            self.isUserSignedOut = true
        }
    }
}

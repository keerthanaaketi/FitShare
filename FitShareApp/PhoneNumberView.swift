import SwiftUI
import Firebase
import FirebaseAuth

struct PhoneNumberView: View {
    @ObservedObject var phoneViewModel: PhoneViewModel
    @State private var phoneNumber: String = ""
    @State private var isNavigationActive = false
    @State private var isLoading = false
    @State private var errorMessage: String? // Added state for error message

    var body: some View {
        VStack {
            Text("FitShare")
                .font(.title)
                .padding(.bottom, 20)
            
            Text("Enter Your Phone Number")
                .padding(.bottom, 20)
            HStack {
                TextField("Country Code", text: $phoneViewModel.countryCodeNumber)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            
            Button(action: {
                if isValidPhoneNumber() {
                    isLoading = true
                    phoneViewModel.phoneNumber = phoneNumber
                    DispatchQueue.global(qos: .background).async {
                        phoneViewModel.requestVerificationID()
                            .done { _ in
                                if phoneViewModel.isVerificationCodeSent {
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        isNavigationActive = true
                                    }
                                } else {
                                    // Handle authentication failure and show error message
                                    errorMessage = "Please check your phone number and try again"
                                    isLoading = false
                                }
                            }
                            .catch { error in
                                // Handle error and show error message
                                errorMessage = "An error occurred. Please try again later."
                                isLoading = false
                            }
                    }
                }
            }) {
                if isLoading {
                    // Show loading indicator
                    ProgressView()
                } else {
                    Text("Signup")
                        .padding()
                        .background(phoneNumber.count >= 10 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(phoneNumber.count < 10)
                }
            }
        }
        .padding()
        .background(NavigationLink("", destination: OTPView(phoneViewModel: phoneViewModel), isActive: $isNavigationActive)
            .opacity(0)
            .accessibility(hidden: true))
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { newValue in errorMessage = newValue ? errorMessage : nil }
        )) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }

    private func isValidPhoneNumber() -> Bool {
        let numericPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return numericPhoneNumber.count >= 10
    }
}


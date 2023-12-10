import SwiftUI
import Firebase
import FirebaseAuth

public struct OTPView: View {
    @State private var otp = ""
    @State private var isInputValid = true
    @ObservedObject var phoneViewModel: PhoneViewModel
    @State private var isAuthenticationInProgress = false
    @State private var errorMessage: String? // Added state for error message

    public var body: some View {
        VStack {
            Text("FitShare")
                .font(.title)
                .padding(.bottom, 20)
            Text("Sending OTP to: \(phoneViewModel.phoneNumber)")
                .fontWeight(.semibold)
                .frame(width: nil, height: nil, alignment: .leading)
                .foregroundColor(Color.primary)
            
            Text("Enter 6-digit OTP")
            
            TextField("123456", text: $phoneViewModel.verificationCode)
                .keyboardType(.numberPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 200)
                .border(isInputValid ? Color.clear : Color.red, width: 1) // Add a border to indicate validation
            
            if !isInputValid {
                Text("Please enter a valid 6-digit OTP")
                    .foregroundColor(.red)
            }
            
            VStack {
                Button("Verify OTP") {
                    handleVerifyOTP()
                }
                .padding()
                .background(phoneViewModel.verificationCode.count == 6 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(phoneViewModel.verificationCode.count < 6 || isAuthenticationInProgress)
            }
            .padding()
        }
        .onAppear(){
            phoneViewModel.verificationCode = ""
        }
        .onChange(of: otp) { newValue in
            // Check if the input is a 6-digit number
            isInputValid = newValue.count == 6 && Int(newValue) != nil
        }
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { newValue in errorMessage = newValue ? errorMessage : nil }
        )) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("Retry")) {
                phoneViewModel.verificationCode = ""
            })
        }
    }
    
    private func handleVerifyOTP() {
        guard !isAuthenticationInProgress else { return }
        if isInputValid {
            isAuthenticationInProgress = true
            phoneViewModel.authenticate()
                .done { _ in
                    // Authentication succeeded
                    if phoneViewModel.isVerifiedUser {
                        // Handle successful authentication
                    } else {
                        // Handle authentication failure
                        errorMessage = "Authentication failed. Please retry."
                        isAuthenticationInProgress = false // Reset authentication state
                    }
                }
                .catch { error in
                    // Handle authentication error
                    errorMessage = "An error occurred. Please retry."
                    isAuthenticationInProgress = false // Reset authentication state
                }
        }
    }
}

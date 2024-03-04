import SwiftUI
import Firebase
import FirebaseAuth

struct PhoneNumberView: View {
    @ObservedObject var phoneViewModel: PhoneViewModel
    @State private var phoneNumber: String = ""
    @State private var isNavigationActive = false
    @State private var isLoading = false
    @State private var errorMessage: String? // Added state for error message
    @ObservedObject var goalModel : GoalModel
    @ObservedObject var shareList: ShareList
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkTheme = true
    var body: some View {
        let imageName = isDarkTheme ? "FitShareDark" : "FitShareLaunch"
        NavigationView {
        VStack {
            Spacer()
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black) // Adjust the color of the logo as needed
                .frame(width: 300, height: 300)
                .clipShape(Circle())
            Text("Enter Your Phone Number")
                .padding(.bottom, 20)
            HStack {
                CountryCodeTextField(text: $phoneViewModel.countryCodeNumber)
                                   .textFieldStyle(RoundedBorderTextFieldStyle())
                                   .frame(width: 100)
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
                    Text("Login")
                        .padding()
                        .background(phoneNumber.count >= 10 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(phoneNumber.count < 10)
                }
            }
            Spacer()
            Spacer()
        }
        .onAppear(){
            isDarkTheme = (colorScheme == .dark)
        }
        .padding()
        .background(NavigationLink("", destination: OTPView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList), isActive: $isNavigationActive)
            .opacity(0)
            .accessibility(hidden: true))
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { newValue in errorMessage = newValue ? errorMessage : nil }
        )) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
                }
    struct CountryCodeTextField: View {
        @Binding var text: String
        
        var body: some View {
            TextField("", text: $text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                //.overlay(
                  //  RoundedRectangle(cornerRadius: 8)
                    //    .stroke(Color.gray, lineWidth: 1)
                //)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .textContentType(.telephoneNumber) // For keyboard suggestions
                .modifier(CountryCodeFormatter(text: $text))
        }
    }

    // Custom modifier to format country code input
    struct CountryCodeFormatter: ViewModifier {
        @Binding var text: String
        
        func body(content: Content) -> some View {
            content
                .onChange(of: text) { newValue in
                    // Format country code input as needed here
                    // For example, you can add the '+' character at the beginning if missing
                    if !newValue.hasPrefix("+") {
                        text = "+" + newValue
                    }
                }
        }
    }
    private func isValidPhoneNumber() -> Bool {
        let numericPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return numericPhoneNumber.count >= 10
    }
}

struct PhoneNumberView_Previews: PreviewProvider {
     static var previews: some View {
         PhoneNumberView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}


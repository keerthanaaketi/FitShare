import SwiftUI

struct LogoView: View {
    @State private var isActive = false
    @ObservedObject var phoneViewModel: PhoneViewModel
    @ObservedObject var goalModel: GoalModel
    @ObservedObject var shareList: ShareList
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkTheme = false
    var body: some View {
        let imageName = isDarkTheme ? "FitShareDark" : "FitShareLaunch"
        ZStack {  
            VStack {
                Spacer()
                // Your app's logo
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.black) // Adjust the color of the logo as needed
                    .frame(width: 300, height: 300)
                    .clipShape(Circle())
                Spacer()
                
                // Loading dots around the logo
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.blue) // Adjust the color of the dots as needed
                            .opacity(self.isActive ? 0 : 1) // Hide the dots when isActive is true
                            .animation(Animation.easeInOut(duration: 0.5).delay(0.2 * Double(index)))
                    }
                }
                
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            isDarkTheme = (colorScheme == .dark)
            // Start a timer to navigate to the next page after a few seconds
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            HomeScreenView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
        }
    }
}
public struct LogoView_Previews: PreviewProvider {
    public static var previews: some View {
        LogoView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}


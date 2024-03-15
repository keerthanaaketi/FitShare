import Foundation
import SwiftUI
import HealthKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseDatabaseSwift

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
                Text("Share your fit info in seconds")
                    .padding(.bottom, 20)
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
            if let userID = getUserID() {
                getUserData(userID: userID) { userData in
                    if let goalStepCount = userData?["goalStepCount"] as? Int,
                    let goalNutrtionCount = userData?["goalNutrition"] as? Int,
                    let goalProtein = userData?["goalProtein"] as? Int,
                    let goalFat = userData?["goalFat"] as? Int,
                    let goalCarbs = userData?["goalCarbs"] as? Int,
                    let goalWorkouts = userData?["goalWorkouts"] as? Int,
                    let goalSleep = userData?["goalSleep"] as? Int,
                    let showStep = userData?["showStep"] as? Bool,
                    let showWorkout = userData?["showWorkout"] as? Bool,
                    let showNutrition = userData?["showNutrition"] as? Bool,
                    let showSleep = userData?["showSleep"] as? Bool
                    {
                        goalModel.stepGoal = String(goalStepCount)
                        goalModel.nutritionGoal = String(goalNutrtionCount)
                        goalModel.proteinGoal = String(goalProtein)
                        goalModel.fatsGoal = String(goalFat)
                        goalModel.carbsGoal = String(goalCarbs)
                        goalModel.workoutsGoal = String(goalWorkouts)
                        goalModel.sleepGoal = String(goalSleep)
                        shareList.showSteps = showStep
                        shareList.showNutrition = showNutrition
                        shareList.showWorkout = showWorkout
                        shareList.showSleep = showSleep
                    }
                }
            }
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
func getUserData(userID: String, completion: @escaping ([String: Any]?) -> Void) {
    let databaseReference = Database.database().reference()
    let userReference = databaseReference.child("users").child(userID)

    userReference.observeSingleEvent(of: .value) { snapshot in
        guard snapshot.exists(), let userData = snapshot.value as? [String: Any] else {
            // User not found or data is not in the expected format
            completion(nil)
            return
        }

        // User data retrieved successfully
        completion(userData)
    }
}
func getUserID() -> String? {
    if let user = Auth.auth().currentUser {
        return user.uid
    }
    return nil
}
public struct LogoView_Previews: PreviewProvider {
    public static var previews: some View {
        LogoView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}


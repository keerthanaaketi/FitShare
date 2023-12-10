//
//  GoalSheet.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 13/11/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseDatabaseSwift

public struct GoalSheet: View {
    @ObservedObject var goalModel: GoalModel
    @ObservedObject var phoneViewModel: PhoneViewModel
    @State private var phoneNumber: String = ""
    @State var stepGoalLocal: String = ""
    @State var nutritionGoalLocal: String = ""
    @State var proteinGoalLocal: String = ""
    @State var fatGoalLocal: String = ""
    @State var carbsGoalLocal: String = ""
    @State var workoutGoalLocal: String = ""
    @State var sleepGoalLocal: String = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var shareList: ShareList
    
    public var body: some View {
        VStack {
            Text("FitShare")
                .font(.title)
            Text("\nChoose category and goal to share")
            VStack{
                List {
                    HStackRow(title: "Steps", textValue: $stepGoalLocal, toggleValue: $shareList.showSteps, textField: "steps")
                    HStackRow(title: "Nutrition", textValue: $nutritionGoalLocal, toggleValue: $shareList.showNutrition, textField: "Calories")
                    HStackRow2(title: "Protein", textValue: $proteinGoalLocal, textField: "gms")
                    HStackRow2(title: "Fat", textValue: $fatGoalLocal, textField: "gms")
                    HStackRow2(title: "Carbohydrates", textValue: $carbsGoalLocal, textField: "gms")
                    HStackRow(title: "Workouts", textValue: $workoutGoalLocal, toggleValue: $shareList.showWorkout, textField: "KCals")
                    HStackRow(title: "Sleep", textValue: $sleepGoalLocal, toggleValue: $shareList.showSleep, textField: "Hours")
                }
                Button("Set Goal") {
                    if(!self.stepGoalLocal.isEmpty){
                        goalModel.stepGoal = self.stepGoalLocal
                    }
                    if(!self.nutritionGoalLocal.isEmpty){
                        goalModel.nutritionGoal = self.nutritionGoalLocal
                    }
                    if(!self.proteinGoalLocal.isEmpty){
                        goalModel.proteinGoal = self.proteinGoalLocal
                    }
                    if(!self.fatGoalLocal.isEmpty){
                        goalModel.fatsGoal = self.fatGoalLocal
                    }
                    if(!self.carbsGoalLocal.isEmpty){
                        goalModel.carbsGoal = self.carbsGoalLocal
                    }
                    if(!self.workoutGoalLocal.isEmpty){
                        goalModel.workoutsGoal = self.workoutGoalLocal
                    }
                    if(!self.sleepGoalLocal.isEmpty){
                        goalModel.sleepGoal = self.sleepGoalLocal
                    }
                    if let userID = getUserID() {
                        if let goalStepCount = Int(goalModel.stepGoal),
                           let nutritionCount = Int(goalModel.nutritionGoal),
                           let protienCount = Int(goalModel.proteinGoal),
                           let fatCount = Int(goalModel.fatsGoal),
                           let carbsCount = Int(goalModel.carbsGoal),
                           let workoutCount = Int(goalModel.workoutsGoal),
                           let sleepCount = Int(goalModel.sleepGoal)
                        {
                            createUserNode(userID: userID, goalStepCount: goalStepCount, goalNutrition: nutritionCount, goalProtein: protienCount, goalFat: fatCount, goalCarbs: carbsCount, goalWorkouts: workoutCount, goalSleep: sleepCount)
                        } else {
                            print("Invalid goal step count input")
                        }
                    }
                    goalModel.goalSet = true
                    UserDefaults.standard.set("true", forKey: "goalSet")
                    if(presentationMode.wrappedValue.isPresented){
                        presentationMode.wrappedValue.dismiss()
                    }else{
                        HomeScreenView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
                    }
                    
                }
                .padding()
                .background(stepGoalLocal.count > 0 || nutritionGoalLocal.count > 0 || workoutGoalLocal.count > 0 || sleepGoalLocal.count > 0 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }.onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .edgesIgnoringSafeArea(.all)
                        .padding()
    }
    struct HStackRow: View {
        var title: String
        @Binding var textValue: String
        @Binding var toggleValue: Bool
        var textField: String
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                TextField(textField, text: $textValue)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                
                Toggle("", isOn: $toggleValue)
            }
            .padding()
            .frame(height: 40)
        }
    }
    struct HStackRow2: View {
        var title: String
        @Binding var textValue: String
        var textField: String
        
        var body: some View {
            HStack {
                Spacer()
                Text(title)
                    .font(.caption)
                
                TextField(textField, text: $textValue)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
            }
            .padding()
            .frame(height: 30)
        }
    }
    func getUserID() -> String? {
        if let user = Auth.auth().currentUser {
            return user.uid
        }
        return nil
    }
    func createUserNode(userID: String, goalStepCount: Int, goalNutrition: Int, goalProtein: Int, goalFat:Int, goalCarbs: Int, goalWorkouts: Int, goalSleep: Int) {
        let ref = Database.database().reference().child("users").child(userID)

        // Check if the user node already exists
        ref.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // User node exists, update stepCount and goalStepCount
                ref.updateChildValues(["goalStepCount": goalStepCount])
                ref.updateChildValues(["goalNutrition": goalNutrition])
                ref.updateChildValues(["goalProtein": goalProtein])
                ref.updateChildValues(["goalFat": goalFat])
                ref.updateChildValues(["goalCarbs": goalCarbs])
                ref.updateChildValues(["goalWorkouts": goalWorkouts])
                ref.updateChildValues(["goalSleep": goalSleep])
                ref.updateChildValues(["showStep":shareList.showSteps])
                ref.updateChildValues(["showNutrition":shareList.showNutrition])
                ref.updateChildValues(["showWorkout":shareList.showWorkout])
                ref.updateChildValues(["showSleep":shareList.showSleep])
            } else {
                // User node does not exist, create it with initial data
                ref.setValue(["goalStepCount": goalStepCount])
                ref.setValue(["goalNutrition": goalNutrition])
                ref.setValue(["goalProtein": goalProtein])
                ref.setValue(["goalFat": goalFat])
                ref.setValue(["goalCarbs": goalCarbs])
                ref.setValue(["goalWorkouts": goalWorkouts])
                ref.setValue(["goalSleep": goalSleep])
                ref.setValue(["showStep":shareList.showSteps])
                ref.setValue(["showNutrition":shareList.showNutrition])
                ref.setValue(["showWorkout":shareList.showWorkout])
                ref.setValue(["showSleep":shareList.showSleep])
            }
        }
    }
}

struct GoalSheet_Previews: PreviewProvider {
     static var previews: some View {
         GoalSheet(goalModel: GoalModel(), phoneViewModel: PhoneViewModel(), shareList: ShareList())
    }
}

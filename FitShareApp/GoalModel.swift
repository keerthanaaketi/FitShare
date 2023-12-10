//
//  GoalModel.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 13/11/23.
//

import Foundation

class GoalModel: ObservableObject {
    @Published var stepGoal: String = "10000"
    @Published var actualStep: String = "0"
    @Published var nutritionGoal: String = "0"
    @Published var proteinGoal: String = "0"
    @Published var fatsGoal: String = "0"
    @Published var carbsGoal: String = "0"
    @Published var workoutsGoal: String = "0"
    @Published var sleepGoal: String = "0"
    @Published var goalSet = false
}

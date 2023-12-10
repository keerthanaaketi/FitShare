//
//  ShareList.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 13/11/23.
//

import Foundation
class ShareList: ObservableObject{
    @Published var showSteps: Bool = false
    @Published var showNutrition: Bool = false
    @Published var showSleep: Bool = false
    @Published var showWorkout: Bool = false
}

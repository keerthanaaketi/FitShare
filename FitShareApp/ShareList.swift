//
//  ShareList.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 13/11/23.
//

import Foundation
class ShareList: ObservableObject{
    @Published var showSteps: Bool = true
    @Published var showNutrition: Bool = true
    @Published var showSleep: Bool = true
    @Published var showWorkout: Bool = true
}

//
//  NutritionSlabView.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 17/05/24.
//

import Foundation
import SwiftUI

struct NutritionSlabView: View {
    var title: String
    var total: String
    var goal: String
    var remaining: String
    var protein: Int
    var fat: Int
    var carbs: Int
    var proteinGoal: Int
    var fatGoal: Int
    var carbsGoal: Int

    var body: some View {
        VStack{
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray)
                .frame(width: 390, height: 190)
                .overlay(VStack {
                    Spacer()
                    HStack{
                        Text("\t")
                        Text(title)
                            .font(.title2).bold()
                        Spacer()
                        Text(total)
                            .font(.title3)
                        Spacer()
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("Goal:"+goal)
                            .font(.headline)
                        Spacer()
                        if let remainingInt = Int(remaining), remainingInt > 0 {
                            Text("Left: \(remaining)")
                                .font(.headline)
                        } else {
                            Text("Goal Reached")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                    Text("\n")
                    VStack {
                        HStack {
                            Text("Protein").font(.headline).bold()
                            if proteinGoal - protein > 0 {
                                Text("total: \(protein) goal: \(proteinGoal) left: \(proteinGoal - protein)").font(.headline)
                            } else if proteinGoal > 0 {
                                Text("total: \(protein) goal: \(proteinGoal) Goal reached").font(.headline).foregroundColor(.green)
                            } else {
                                Text("total: \(protein) goal: \(proteinGoal)").font(.headline)
                            }
                        }
                        HStack {
                            Text("Fat").font(.headline).bold()
                            if fatGoal - fat > 0 {
                                Text("total: \(fat) goal: \(fatGoal) left: \(fatGoal - fat)").font(.headline)
                            } else if fatGoal > 0 {
                                Text("total: \(fat) goal: \(fatGoal) Goal reached").font(.headline).foregroundColor(.green)
                            } else {
                                Text("total: \(fat) goal: \(fatGoal)").font(.headline)
                            }
                        }
                        HStack {
                            Text("Carbs").font(.headline).bold()
                            if carbsGoal - carbs > 0 {
                                Text("total: \(carbs) goal: \(carbsGoal) left: \(carbsGoal - carbs)").font(.headline)
                            } else if carbsGoal > 0 {
                                Text("total: \(carbs) goal: \(carbsGoal)  Goal reached").font(.headline).foregroundColor(.green)
                            } else {
                                Text("total: \(carbs) goal: \(carbsGoal)").font(.headline)
                            }
                        }
                    }
                    Spacer()
                })
        }
    }
}

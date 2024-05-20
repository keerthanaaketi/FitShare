import SwiftUI

struct NutritionView: View {
    var calories: Int
    var protein: Int
    var fat: Int
    var carbs: Int
    var nutritionGoal: Int
    var proteinGoal: Int
    var fatGoal: Int
    var carbsGoal: Int
    
    @State private var showMacros = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let backgroundColor = colorScheme == .dark ? Color.gray.opacity(0.3) : Color.black.opacity(0.1)
        let calorieProgress = min(max(Double(calories) / Double(nutritionGoal), 0.0), 1.0)
        let proteinProgress = min(max(Double(protein) / Double(proteinGoal), 0.0), 1.0)
        let fatProgress = min(max(Double(fat) / Double(fatGoal), 0.0), 1.0)
        let carbsProgress = min(max(Double(carbs) / Double(carbsGoal), 0.0), 1.0)
        let goalCalReached = calories >= nutritionGoal
        let goalProReached = protein >= proteinGoal
        let goalCarbReached = carbs >= carbsGoal
        let goalFatReached = fat >= fatGoal
        //let backgroundColor = colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text("Nutrition")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                AdaptiveText(text: "\(calories) / \(nutritionGoal) kcal", font: .title2, color: .blue)
                Spacer()
                if(goalCalReached){
                    Text("Uh oh!")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .fontWeight(.bold)
                
                } else {
                    Text("Remaining: \(nutritionGoal - calories) kcal")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            HStack {
                let progressBarColor = goalCalReached ? Color.orange : Color.green
                ProgressView(value: calorieProgress)
                    .progressViewStyle(CustomProgressViewStyle(color: progressBarColor))
                Button(action: {
                    showMacros.toggle()
                }) {
                    Image(systemName: showMacros ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .padding(.leading, 5)
                }
            }
            if showMacros {
                VStack {
                    HStack {
                        //let progressProBarColor = goalProReached ? Color.green : Color.orange
                        Text("Protein")
                            .foregroundColor(.gray)
                        ProgressView(value: proteinProgress)
                            .progressViewStyle(CustomProgressViewStyle(color: .green))
                        AdaptiveText(text: "\(protein) / \(proteinGoal) g", font: .caption2, color: .gray)
                    }
                    HStack {
                        let progressFatBarColor = goalFatReached ? Color.orange : Color.green
                        Text("Fat")
                            .foregroundColor(.gray)
                        ProgressView(value: fatProgress)
                            .progressViewStyle(CustomProgressViewStyle(color: progressFatBarColor))
                        AdaptiveText(text: "\(fat) / \(fatGoal) g", font: .caption2, color: .gray)
                    }
                    HStack {
                        let progressCarbBarColor = goalCarbReached ? Color.orange : Color.green
                        Text("Carbs")
                            .foregroundColor(.gray)
                        ProgressView(value: carbsProgress)
                            .progressViewStyle(CustomProgressViewStyle(color: progressCarbBarColor))
                        AdaptiveText(text: "\(carbs) / \(carbsGoal) g", font: .caption2, color: .gray)
                    }
                }
                .frame(maxWidth: .infinity)
                //.background(backgroundColor)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

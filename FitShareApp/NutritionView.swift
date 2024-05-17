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

    var body: some View {
        let calorieProgress = min(max(Double(calories) / Double(nutritionGoal), 0.0), 1.0)
        let proteinProgress = min(max(Double(protein) / Double(proteinGoal), 0.0), 1.0)
        let fatProgress = min(max(Double(fat) / Double(fatGoal), 0.0), 1.0)
        let carbsProgress = min(max(Double(carbs) / Double(carbsGoal), 0.0), 1.0)

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
                Text("Remaining: \(nutritionGoal - calories) kcal")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            ProgressView(value: calorieProgress)
                .progressViewStyle(CustomProgressViewStyle(color: .green))
                .onTapGesture {
                    showMacros.toggle()
                }
            if showMacros {
                VStack {
                    HStack {
                        Text("Protein")
                            //.font(.title2)
                            .foregroundColor(.gray)
                        ProgressView(value: proteinProgress)
                            .progressViewStyle(CustomProgressViewStyle(color: .green))
                        AdaptiveText(text: "\(protein) / \(proteinGoal) g", font: .caption, color: .gray)
                    }
                    HStack {
                        Text("Fat")
                            //.font(.title2)
                            .foregroundColor(.gray)
                        ProgressView(value: fatProgress)
                            .progressViewStyle(CustomProgressViewStyle(color: .green))
                        AdaptiveText(text: "\(fat) / \(fatGoal) g", font: .caption, color: .gray)
                    }
                    HStack {
                        Text("Carbs")
                           // .font(.title2)
                            .foregroundColor(.gray)
                        ProgressView(value: carbsProgress)
                            .progressViewStyle(CustomProgressViewStyle(color: .green))
                        AdaptiveText(text: "\(carbs) / \(carbsGoal) g", font: .caption, color: .gray)
                    }
                }
                .frame(maxWidth: .infinity)
                //.padding()
                .background(Color.gray.opacity(0.1))
                //.cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

import SwiftUI
import HealthKit

struct SleepView: View {
    var sleepSamples: [HKCategorySample]
    var sleepGoal: Int
    var totalInBedDuration: Double
    var totalAsleepDuration: Double

    var body: some View {
        let inBedProgress = min(max(totalInBedDuration / Double(sleepGoal), 0.0), 1.0)
        let asleepProgress = min(max(totalAsleepDuration / Double(sleepGoal), 0.0), 1.0)
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack {
                    Image(systemName: "bed.double.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text("Sleep")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                AdaptiveText(text: "\(String(format: "%.1f", totalAsleepDuration)) / \(sleepGoal) hrs", font: .title2, color: .blue)
                Spacer()
                Text("Remaining: \(String(format: "%.1f", Double(sleepGoal) - totalAsleepDuration)) hrs")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            ProgressView(value: asleepProgress)
                .progressViewStyle(CustomProgressViewStyle(color: .green))
            /*Text("In Bed: \(String(format: "%.1f", totalInBedDuration)) hrs")
                .font(.caption)
                .foregroundColor(.gray)
            ProgressView(value: inBedProgress)
                .progressViewStyle(CustomProgressViewStyle(color: .green))*/
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

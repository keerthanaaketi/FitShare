import SwiftUI

struct StepView: View {
    var stepCount: Int
    var stepGoal: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let backgroundColor = colorScheme == .dark ? Color.gray.opacity(0.3) : Color.black.opacity(0.1)
        let progress = min(max(Double(stepCount) / Double(stepGoal), 0.0), 1.0)
        let goalReached = stepCount >= stepGoal
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack {
                    Image(systemName: "figure.walk")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text("Steps")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                AdaptiveText(text: "\(stepCount) / \(stepGoal)", font: .title2, color: .blue)
                Spacer()
                if goalReached {
                    Text("Smashed it!")
                        .foregroundColor(.green)
                        .font(.caption)
                        .fontWeight(.bold)
                } else {
                    Text("Remaining: \(stepGoal - stepCount)")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            ProgressView(value: progress)
                .progressViewStyle(CustomProgressViewStyle(color: .green))
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

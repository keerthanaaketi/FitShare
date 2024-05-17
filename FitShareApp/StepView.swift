import SwiftUI

struct StepView: View {
    var stepCount: Int
    var stepGoal: Int
    
    var body: some View {
        let progress = min(max(Double(stepCount) / Double(stepGoal), 0.0), 1.0)
        
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
                Text("Remaining: \(stepGoal - stepCount)")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            ProgressView(value: progress)
                .progressViewStyle(CustomProgressViewStyle(color: .green))
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

import SwiftUI

struct CustomProgressViewStyle: ProgressViewStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(width: max(0, min(CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, geometry.size.width)), height: 10)
            }
        }
        .frame(height: 10)
    }
}

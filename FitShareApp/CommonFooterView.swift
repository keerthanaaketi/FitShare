import SwiftUI

struct CommonFooterView: View {
    @Binding var isPresentingView: Bool
    var refreshAction: () -> Void
    var captureScreenshot: () -> Void
    @ObservedObject var viewHelper = ViewHelper()

    var body: some View {
        HStack {
            Button(action: {
                refreshAction()
            }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
            Spacer()
            Button(action: {
                viewHelper.captureScreenshot()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
                    .font(.system(size: 35))
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
            .padding()
            .onChange(of: viewHelper.readyToPresentActivityView) { newValue in
                if newValue {
                    DispatchQueue.main.async {
                        viewHelper.isPresentingActivityViewController = true
                        viewHelper.readyToPresentActivityView = false
                    }
                }
            }
            .sheet(isPresented: $viewHelper.isPresentingActivityViewController) {
                if let screenshotImage = viewHelper.screenshot {
                    ActivityViewController(activityItems: [screenshotImage], onDismiss: {
                        viewHelper.isPresentingActivityViewController = false
                        viewHelper.screenshot = nil
                    })
                }
            }
            Spacer()
            Button(action: {
                isPresentingView = false
            }) {
                Image(systemName: "house.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.bottom, 20)
    }
}

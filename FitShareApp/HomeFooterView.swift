//
//  HomeFooterView.swift
//  FitShareApp
//
//  Created by Keerthanaa Vm on 21/05/24.
//

import Foundation
import SwiftUI
import FirebaseAnalytics

struct HomeFooterView: View {
    @Binding var isPresentingView: Bool
    var refreshData: (Date) -> Void
    @Binding var showSettings: Bool
    @Binding var showDatePicker: Bool
    @Binding var selectedDate: Date
    @Binding var screenshot: UIImage?
    @Binding var isPresentingImagePicker: Bool
    @Binding var selectedImage: UIImage?
    @Binding var headerHeight: CGFloat
    @Binding var footerHeight: CGFloat
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                showSettings.toggle()
            }) {
                Image(systemName: "gearshape.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .font(.system(size: 30))
                    .frame(width: 45, height: 45)
            }
            Spacer()
            Button(action: {
                showDatePicker.toggle()
            }) {
                ZStack {
                    Image(systemName: "calendar.circle.fill")
                        .imageScale(.large)
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                        .frame(width: 45, height: 45)
                }
            }.sheet(isPresented: $showDatePicker) {
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxHeight: 400)
                    Button("Submit") {
                        showDatePicker = false
                        refreshData(selectedDate)
                    }
                    .padding(.top)
                }
                .padding()
            }
            Spacer()
            Button(action: {
                Analytics.logEvent("screenshot_capture_initiated", parameters: [
                    "description": "User initiated screenshot capture" as NSObject
                ])
                ScreenshotManager.shared.capture { capturedImage in
                    DispatchQueue.main.async {
                        screenshot = capturedImage
                        if capturedImage != nil {
                            // Do something with the screenshot
                        }
                    }
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.large)
                    .font(.system(size: 35))
                    .foregroundColor(.blue)
                    .frame(width: 45, height: 45)
            }
            .padding()
            Spacer()
            Button(action: {
                refreshData(selectedDate)
            }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .font(.system(size: 30))
                    .frame(width: 45, height: 45)
            }
            Spacer()
            Button(action: {
                isPresentingImagePicker = true
            }) {
                Image(systemName: "camera.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                    .font(.system(size: 30))
                    .frame(width: 45, height: 45)
            }
            .sheet(isPresented: $isPresentingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if let image = selectedImage {
                            // Upload image
                        }
                    }
            }
            Spacer()
        }
        .background(GeometryReader { geometry in
            Color.clear.onAppear {
                footerHeight = geometry.size.height
            }
        })
    }
}

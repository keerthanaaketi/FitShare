import SwiftUI
import FirebaseStorage

struct TransformationView: View {
    @ObservedObject var viewHelper: ViewHelper
    @State private var beforeDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var afterDate: Date = Date()
    @State private var isPresentingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var currentImageDate: Date?

    var body: some View {
        VStack {
            Text("Transformation")
                .font(.largeTitle)
                .padding()

            HStack {
                VStack {
                    DatePicker(
                        "Before",
                        selection: $beforeDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: beforeDate) { _ in
                        viewHelper.fetchImage(for: beforeDate)
                        viewHelper.getWeightString(for: beforeDate)
                    }

                    ZStack {
                        if let beforeImage = viewHelper.imageForDate(beforeDate) {
                            Image(uiImage: beforeImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .onLongPressGesture {
                                    viewHelper.deleteImage(for: beforeDate)
                                }
                        } else {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .onTapGesture {
                                    currentImageDate = beforeDate
                                    isPresentingImagePicker = true
                                }
                        }
                        if let weight = viewHelper.weightForDate(beforeDate), !weight.isEmpty {
                            Circle()
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(weight)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                )
                                .position(x: 75, y: 75) // Adjust the position as needed
                        }
                    }
                }

                VStack {
                    DatePicker(
                        "After",
                        selection: $afterDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: afterDate) { _ in
                        viewHelper.fetchImage(for: afterDate)
                        viewHelper.getWeightString(for: afterDate)
                    }

                    ZStack {
                        if let afterImage = viewHelper.imageForDate(afterDate) {
                            Image(uiImage: afterImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .onLongPressGesture {
                                    viewHelper.deleteImage(for: afterDate)
                                }
                        } else {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .onTapGesture {
                                    currentImageDate = afterDate
                                    isPresentingImagePicker = true
                                }
                        }
                        if let weight = viewHelper.weightForDate(afterDate), !weight.isEmpty {
                            Circle()
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(weight)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                )
                                .position(x: 75, y: 75) // Adjust the position as needed
                        }
                    }
                }
            }
            .padding()

            Spacer()

        }
        .sheet(isPresented: $isPresentingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                .onDisappear {
                    if let image = selectedImage, let date = currentImageDate {
                        viewHelper.setImage(image, for: date)
                        viewHelper.uploadImage(image, for: date)
           // Update the local image cache
                    }
                }
        }
    }
}

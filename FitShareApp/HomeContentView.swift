import SwiftUI
import HealthKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAnalytics
import FirebaseStorage

struct HomeContentView: View {
    @Binding var selectedImage: UIImage?
    @Binding var imageURL: String?
    @Binding var isPresentingImagePicker: Bool
    @Binding var selectedDate: Date
    @Binding var headerHeight: CGFloat
    @Binding var footerHeight: CGFloat
    
    @Binding var stepCount: Double
    @Binding var weight: Double
    @Binding var calories: Double
    @Binding var totalInBedDuration: Double
    @Binding var totalAsleepDuration: Double
    @Binding var workouts: [HKWorkout]
    
    @Binding var stepPosition: CGPoint
    @Binding var workoutPosition: CGPoint
    @Binding var sleepPosition: CGPoint
    @Binding var nutritionPosition: CGPoint
    @Binding var weightPosition: CGPoint
    
    @Binding var showDeleteIconStep: Bool
    @Binding var showDeleteIconWorkout: Bool
    @Binding var showDeleteIconSleep: Bool
    @Binding var showDeleteIconNutrition: Bool
    @Binding var showDeleteIconWeight: Bool
    @Binding var showDeleteIcon: Bool
    
    @Binding var isStepsDeleted: Bool
    @Binding var isWorkoutDeleted: Bool
    @Binding var isSleepDeleted: Bool
    @Binding var isNutritionDeleted: Bool
    @Binding var isWeightDeleted: Bool
    
    @Binding var isWeightViewPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    var shareList: ShareList
    var goalModel: GoalModel
    var refreshData: (Date) -> Void
    var viewHelper: ViewHelper
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .position(x: geometry.size.width / 2, y: (geometry.size.height - headerHeight + 100) / 2)
                        .onTapGesture {
                            withAnimation {
                                showDeleteIconStep = false
                                showDeleteIconWorkout = false
                                showDeleteIconSleep = false
                                showDeleteIconNutrition = false
                                showDeleteIconWeight = false
                                showDeleteIcon = false
                            }
                        }
                        .onLongPressGesture {
                            withAnimation {
                                showDeleteIcon.toggle()
                            }
                        }
                        .overlay(
                            VStack {
                                HStack {
                                    if showDeleteIcon {
                                        Button(action: {
                                            deleteImage()
                                            selectedImage = nil
                                            showDeleteIcon = false
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .padding(5)
                                        }
                                    }
                                }
                            }
                            .offset(x: geometry.size.width / 2 - 20, y: -(geometry.size.height - headerHeight) / 2 - 50)
                        )
                }
                
                // Draggable circles
                if !isStepsDeleted && shareList.showSteps {
                    DraggableCircle(value: $stepCount, goal: Double(goalModel.stepGoal), title: "Steps", unit: "steps", color: .blue, position: $stepPosition, boundary: CGRect(x: 0, y: headerHeight - 30, width: geometry.size.width, height: geometry.size.height - headerHeight - 30), showDeleteIcon: $showDeleteIconStep) {
                        isStepsDeleted = true
                    }
                }
                if !isWeightDeleted && shareList.showWeight {
                    let weightColor = colorScheme == .dark ? Color.gray : Color.gray
                    DraggableCircle(value: $weight, goal: nil, title: "Weight", unit: "kg", color: weightColor, position: $weightPosition, boundary: CGRect(x: 0, y: headerHeight - 30, width: geometry.size.width, height: geometry.size.height - headerHeight - 30), showDeleteIcon: $showDeleteIconWeight) {
                        isWeightDeleted = true
                    }.onTapGesture {
                        isWeightViewPresented = true
                    }
                }
                if !isNutritionDeleted && shareList.showNutrition {
                    DraggableCircle(value: $calories, goal: Double(goalModel.nutritionGoal), title: "Nutrition", unit: "kcal", color: .yellow, position: $nutritionPosition, boundary: CGRect(x: 0, y: headerHeight - 30, width: geometry.size.width, height: geometry.size.height - headerHeight - 30), showDeleteIcon: $showDeleteIconNutrition) {
                        isNutritionDeleted = true
                    }
                }
                if !isSleepDeleted && shareList.showSleep {
                    DraggableCircle(value: $totalAsleepDuration, goal: Double(goalModel.sleepGoal), title: "Sleep", unit: "hours", color: .green, position: $sleepPosition, boundary: CGRect(x: 0, y: headerHeight - 30, width: geometry.size.width, height: geometry.size.height - headerHeight - 30), showDeleteIcon: $showDeleteIconSleep) {
                        isSleepDeleted = true
                    }
                }
                var totalMinutes: Int {
                    workouts.reduce(0) { total, workout in
                        return total + Int(workout.duration / 60)
                    }
                }
                if !isWorkoutDeleted && shareList.showWorkout {
                    DraggableCircle(value: .constant(Double(totalMinutes)), goal: Double(goalModel.workoutsGoal) ?? nil, title: "Workouts", unit: "Mins", color: .red, position: $workoutPosition, boundary: CGRect(x: 0, y: headerHeight - 30, width: geometry.size.width, height: geometry.size.height - headerHeight - 30), showDeleteIcon: $showDeleteIconWorkout) {
                        isWorkoutDeleted = true
                    }
                }
                
                // Navigation buttons
                if selectedDate < Date() {
                    HStack {
                        Button(action: {
                            navigateToPreviousDay()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .foregroundColor(contrastColor(for: .blue))
                        }
                        .padding()
                        Spacer()
                        if selectedDate < Date() {
                            Button(action: {
                                navigateToNextDay()
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title)
                                    .foregroundColor(contrastColor(for: .blue))
                            }
                            .padding()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 {
                            navigateToPreviousDay()
                        } else if value.translation.width < -100 && selectedDate < Date() {
                            navigateToNextDay()
                        }
                    }
            )
        }
    }
    
    func deleteImage() {
        guard let userID = getUserID() else { return }
        let dateString = viewHelper.getFormattedDate(date: selectedDate)
        
        // Remove the image URL from the database
        let dbRef = Database.database().reference()
        dbRef.child("users/\(userID)/images/\(dateString)").removeValue { error, _ in
            if error != nil {
                print("Failed to delete image URL: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                print("Image URL deleted successfully")
                // Optionally, delete the image from Firebase Storage
                let storageRef = Storage.storage().reference().child("images/\(userID)/\(dateString).jpg")
                storageRef.delete { error in
                    if let error = error {
                        print("Failed to delete image from storage: \(error.localizedDescription)")
                    } else {
                        print("Image deleted from storage successfully")
                    }
                }
            }
        }
    }
    
    func contrastColor(for color: Color) -> Color {
        let components = color.cgColor?.components ?? [0.0, 0.0, 0.0]
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness < 0.5 ? .white : .black
    }
    
    func navigateToPreviousDay() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
        selectedDate = previousDay
        refreshData(previousDay)
    }
    
    func navigateToNextDay() {
        guard selectedDate < Calendar.current.startOfDay(for: Date()) else { return }
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
        selectedDate = nextDay
        refreshData(nextDay)
    }
}

import SwiftUI
import HealthKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAnalytics
import FirebaseStorage

let healthStore = HKHealthStore()

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.completionWithItemsHandler = { _, _, _, _ in
            self.onDismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

public struct HomeScreenView: View {
    let healthStore = HKHealthStore()
    @State private var stepCount: Int = 0
    @State private var workouts: [HKWorkout] = []
    @State private var sleepSamples: [HKCategorySample] = []
    @State var calories: Int = 0
    @State var protein: Int = 0
    @State var fat: Int = 0
    @State var carbohydrates: Int = 0
    @State var weight: Double = 0.0
    @ObservedObject var phoneViewModel: PhoneViewModel
    @ObservedObject var goalModel: GoalModel
    @State private var showSettings = false
    @ObservedObject var shareList: ShareList
    @State private var isPresentingActivityViewController = false
    @State private var screenshot: UIImage? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var isDarkTheme = true
    @State private var readyToPresentActivityView = false
    @State private var totalInBedDuration: Double = 0.0
    @State private var totalAsleepDuration: Double = 0.0
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    @State private var isWeightDeleted = false
    @State private var isStepsDeleted = false
    @State private var isWorkoutDeleted = false
    @State private var isNutritionDeleted = false
    @State private var isSleepDeleted = false
    
    // Image Picker
    @State private var isPresentingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String? = nil
    @State private var showDeleteIcon = false
    @State private var isRefreshing = false

    public var body: some View {
        let imageName = isDarkTheme ? "FitShareDark" : "FitShareLaunch"
        ZStack {
            VStack {
                // Header
                HStack {
                    Button(action: {
                        self.showSettings.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button(action: {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
                        refreshData(for: selectedDate)
                    }) {
                        Image(systemName: "arrow.left")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showDatePicker.toggle()
                    }) {
                            Text(selectedDate, style: .date)
                                .foregroundColor(.blue)
                                .font(.title3)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                    }
                    .sheet(isPresented: $showDatePicker) {
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
                                refreshData(for: selectedDate)
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                    
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
                            refreshData(for: selectedDate)
                        }) {
                            Image(systemName: "arrow.right")
                                .imageScale(.large)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                    Button(action: {
                        isPresentingImagePicker = true
                    }) {
                        Image(systemName: "camera")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $isPresentingImagePicker) {
                        ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                            .onDisappear {
                                if let image = selectedImage {
                                    uploadImage(image)
                                }
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .padding(.top)
                HStack{
                    if shareList.showUserName, !goalModel.userName.isEmpty {
                        Text("\(goalModel.userName)'s day")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                // Scrollable Content with Pull-to-Refresh
                RefreshableScrollView(isRefreshing: $isRefreshing, action: {
                    refreshData(for: selectedDate)
                }) {
                    VStack(spacing: 10) {
                        HStack {
                            if !isWeightDeleted {
                                WeightEntryView(weight: $weight, healthStore: healthStore, date: selectedDate)
                                    .swipeToDelete(isDeleted: $isWeightDeleted)
                            }
                            if selectedImage != nil {
                                if let selectedImage = selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 150, height: 200)
                                            .cornerRadius(10)
                                            .onLongPressGesture {
                                                withAnimation {
                                                    showDeleteIcon.toggle()
                                                }
                                            }
                                        
                                        if showDeleteIcon {
                                            Button(action: {
                                                withAnimation {
                                                    self.selectedImage = nil
                                                    self.showDeleteIcon = false
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .padding()
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        
                        if !isStepsDeleted && shareList.showSteps {
                            StepView(stepCount: stepCount, stepGoal: Int(goalModel.stepGoal) ?? 0)
                                .swipeToDelete(isDeleted: $isStepsDeleted)
                        }
                        if !isWorkoutDeleted && shareList.showWorkout{
                            WorkoutView(workouts: workouts, workoutGoal: Int(goalModel.workoutsGoal) ?? 0)
                                .swipeToDelete(isDeleted: $isWorkoutDeleted)
                        }
                        if !isNutritionDeleted && shareList.showNutrition{
                            NutritionView(calories: calories, protein: protein, fat: fat, carbs: carbohydrates, nutritionGoal: Int(goalModel.nutritionGoal) ?? 0, proteinGoal: Int(goalModel.proteinGoal) ?? 0, fatGoal: Int(goalModel.fatsGoal) ?? 0, carbsGoal: Int(goalModel.carbsGoal) ?? 0)
                                .swipeToDelete(isDeleted: $isNutritionDeleted)
                        }
                        if !isSleepDeleted && shareList.showSleep{
                            SleepView(sleepSamples: sleepSamples, sleepGoal: Int(goalModel.sleepGoal) ?? 8, totalInBedDuration: totalInBedDuration, totalAsleepDuration: totalAsleepDuration)
                                .swipeToDelete(isDeleted: $isSleepDeleted)
                        }
                    }
                }
            }
            .onAppear {
                isDarkTheme = (colorScheme == .dark)
                if let userID = getUserID() {
                    getUserData(userID: userID) { userData in
                        if let goalStepCount = userData?["goalStepCount"] as? Int,
                           let goalNutritionCount = userData?["goalNutrition"] as? Int,
                           let goalProtein = userData?["goalProtein"] as? Int,
                           let goalFat = userData?["goalFat"] as? Int,
                           let goalCarbs = userData?["goalCarbs"] as? Int,
                           let goalWorkouts = userData?["goalWorkouts"] as? Int,
                           let goalSleep = userData?["goalSleep"] as? Int,
                           let showStep = userData?["showStep"] as? Bool,
                           let showWorkout = userData?["showWorkout"] as? Bool,
                           let showNutrition = userData?["showNutrition"] as? Bool,
                           let showSleep = userData?["showSleep"] as? Bool,
                            let showUserName = userData?["showUserName"] as? Bool{
                            goalModel.stepGoal = String(goalStepCount)
                            goalModel.nutritionGoal = String(goalNutritionCount)
                            goalModel.proteinGoal = String(goalProtein)
                            goalModel.fatsGoal = String(goalFat)
                            goalModel.carbsGoal = String(goalCarbs)
                            goalModel.workoutsGoal = String(goalWorkouts)
                            goalModel.sleepGoal = String(goalSleep)
                            shareList.showUserName = showUserName
                            shareList.showSteps = showStep
                            shareList.showNutrition = showNutrition
                            shareList.showWorkout = showWorkout
                            shareList.showSleep = showSleep
                            goalModel.userName = userData?["userName"] as! String
                        }
                    }
                }
                requestAuthorization()
                refreshData(for: selectedDate)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
            }

            // Share button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        Analytics.logEvent("screenshot_capture_initiated", parameters: [
                            "description": "User initiated screenshot capture" as NSObject
                        ])
                        ScreenshotManager.shared.capture { capturedImage in
                            DispatchQueue.main.async {
                                self.screenshot = capturedImage
                                if capturedImage != nil {
                                    self.readyToPresentActivityView = true
                                }
                            }
                        }
                    }) {
                        Image(imageName)
                            .resizable()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .shadow(color: colorScheme == .dark ? .gray : .black, radius: 10)
                           // .overlay(
                             //   Circle()
                               //     .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2)
                            //)
                    }
                    .padding()
                    .onChange(of: readyToPresentActivityView) { newValue in
                        if newValue {
                            DispatchQueue.main.async {
                                self.isPresentingActivityViewController = true
                                self.readyToPresentActivityView = false
                            }
                        }
                    }
                    .sheet(isPresented: self.$isPresentingActivityViewController) {
                        if let screenshotImage = self.screenshot {
                            ActivityViewController(activityItems: [screenshotImage], onDismiss: {
                                self.isPresentingActivityViewController = false
                                self.screenshot = nil
                            })
                        }
                    }
                }
            }
        }
    }

    func requestAuthorization() {
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)! // Added body mass (weight) to read
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)! // Added body mass (weight) to write
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if success {
                print("Authorization granted")
            } else if let error = error {
                print("Authorization error: \(error.localizedDescription)")
            }
        }
    }

    func refreshData(for date: Date) {
        isWeightDeleted = false
        isStepsDeleted = false
        isWorkoutDeleted = false
        isNutritionDeleted = false
        isSleepDeleted = false
        refreshStepCount(for: date)
        fetchWorkouts(for: date)
        fetchSleepData(for: date)
        fetchNutritionData(for: date)
        fetchWeight(for: date)
    }
    
    func refreshStepCount(for date: Date) {
        readStepCount(for: date, healthStore: healthStore) { stepCountValue in
            self.stepCount = stepCountValue
        }
    }

    func readStepCount(for date: Date, healthStore: HKHealthStore, completion: @escaping (Int) -> Void) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("Query error: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            
            self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            completion(stepCount)
        }
        
        healthStore.execute(query)
    }
    
    func fetchWorkouts(for date: Date) {
        let workoutType = HKObjectType.workoutType()
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            if let activities = samples as? [HKWorkout] {
                DispatchQueue.main.async {
                    self.workouts = activities
                }
            }
        }
        
        healthStore.execute(query)
        print(workouts.count)
    }
    
    func fetchSleepData(for date: Date) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current

        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, samples, error in
            guard error == nil else {
                print("Error fetching sleep data: \(String(describing: error))")
                return
            }

            if let sleepSamples = samples as? [HKCategorySample] {
                DispatchQueue.main.async {
                    let inBedSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
                    let asleepSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue}

                    let totalInBedDurationInSeconds = inBedSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    let totalAsleepDurationInSeconds = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

                    self.sleepSamples = sleepSamples
                    self.totalInBedDuration = totalInBedDurationInSeconds / 3600 // Convert to hours
                    self.totalAsleepDuration = totalAsleepDurationInSeconds / 3600 // Convert to hours
                }
            }
        }

        HKHealthStore().execute(query)
    }

    func fetchWeight(for date: Date) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, _ in
            if let result = results?.first as? HKQuantitySample {
                DispatchQueue.main.async {
                    self.weight = result.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                }
            }
        }
        healthStore.execute(query)
    }

    func fetchNutritionData(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let energyConsumedQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
                }
            }
            else{
                self.calories = 0;
            }
        }
        
        let proteinQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.protein = Int(sum.doubleValue(for: HKUnit.gram()))
                }
            }
            else{
                self.protein = 0;
            }
        }
        
        let fatQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.fat = Int(sum.doubleValue(for: HKUnit.gram()))
                }
            }
            else{
                self.fat = 0;
            }
        }
        
        let carbsQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.carbohydrates = Int(sum.doubleValue(for: HKUnit.gram()))
                }
            }
            else{
                self.carbohydrates = 0;
            }
        }
        
        healthStore.execute(energyConsumedQuery)
        healthStore.execute(proteinQuery)
        healthStore.execute(fatQuery)
        healthStore.execute(carbsQuery)
    }

    func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            guard metadata != nil else {
                print("Failed to upload image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Failed to get download URL: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.imageURL = downloadURL.absoluteString
                // Save the download URL to your Firebase Realtime Database or Firestore
            }
        }
    }
}

// PullToRefresh modifier
struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    let content: () -> Content
    
    var body: some View {
        ScrollView {
            VStack {
                if isRefreshing {
                    ProgressView()
                        .padding()
                }
                content()
            }
            .background(GeometryReader { geo -> Color in
                let offsetY = geo.frame(in: .global).origin.y
                if offsetY > 150 {
                    DispatchQueue.main.async {
                        if !isRefreshing {
                            isRefreshing = true
                            action()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isRefreshing = false
                            }
                        }
                    }
                }
                return Color.clear
            })
        }
    }
}

// SwipeToDelete modifier
struct SwipeToDeleteModifier: ViewModifier {
    @Binding var isDeleted: Bool
    @State private var offset: CGFloat = 0.0
    
    func body(content: Content) -> some View {
        ZStack {
            if isDeleted {
                Color.red
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10)
                    .padding(.vertical, 8)
                
                HStack {
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding(.trailing, 20)
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                .padding(.vertical, 8)
            }
            
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < -50 {
                                withAnimation {
                                    offset = value.translation.width
                                }
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -150 {
                                withAnimation {
                                    isDeleted = true
                                }
                            } else {
                                withAnimation {
                                    offset = 0
                                }
                            }
                        }
                )
        }
    }
}

extension View {
    func swipeToDelete(isDeleted: Binding<Bool>) -> some View {
        self.modifier(SwipeToDeleteModifier(isDeleted: isDeleted))
    }
}


struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}

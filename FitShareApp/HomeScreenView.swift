import SwiftUI
import HealthKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAnalytics

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

    public var body: some View {
        let imageName = isDarkTheme ? "FitShareDark" : "FitShareLaunch"
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
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
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
                    Image(systemName: "square.and.arrow.up")
                        .font(.title)
                        .foregroundColor(.blue)
                }
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
            .padding(.horizontal)
            .padding(.top)

            // Refresh and Date Options
            HStack {
                Button("Refresh") {
                    if let userID = getUserID() {
                        getUserData(userID: userID) { userData in
                            if let goalStepCount = userData?["goalStepCount"] as? Int,
                               let goalNutritionCount = userData?["goalNutrition"] as? Int,
                               let goalProtein = userData?["goalProtein"] as? Int,
                               let goalFat = userData?["goalFat"] as? Int,
                               let goalCarbs = userData?["goalCarbs"] as? Int,
                               let goalWorkouts = userData?["goalWorkouts"] as? Int,
                               let goalSleep = userData?["goalSleep"] as? Int {
                                goalModel.stepGoal = String(goalStepCount)
                                goalModel.nutritionGoal = String(goalNutritionCount)
                                goalModel.proteinGoal = String(goalProtein)
                                goalModel.fatsGoal = String(goalFat)
                                goalModel.carbsGoal = String(goalCarbs)
                                goalModel.workoutsGoal = String(goalWorkouts)
                                goalModel.sleepGoal = String(goalSleep)
                            }
                        }
                    }
                    refreshData(for: selectedDate)
                }
                .padding(.horizontal)
                
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
                        .font(.title2)
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
            }
            .padding(.horizontal)

            // Scrollable Content
            ScrollView {
                VStack(spacing: 20) {
                    if shareList.showSteps {
                        StepView(stepCount: stepCount, stepGoal: Int(goalModel.stepGoal) ?? 0)
                    }
                    if shareList.showWorkout {
                        WorkoutView(workouts: workouts, workoutGoal: Int(goalModel.workoutsGoal) ?? 0)
                    }
                    if shareList.showNutrition {
                        NutritionView(calories: calories, protein: protein, fat: fat, carbs: carbohydrates, nutritionGoal: Int(goalModel.nutritionGoal) ?? 0, proteinGoal: Int(goalModel.proteinGoal) ?? 0, fatGoal: Int(goalModel.fatsGoal) ?? 0, carbsGoal: Int(goalModel.carbsGoal) ?? 0)
                    }
                    if shareList.showSleep {
                        SleepView(sleepSamples: sleepSamples, sleepGoal: Int(goalModel.sleepGoal) ?? 8, totalInBedDuration: totalInBedDuration, totalAsleepDuration: totalAsleepDuration)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
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
                       let showSleep = userData?["showSleep"] as? Bool {
                        goalModel.stepGoal = String(goalStepCount)
                        goalModel.nutritionGoal = String(goalNutritionCount)
                        goalModel.proteinGoal = String(goalProtein)
                        goalModel.fatsGoal = String(goalFat)
                        goalModel.carbsGoal = String(goalCarbs)
                        goalModel.workoutsGoal = String(goalWorkouts)
                        goalModel.sleepGoal = String(goalSleep)
                        shareList.showSteps = showStep
                        shareList.showNutrition = showNutrition
                        shareList.showWorkout = showWorkout
                        shareList.showSleep = showSleep
                    }
                }
            }
            requestAuthorization()
            refreshData(for: selectedDate)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
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
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("Authorization granted")
            } else if let error = error {
                print("Authorization error: \(error.localizedDescription)")
            }
        }
    }

    func refreshData(for date: Date) {
        refreshStepCount(for: date)
        fetchWorkouts(for: date)
        fetchSleepData(for: date)
        fetchNutritionData(for: date)
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
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}

import SwiftUI
import HealthKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseAnalytics
import FirebaseStorage

let healthStore = HKHealthStore()

struct HomeScreenView: View {
    let healthStore = HKHealthStore()
    @State private var stepCount: Double = 0
    @State private var workouts: [HKWorkout] = []
    @State private var sleepSamples: [HKCategorySample] = []
    @State var calories: Double = 0
    @State var protein: Double = 0
    @State var fat: Double = 0
    @State var carbohydrates: Double = 0
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
    @State private var showDeleteIconStep = false
    @State private var showDeleteIconWorkout = false
    @State private var showDeleteIconSleep = false
    @State private var showDeleteIconNutrition = false
    @State private var showDeleteIconWeight = false
    @State private var isPresentingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String? = nil
    @State private var showDeleteIcon = false
    @State private var isRefreshing = false
    @State private var stepPosition = CGPoint(x: 200, y: 150)
    @State private var workoutPosition = CGPoint(x: 300, y: 150)
    @State private var sleepPosition = CGPoint(x: 250, y: 250)
    @State private var nutritionPosition = CGPoint(x: 150, y: 250)
    @State private var weightPosition = CGPoint(x: 100, y: 150)
    @State private var stepTargetPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: 100)
    @State private var workoutTargetPosition = CGPoint(x: UIScreen.main.bounds.width - 50, y: 100)
    @State private var sleepTargetPosition = CGPoint(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height - 500)
    @State private var nutritionTargetPosition = CGPoint(x: 50, y: UIScreen.main.bounds.height - 500)
    @State private var weightTargetPosition = CGPoint(x: 50, y: 100)
    @State private var headerHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var isPresentingWeightView = false
    @State private var isWeightViewPresented = false
    @State private var isStepsViewPresented = false
    @State private var isWorkoutViewPresented = false
    @State private var isNutritionViewPresented = false
    @ObservedObject var viewHelper = ViewHelper()
    @State private var showTransformationPopup = false
    @State private var showTransformationView = false
    @State private var beforeDate = Date()
    @State private var afterDate = Date()
    @State private var userName = ""

    public var body: some View {
        let imageName = isDarkTheme ? "FitShareDark" : "FitShareLaunch"
        let backgroundColor = colorScheme == .dark ? Color.white : Color.black

        VStack {
            // Header
            HStack {
                Spacer()
                Spacer()
                VStack {
                    Image(imageName) // Use appropriate logo based on theme
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 90)
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                headerHeight = geometry.size.height
                            }
                        })
                    HStack{
                        if !isWeightViewPresented && !showTransformationView {
                            Text("\(selectedDate, formatter: DateFormatter.shortDate) ").font(.title2).italic()
                            //    .padding()
                            //.foregroundColor(.blue)
                            if !goalModel.userName.isEmpty && shareList.showUserName{
                                Text("\(goalModel.userName)'s day").font(.headline).italic()
                                //.foregroundColor(.blue).italic()
                        }
                    }
                    }
                }
                Spacer()
                if !isWeightViewPresented && !showTransformationView {
                    Button(action: {
                        showDatePicker.toggle()
                    }) {
                        Image(systemName: "calendar.circle.fill")
                            .imageScale(.large)
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .frame(width: 35, height: 35)
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
                            .padding(.horizontal)
                        }
                    }
                }
              //  Spacer()
            }
            .padding(.top)

            if isWeightViewPresented {
                WeightView(isPresentingWeightView: $isWeightViewPresented, weight: $weight, selectedDate: $selectedDate, healthStore: healthStore, viewHelper: viewHelper)
            } else if isStepsViewPresented {
                // StepsView
            } else if isWorkoutViewPresented {
                // WorkoutView
            } else if isNutritionViewPresented {
                // NutritionView
            } else if showTransformationView {
                TransformationView(viewHelper: viewHelper)
            } else {
                GeometryReader { geometry in
                    // Content area with image and circles
                    ZStack {
                        // Background image
                        if let image = viewHelper.imageForDate(selectedDate) {
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
                                                    viewHelper.imagesCache[selectedDate] = nil
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
                                isPresentingWeightView = true
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
                                        .font(.largeTitle)
                                        .padding()
                                        .foregroundColor(contrastColor(for: .blue))
                                }
                                .padding()
                                Spacer()
                                if selectedDate < Date() {
                                    Button(action: {
                                        navigateToNextDay()
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .font(.largeTitle)
                                            .padding()
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

            // Footer
            VStack {
                Divider()
                if isWeightViewPresented {
                    HStack {
                        Spacer()
                        CommonFooterView(isPresentingView: $isWeightViewPresented, refreshAction: {
                            viewHelper.fetchWeightHistory()
                            fetchWeight(for: selectedDate)
                        }, captureScreenshot: {
                            viewHelper.captureScreenshot()
                        })
                    }
                } else if showTransformationView {
                    HStack {
                        Spacer()
                        CommonFooterView(isPresentingView: $showTransformationView, refreshAction: {
                            viewHelper.fetchImage(for: beforeDate)
                            viewHelper.fetchImage(for: afterDate)
                            viewHelper.getWeightString(for: beforeDate)
                            viewHelper.getWeightString(for: afterDate)
                        }, captureScreenshot: {
                            // Screenshot logic
                            viewHelper.captureScreenshot()
                        })
                    }
                } else {
                    HStack {
                        Spacer()
                        Button(action: {
                            self.showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .imageScale(.large)
                                .foregroundColor(.blue)
                                .font(.system(size: 30))
                                .frame(width: 45, height: 45)
                        }
                        Spacer()
                        Button(action: {
                            showTransformationView = true
                        }) {
                            Image(systemName: "figure.flexibility")
                                .imageScale(.large)
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                                .frame(width: 45, height: 45)
                        }
                        /*.sheet(isPresented: $showTransformationPopup) {
                            TransformationPopup(isPresented: $showTransformationPopup, beforeDate: $beforeDate, afterDate: $afterDate, showTransformationView: $showTransformationView)
                        }*/
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
                            refreshData(for: selectedDate)
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
                                        viewHelper.imagesCache[selectedDate] = image
                                        uploadImage(image)
                                        withAnimation(.easeInOut(duration: 1.5)) {
                                            stepPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: headerHeight - 10)
                                            workoutPosition = CGPoint(x: UIScreen.main.bounds.width - 50, y: headerHeight - 10)
                                            sleepPosition = CGPoint(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height - footerHeight - 320) // Adjusted
                                            nutritionPosition = CGPoint(x: 50, y: UIScreen.main.bounds.height - footerHeight - 320) // Adjusted
                                            weightPosition = CGPoint(x: 50, y: headerHeight - 10)
                                        }
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
            .edgesIgnoringSafeArea(.all)
        }
        .background(Color.clear.contentShape(Rectangle()).onTapGesture {
            withAnimation {
                showDeleteIconStep = false
                showDeleteIconWorkout = false
                showDeleteIconSleep = false
                showDeleteIconNutrition = false
                showDeleteIconWeight = false
                showDeleteIcon = false
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                       let imageURL = userData?["imageURL"] as? String,
                       let name = userData?["userName"] as? String {
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
                        goalModel.userName = name
                        self.imageURL = imageURL
                        self.userName = name
                        loadImage(from: imageURL)
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

    private func loadImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.selectedImage = image
                    viewHelper.imagesCache[selectedDate] = image
                    withAnimation(.easeInOut(duration: 1.5)) {
                        stepPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: headerHeight - 10)
                        workoutPosition = CGPoint(x: UIScreen.main.bounds.width - 50, y: headerHeight - 10)
                        sleepPosition = CGPoint(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height - footerHeight - 320) // Adjusted
                        nutritionPosition = CGPoint(x: 50, y: UIScreen.main.bounds.height - footerHeight - 320) // Adjusted
                        weightPosition = CGPoint(x: 50, y: headerHeight - 10)
                    }
                }
            }
        }.resume()
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
        fetchImageURL(for: date)
        showDeleteIcon = false
    }

    func contrastColor(for color: Color) -> Color {
        let components = color.cgColor?.components ?? [0.0, 0.0, 0.0]
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness < 0.5 ? .white : .black
    }

    func refreshStepCount(for date: Date) {
        readStepCount(for: date, healthStore: healthStore) { stepCountValue in
            self.stepCount = Double(stepCountValue)
        }
    }

    func navigateToPreviousDay() {
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? Date()
        selectedDate = previousDay
        refreshData(for: selectedDate)
    }

    func navigateToNextDay() {
        guard selectedDate < Calendar.current.startOfDay(for: Date()) else { return }
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? Date()
        selectedDate = nextDay
        refreshData(for: selectedDate)
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

            let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
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
                    let asleepSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }

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
                    self.calories = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            } else {
                self.calories = 0
            }
        }

        let proteinQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.protein = sum.doubleValue(for: HKUnit.gram())
                }
            } else {
                self.protein = 0
            }
        }

        let fatQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.fat = sum.doubleValue(for: HKUnit.gram())
                }
            } else {
                self.fat = 0
            }
        }

        let carbsQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity() {
                DispatchQueue.main.async {
                    self.carbohydrates = sum.doubleValue(for: HKUnit.gram())
                }
            } else {
                self.carbohydrates = 0
            }
        }

        healthStore.execute(energyConsumedQuery)
        healthStore.execute(proteinQuery)
        healthStore.execute(fatQuery)
        healthStore.execute(carbsQuery)
    }

    func fetchImageURL(for date: Date) {
        guard let userID = getUserID() else {
            print("Failed to get user ID")
            return
        }
        let dateString = getFormattedDate(date: date)

        let dbRef = Database.database().reference()
        dbRef.child("users/\(userID)/images/\(dateString)").observeSingleEvent(of: .value) { snapshot in
            if let imageURL = snapshot.value as? String {
                loadImage(from: imageURL)
            } else {
                self.selectedImage = nil
            }
        }
    }

    func uploadImage(_ image: UIImage) {
        guard let userID = getUserID() else {
            print("Failed to get user ID")
            return
        }
        let dateString = getFormattedDate(date: selectedDate)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return
        }

        let storageRef = Storage.storage().reference().child("images/\(userID)/\(dateString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Failed to upload image: \(error.localizedDescription)")
                return
            }

            print("Image uploaded successfully, getting download URL")

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }

                guard let downloadURL = url else {
                    print("Download URL is nil")
                    return
                }

                self.imageURL = downloadURL.absoluteString
                print("Download URL: \(self.imageURL!)")

                let dbRef = Database.database().reference()
                dbRef.child("users/\(userID)/images/\(dateString)").setValue(self.imageURL) { error, _ in
                    if let error = error {
                        print("Failed to save image URL to database: \(error.localizedDescription)")
                    } else {
                        print("Image URL saved to database successfully")
                    }
                }
            }
        }
    }

    func deleteImage() {
        guard let userID = getUserID() else { return }
        let dateString = getFormattedDate(date: selectedDate)

        let dbRef = Database.database().reference()
        dbRef.child("users/\(userID)/images/\(dateString)").removeValue { error, _ in
            if error != nil {
                print("Failed to delete image URL: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                print("Image URL deleted successfully")
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

    func getFormattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }
}

struct DraggableCircle: View {
    @Binding var value: Double
    var goal: Double?
    var title: String
    var unit: String
    var color: Color
    @Binding var position: CGPoint
    var boundary: CGRect
    @Binding var showDeleteIcon: Bool
    var onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.5))
                    .frame(width: 120, height: 120)
                    .shadow(color: color.opacity(0.5), radius: 10, x: 5, y: 5)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(value / (goal ?? value), 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: -90))
                VStack {
                    Text(title)
                        .font(.caption).bold()
                        .foregroundColor(contrastColor(for: color))
                    if let goal = goal {
                        Text("\(Int(value))")
                            .font(.title).bold()
                            .foregroundColor(contrastColor(for: color))
                        Text("/\(Int(goal)) \(unit)")
                            .font(.caption).bold()
                            .foregroundColor(contrastColor(for: color))
                    } else {
                        Text("\(Int(value)) \(unit)")
                            .font(.caption).bold()
                            .foregroundColor(contrastColor(for: color))
                    }
                }
                if showDeleteIcon {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                onDelete()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .offset(x: -150, y: -50) // Adjusted offset to position the delete button correctly
                }
            }
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newLocation = value.location
                        if boundary.contains(newLocation) {
                            self.position = newLocation
                        }
                    }
                    .onEnded { _ in
                        showDeleteIcon = false
                    }
            )
            .onLongPressGesture {
                withAnimation {
                    showDeleteIcon.toggle()
                }
            }
        }
    }
    
    func contrastColor(for color: Color) -> Color {
        let components = color.cgColor?.components ?? [0.0, 0.0, 0.0]
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness < 0.5 ? .white : .black
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}


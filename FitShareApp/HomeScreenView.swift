//
//  HomeScreenView.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 05/09/23.
//

import Foundation
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
    
    public var body: some View {
        let imageName = isDarkTheme ? "FitShareDark" : "FitShareLaunch"
        ScrollView{
            VStack {
               
                HStack{
                    Spacer()
                    Button(action: {
                        self.showSettings.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    Spacer()
                   // (Text("FitShare").bold().font(.title))
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.black) // Adjust the color of the logo as needed
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                    Spacer()
                    Spacer()
                    HStack {
                        Button(action: {
                            Analytics.logEvent("screenshot_capture_initiated", parameters: [
                                            "description": "User initiated screenshot capture" as NSObject
                                        ])
                            
                            ScreenshotManager.shared.capture { capturedImage in
                                DispatchQueue.main.async {
                                    self.screenshot = capturedImage
                                    // Check if a screenshot was successfully captured before presenting
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
                                // Ensure this logic is run on the main thread
                                DispatchQueue.main.async {
                                    self.isPresentingActivityViewController = true
                                    // Reset the trigger to avoid unintended re-presentations
                                    self.readyToPresentActivityView = false
                                }
                            }
                        }
                        .sheet(isPresented: self.$isPresentingActivityViewController) {
                            if let screenshotImage = self.screenshot {
                                ActivityViewController(activityItems: [screenshotImage], onDismiss: {
                                                    // This closure is called after the ActivityViewController is dismissed
                                                    self.isPresentingActivityViewController = false
                                                    self.screenshot = nil // Optionally reset other relevant state variables
                                                })
                                            }
                        }
                    }
                    Spacer()
                }
                Button("Recheck") {
                    if let userID = getUserID() {
                        getUserData(userID: userID) { userData in
                            if let goalStepCount = userData?["goalStepCount"] as? Int,
                               let goalNutrtionCount = userData?["goalNutrition"] as? Int,
                               let goalProtein = userData?["goalProtein"] as? Int,
                               let goalFat = userData?["goalFat"] as? Int,
                               let goalCarbs = userData?["goalCarbs"] as? Int,
                               let goalWorkouts = userData?["goalWorkouts"] as? Int,
                               let goalSleep = userData?["goalSleep"] as? Int  {
                                goalModel.stepGoal = String(goalStepCount)
                                goalModel.nutritionGoal = String(goalNutrtionCount)
                                goalModel.proteinGoal = String(goalProtein)
                                goalModel.fatsGoal = String(goalFat)
                                goalModel.carbsGoal = String(goalCarbs)
                                goalModel.workoutsGoal = String(goalWorkouts)
                                goalModel.sleepGoal = String(goalSleep)
                            }
                        }
                    }
                    print(phoneViewModel.isSignedIn)
                    refreshStepCount()
                    fetchWorkoutsForToday()
                    fetchSleepData()
                    fetchNutritionData()
                }
                // Text("Disclaimer: Just recheck is not going to > steps")
                
                let stepGoalVal = Int(goalModel.stepGoal) ?? 0
                let remainingSteps = Int(stepGoalVal - stepCount)
                if(shareList.showSteps){
                    SlabView(title: "STEPS",total: String(stepCount),goal: String(Int(stepGoalVal)), remaining: String(remainingSteps))
                    /*if stepCount >= Int(stepGoalVal) {
                        Text("Wohooo you did more than your goal steps")
                            .foregroundColor(.red) // You can adjust the color as needed
                            .font(.caption)
                            .padding(.bottom, 20)
                    }*/
                }
                if(shareList.showWorkout){
                    VStack {
                        var totalCaloriesBurnt: Int {
                            workouts.reduce(0) { total, workout in
                                if let energyBurned = workout.totalEnergyBurned {
                                    return total + Int(energyBurned.doubleValue(for: HKUnit.calorie()))/1000
                                } else {
                                    return total
                                }
                            }
                        }
                        if workouts.isEmpty {
                            HStack{
                                Text("\tWORKOUTS").font(.title2).bold()
                                Spacer()
                            }
                            Text("No workouts today")
                        } else {
                            SlabView(title: "WORKOUTS",
                                     total: "\(totalCaloriesBurnt) cals",
                                     goal: goalModel.workoutsGoal ?? "0",
                                     remaining: String((Int(goalModel.workoutsGoal ?? "0") ?? 0) - totalCaloriesBurnt) )
                            NavigationView {
                                List(workouts, id: \.workoutActivityType) { workout in
                                    VStack(alignment: .leading) {
                                        Text("Activity: \(readableWorkoutActivityType(workout.workoutActivityType))").font(.caption)
                                        var duration = Int(workout.duration / 60)
                                        Text("Duration: \(duration) minutes").font(.caption)
                                    }.padding()
                                }
                            }.frame(width: 390, height: 80)
                        }
                    }
                }
                if(shareList.showNutrition){
                    VStack {
                        NutritionSlabView(title: "NUTRITION",total: "\(calories) Cals",goal: goalModel.nutritionGoal, remaining: String((Int(goalModel.nutritionGoal) ?? 0)-calories),protein: protein,fat: fat,carbs: Int(carbohydrates),proteinGoal: Int(goalModel.proteinGoal) ?? 0,fatGoal: Int(goalModel.fatsGoal) ?? 0,carbsGoal: Int(goalModel.carbsGoal) ?? 0)
                    }
                }
                if(shareList.showSleep){
                    let inBedSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
                
                if !inBedSamples.isEmpty {
                    let totalInBedDurationInSeconds = inBedSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                    
                    let totalInBedDurationInMinutes = Int(totalInBedDurationInSeconds) / 60
                    let hours = totalInBedDurationInMinutes / 60
                    let minutes = totalInBedDurationInMinutes % 60
                    let reminingHours = (Int(goalModel.sleepGoal) ?? 8)-hours
                    SlabView(title: "SLEEP",total: "\(hours) hours \(minutes) minutes",goal: goalModel.sleepGoal, remaining: String(reminingHours))
                } else {
                    HStack{
                        Text("\tSLEEP").font(.title2).bold()
                        Spacer()
                    }
                    Text("No 'In Bed' sleep data available.")
                }
            }
            }.onAppear {
                isDarkTheme = (colorScheme == .dark)
                if let userID = getUserID() {
                    getUserData(userID: userID) { userData in
                        if let goalStepCount = userData?["goalStepCount"] as? Int,
                        let goalNutrtionCount = userData?["goalNutrition"] as? Int,
                        let goalProtein = userData?["goalProtein"] as? Int,
                        let goalFat = userData?["goalFat"] as? Int,
                        let goalCarbs = userData?["goalCarbs"] as? Int,
                        let goalWorkouts = userData?["goalWorkouts"] as? Int,
                        let goalSleep = userData?["goalSleep"] as? Int,
                        let showStep = userData?["showStep"] as? Bool,
                        let showWorkout = userData?["showWorkout"] as? Bool,
                        let showNutrition = userData?["showNutrition"] as? Bool,
                        let showSleep = userData?["showSleep"] as? Bool
                        {
                            goalModel.stepGoal = String(goalStepCount)
                            goalModel.nutritionGoal = String(goalNutrtionCount)
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
                    refreshStepCount()
                    fetchWorkoutsForToday()
                    fetchSleepData()
                    fetchNutritionData()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
            }
        }
    }
        
    struct SlabView: View {
        var title: String
        var total: String
        var goal: String
        var remaining: String
        
        var body: some View {
            VStack{
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray)
                    .frame(width: 390, height: 90)
                    .overlay(VStack {
                        HStack{
                            Text("\t")
                            Text(title)
                                .font(.title2).bold()
                            Spacer()
                            Text(total)
                                .font(.title3)
                            Spacer()
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text("Goal:"+goal)
                                .font(.headline)
                            Spacer()
                            if let remainingInt = Int(remaining), remainingInt > 0 {
                                                        Text("Left: \(remaining)")
                                                            .font(.headline)
                                                    } else {
                                                        Text("Goal Reached")
                                                            .font(.headline)
                                                            .foregroundColor(.green) // Optional: Change color to emphasize completion
                                                    }
                                                    
                           Spacer()
                            
                        }
                    }
                    )
            }
        }
    }
    struct NutritionSlabView: View {
        var title: String
        var total: String
        var goal: String
        var remaining: String
        var protein: Int
        var fat: Int
        var carbs: Int
        var proteinGoal: Int
        var fatGoal: Int
        var carbsGoal: Int
        
        var body: some View {
            VStack{
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray)
                    .frame(width: 390, height: 190)
                    .overlay(VStack {
                        Spacer()
                        HStack{
                            Text("\t")
                            Text(title)
                                .font(.title2).bold()
                            Spacer()
                            Text(total)
                                .font(.title3)
                            Spacer()
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text("Goal:"+goal)
                                .font(.headline)
                            Spacer()
                            if let remainingInt = Int(remaining), remainingInt > 0 {
                                                        Text("Left: \(remaining)")
                                                            .font(.headline)
                                                    } else {
                                                        Text("Goal Reached")
                                                            .font(.headline)
                                                            .foregroundColor(.green) // Optional: Change color to emphasize completion
                                                    }
                                                    
                                                    Spacer()
                            
                        }
                        Text("\n")
                        VStack {
                            HStack {
                                Text("Protein").font(.headline).bold()
                                if proteinGoal - protein > 0 {
                                    Text("total: \(protein) goal: \(proteinGoal) left: \(proteinGoal - protein)").font(.headline)
                                } else if proteinGoal > 0 {
                                    Text("total: \(protein) goal: \(proteinGoal) Goal reached").font(.headline).foregroundColor(.green)
                                }
                                else{
                                    Text("total: \(protein) goal: \(proteinGoal)").font(.headline)
                                }
                            
                            }
                            HStack {
                                Text("Fat").font(.headline).bold()
                                if fatGoal - fat > 0 {
                                    Text("total: \(fat) goal: \(fatGoal) left: \(fatGoal - fat)").font(.headline)
                                } else if fatGoal > 0{
                                    Text("total: \(fat) goal: \(fatGoal) Goal reached").font(.headline).foregroundColor(.green)
                                }else{
                                    Text("total: \(fat) goal: \(fatGoal)").font(.headline)
                                }
                            }
                            HStack {
                                Text("Carbs").font(.headline).bold()
                                if carbsGoal - carbs > 0 {
                                    Text("total: \(carbs) goal: \(carbsGoal) left: \(carbsGoal - carbs)").font(.headline)
                                } else if carbsGoal > 0 {
                                    Text("total: \(carbs) goal: \(carbsGoal)  Goal reached").font(.headline).foregroundColor(.green)
                                }
                                else{
                                    Text("total: \(carbs) goal: \(carbsGoal)").font(.headline)
                                }
                            }
                        }

                        Spacer()
                    }
                    )
            }
        }
    }
    func requestAuthorization() {
        let typesToRead: Set<HKSampleType> = [HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .stepCount)!,HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!, HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("Authorization granted")
                // Now you can read HealthKit data
            } else {
                if let error = error {
                    print("Authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    func shareScreenshot(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            return
        }
        
        let items: [Any] = [data]
        
        // Delay presentation to ensure no conflicts with existing presentations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
    func takeScreenshot() -> UIImage? {
        guard let window = UIApplication.shared.windows.first else { return nil }
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, 0.0)
        window.drawHierarchy(in: window.frame, afterScreenUpdates: false)
        let screenshotObj = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshotObj
    }

    func getUserData(userID: String, completion: @escaping ([String: Any]?) -> Void) {
        let databaseReference = Database.database().reference()
        let userReference = databaseReference.child("users").child(userID)

        userReference.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists(), let userData = snapshot.value as? [String: Any] else {
                // User not found or data is not in the expected format
                completion(nil)
                return
            }

            // User data retrieved successfully
            completion(userData)
        }
    }

    func getUserID() -> String? {
        if let user = Auth.auth().currentUser {
            return user.uid
        }
        return nil
    }
        
    func readableWorkoutActivityType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .americanFootball:
            return "American Football"
        case .archery:
            return "Archery"
        case .australianFootball:
            return "Australian Football"
        case .badminton:
            return "Badminton"
        case .baseball:
            return "Baseball"
        case .basketball:
            return "Basketball"
        case .bowling:
            return "Bowling"
        case .boxing:
            return "Boxing"
        case .climbing:
            return "Climbing"
        case .coreTraining:
            return "Core Training"
        case .cricket:
            return "Cricket"
        case .crossCountrySkiing:
            return "Cross Country Skiing"
        case .crossTraining:
            return "Cross Training"
        case .curling:
            return "Curling"
        case .cycling:
            return "Cycling"
        case .dance:
            return "Dance"
        case .danceInspiredTraining:
            return "Dance Inspired Training"
        case .downhillSkiing:
            return "Downhill Skiing"
        case .elliptical:
            return "Elliptical"
        case .equestrianSports:
            return "Equestrian Sports"
        case .fencing:
            return "Fencing"
        case .fishing:
            return "Fishing"
        case .functionalStrengthTraining:
            return "Functional Strength Training"
        case .golf:
            return "Golf"
        case .gymnastics:
            return "Gymnastics"
        case .handball:
            return "Handball"
        case .hiking:
            return "Hiking"
        case .hockey:
            return "Hockey"
        case .hunting:
            return "Hunting"
        case .lacrosse:
            return "Lacrosse"
        case .martialArts:
            return "Martial Arts"
        case .mindAndBody:
            return "Mind and Body"
        case .mixedMetabolicCardioTraining:
            return "Mixed Metabolic Cardio Training"
        case .paddleSports:
            return "Paddle Sports"
        case .play:
            return "Play"
        case .preparationAndRecovery:
            return "Preparation and Recovery"
        case .racquetball:
            return "Racquetball"
        case .rowing:
            return "Rowing"
        case .rugby:
            return "Rugby"
        case .running:
            return "Running"
        case .sailing:
            return "Sailing"
        case .skatingSports:
            return "Skating Sports"
        case .snowboarding:
            return "Snowboarding"
        case .snowSports:
            return "Snow Sports"
        case .soccer:
            return "Soccer"
        case .softball:
            return "Softball"
        case .squash:
            return "Squash"
        case .stairClimbing:
            return "Stair Climbing"
        case .surfingSports:
            return "Surfing Sports"
        case .swimming:
            return "Swimming"
        case .tableTennis:
            return "Table Tennis"
        case .tennis:
            return "Tennis"
        case .trackAndField:
            return "Track and Field"
        case .traditionalStrengthTraining:
            return "Traditional Strength Training"
        case .volleyball:
            return "Volleyball"
        case .walking:
            return "Walking"
        case .waterFitness:
            return "Water Fitness"
        case .waterPolo:
            return "Water Polo"
        case .waterSports:
            return "Water Sports"
        case .wrestling:
            return "Wrestling"
        case .yoga:
            return "Yoga"
        default:
            return "Unknown"
        }
    }
    func refreshStepCount() {
        let targetDate = Date()
        
        readStepCount(forToday: targetDate, healthStore: healthStore) { stepCountValue in
            self.stepCount = stepCountValue
        }
    }
    

    func readStepCount(forToday date: Date, healthStore: HKHealthStore, completion: @escaping (Int) -> Void) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let now = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
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
    
    func fetchWorkoutsForToday() {
        let workoutType = HKObjectType.workoutType()
        
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictStartDate)
        
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
    
    func fetchSleepData() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate the start and end times for the desired sleep period
        let endOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .hour, value: 21, to: calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)) // 9 PM yesterday
        let endOfTodayPlus11AM = calendar.date(byAdding: .hour, value: 11, to: endOfToday) // 11 AM today

        // Update the predicate to filter for "In Bed" samples within the specified time range
        let predicate = NSPredicate(format: "startDate >= %@ AND endDate <= %@", startOfYesterday! as NSDate, endOfTodayPlus11AM! as NSDate, HKCategoryValueSleepAnalysis.inBed.rawValue)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, samples, error in
            if let sleepSamples = samples as? [HKCategorySample] {
                DispatchQueue.main.async {
                    // Handle the sleep data within the specified time range
                    self.sleepSamples = sleepSamples
                }
            }
        }

        HKHealthStore().execute(query)
    }
    
    func fetchNutritionData() {
            let now = Date()
            let startOfToday = Calendar.current.startOfDay(for: Date())

            let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.calories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
                    }
                }
            }
        let proteinQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.protein = Int(sum.doubleValue(for: HKUnit.gram()))
                    }
                }
            }
        let fatQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.fat = Int(sum.doubleValue(for: HKUnit.gram()))
                    }
                }
            }
        let carbsQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.carbohydrates = Int(sum.doubleValue(for: HKUnit.gram()))
                    }
                }
            }
        healthStore.execute(query)
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
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var phoneViewModel: PhoneViewModel
    @ObservedObject var goalModel: GoalModel
    @ObservedObject var shareList: ShareList
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: GoalSheet(goalModel: goalModel, phoneViewModel: phoneViewModel, shareList: shareList)) {
                    Text("Set Goals")
                }

                Button(action: {
                    // Perform sign out logic
                    phoneViewModel.signout()
                    UserDefaults.standard.set("false", forKey: "goalSet")
                    PhoneNumberView(phoneViewModel: phoneViewModel, goalModel: goalModel, shareList: shareList)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
            }
            .navigationBarTitle("Settings")
            .navigationBarItems(leading:
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                }
            )
        }
    }
}

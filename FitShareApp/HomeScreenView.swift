//
//  HomeScreenView.swift
//  WeightX2
//
//  Created by Keerthanaa Vm on 05/09/23.
//

import Foundation
import SwiftUI
import HealthKit

let healthStore = HKHealthStore()

public struct HomeScreenView: View {
    let healthStore = HKHealthStore()
    @State private var stepCount: Double = 0
    @State private var workouts: [HKWorkout] = []
    @State private var sleepSamples: [HKCategorySample] = []
    @State var calories: Double = 0.0
    @State var protein: Double = 0.0
    @State var fat: Double = 0.0
    @State var carbohydrates: Double = 0.0
    @ObservedObject var phoneViewModel: PhoneViewModel
    
    public var body: some View {
        ScrollView{
            VStack {
                HStack{
                    Button(action: {
                        phoneViewModel.signout()
                        PhoneNumberView(phoneViewModel: phoneViewModel)
                    }) {
                        HStack {
                            Image(systemName: "person.fill.xmark")
                                .font(.title)
                                .padding(.trailing, 10)
                        }
                    }
                    .padding()
                    .position(x: 40, y: 20)
                    Spacer()
                }
                .overlay(
                    Button(action: {
                        if let screenshot = takeScreenshot() {
                            shareScreenshot(image: screenshot)
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title)
                                .padding(.trailing, 10)
                        }
                    }
                        .padding()
                        .position(x: UIScreen.main.bounds.width-20, y: 20)
                )
                Button("Recheck") {
                    print(phoneViewModel.isSignedIn)
                    refreshStepCount()
                    fetchWorkoutsForToday()
                    fetchSleepData()
                    fetchNutritionData()
                }
                
                Text("\nStep count: \(Int(stepCount))").font(.title)
                    .onAppear {
                        requestAuthorization()
                        refreshStepCount()
                        fetchWorkoutsForToday()
                        fetchSleepData()
                        fetchNutritionData()
                    }
                
                
                
               // Text("Disclaimer: Just recheck is not going to > steps")
                if stepCount < 10000 {
                    let remainingSteps = Int(10000 - stepCount)
                    Text("Steps left for 10k: \(remainingSteps)")
                        .foregroundColor(.red) // You can adjust the color as needed
                        .font(.subheadline)
                        .padding(.bottom, 20)
                }
                if stepCount >= 10000 {
                    Text("Wohooo you did more than 10k steps")
                        .foregroundColor(.red) // You can adjust the color as needed
                        .font(.subheadline)
                        .padding(.bottom, 20)
                }
                VStack {
                    
                    Text("\nWorkouts today").font(.title)
                    
                    if workouts.isEmpty {
                        Text("No workouts today")
                    } else {
                        Text("No of workouts done today: \(Int(workouts.count))")
                    }
                }
                VStack {
                    Text("\nSleep time").font(.title)
                    
                    let inBedSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
                    
                    if !inBedSamples.isEmpty {
                        let totalInBedDurationInSeconds = inBedSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                        
                        let totalInBedDurationInMinutes = Int(totalInBedDurationInSeconds) / 60
                        let hours = totalInBedDurationInMinutes / 60
                        let minutes = totalInBedDurationInMinutes % 60
                        
                        Text("Total In Bed Time: \(hours) hours \(minutes) minutes")
                    } else {
                        Text("No 'In Bed' sleep data available.")
                    }
                }
                VStack {
                    Text("\nNutrition").font(.title)
                    Text("Total calories: \(Int(calories))")
                    Text("Total protein: \(Int(protein))")
                    Text("Total carbs: \(Int(carbohydrates))")
                    Text("Total fats: \(Int(fat))")
                }
                
                VStack {
                    Text("\nWorkouts today").font(.title)
                    if workouts.isEmpty {
                        Text("No workouts today")
                    } else {
                        NavigationView {
                            List(workouts, id: \.workoutActivityType) { workout in
                                VStack(alignment: .leading) {
                                    Text("Activity: \(readableWorkoutActivityType(workout.workoutActivityType))")
                                    Text("Duration: \(workout.duration / 60) minutes")
                                }
                            }
                        }
                    }
                }
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
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
    func takeScreenshot() -> UIImage? {
        guard let window = UIApplication.shared.windows.first else {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, 0.0)
        window.drawHierarchy(in: window.frame, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }
    
    private func readableWorkoutActivityType(_ activityType: HKWorkoutActivityType) -> String {
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
    

    func readStepCount(forToday date: Date, healthStore: HKHealthStore, completion: @escaping (Double) -> Void) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let now = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("Query error: \(error.localizedDescription)")
                completion(0.0)
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            
            self.stepCount = sum.doubleValue(for: HKUnit.count())
            completion(stepCount)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWorkoutsForToday() {
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
    
    private func fetchSleepData() {
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
    
    private func fetchNutritionData() {
            let now = Date()
            let startOfToday = Calendar.current.startOfDay(for: Date())

            let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: now, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    }
                }
            }
        let proteinQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.protein = sum.doubleValue(for: HKUnit.gram())
                    }
                }
            }
        let fatQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.fat = sum.doubleValue(for: HKUnit.gram())
                    }
                }
            }
        let carbsQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
                                                  quantitySamplePredicate: predicate,
                                                  options: .cumulativeSum) { (_, result, _) in
                if let sum = result?.sumQuantity() {
                    DispatchQueue.main.async {
                        self.carbohydrates = sum.doubleValue(for: HKUnit.gram())
                    }
                }
            }
        healthStore.execute(query)
        healthStore.execute(proteinQuery)
        healthStore.execute(fatQuery)
        healthStore.execute(carbsQuery)
        }
    
}

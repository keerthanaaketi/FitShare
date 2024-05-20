import SwiftUI
import HealthKit

struct WeightEntryView: View {
    @Binding var weight: Double
    @State private var weightText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    let healthStore: HKHealthStore
    let date: Date

    @State private var weeklyAverage: Double = 0.0
    @State private var weeklyAverageDifference: Double = 0.0
    @State private var showDetails = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let backgroundColor = colorScheme == .dark ? Color.gray.opacity(0.3) : Color.black.opacity(0.1)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack {
                    Image(systemName: "gauge")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(validWeeklyAverageDifference * 1000))g this week")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Button(action: {
                    withAnimation {
                        showDetails.toggle()
                    }
                }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .padding(.leading, 5)
                }
            }
            if showDetails {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Weekly Average: \(weeklyAverage, specifier: "%.2f") kg")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Weekly Average Difference: \(weeklyAverageDifference, specifier: "%.2f") kg")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        TextField("Enter weight(kg)", text: $weightText)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        Button(action: {
                            saveWeight()
                            dismissKeyboard()
                        }) {
                            Text("Save")
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
               // .padding(.horizontal)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(15)
        .padding(.horizontal)
        .onTapGesture {
            dismissKeyboard()
        }
        .onAppear {
            fetchWeight(for: date)
            calculateWeeklyAverage(for: date)
        }
        .onChange(of: date) { newValue in
            fetchWeight(for: newValue)
            calculateWeeklyAverage(for: newValue)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Weight Entry"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    var validWeeklyAverageDifference: Double {
        if weeklyAverageDifference.isFinite && !weeklyAverageDifference.isNaN {
            return weeklyAverageDifference
        } else {
            return 0.0
        }
    }

    func saveWeight() {
        guard let weightValue = Double(weightText) else {
            alertMessage = "Please enter a valid weight."
            showAlert = true
            return
        }
        saveWeightToHealthKit(weight: weightValue)
    }

    func saveWeightToHealthKit(weight: Double) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            alertMessage = "Unable to save weight."
            showAlert = true
            return
        }
        
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let weightSample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: startOfDay, end: startOfDay)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: nil) { query, results, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to fetch existing weight: \(error?.localizedDescription ?? "Unknown error")"
                    self.showAlert = true
                }
                return
            }
            
            if let existingSample = results?.first as? HKQuantitySample {
                // Delete the existing sample before saving the new one
                self.healthStore.delete(existingSample) { success, error in
                    if success {
                        self.saveNewWeightSample(weightSample)
                    } else {
                        DispatchQueue.main.async {
                            self.alertMessage = "Apple health has weight added from some other app. So we cannot update: \(error?.localizedDescription ?? "Unknown error")"
                            self.showAlert = true
                        }
                    }
                }
            } else {
                self.saveNewWeightSample(weightSample)
            }
        }
        
        healthStore.execute(query)
    }

    func saveNewWeightSample(_ weightSample: HKQuantitySample) {
        healthStore.save(weightSample) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("Weight saved successfully.")
                    self.alertMessage = "Weight saved successfully."
                    self.weight = weightSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                    self.calculateWeeklyAverage(for: self.date)
                } else {
                    self.alertMessage = "Failed to save weight: \(error?.localizedDescription ?? "Unknown error")"
                }
                self.showAlert = true
            }
        }
    }

    func fetchWeight(for date: Date) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            alertMessage = "Unable to fetch weight."
            showAlert = true
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, error in
            if let error = error {
                print("Error fetching weight: \(error.localizedDescription)")
                alertMessage = "Error fetching weight: \(error.localizedDescription)"
                showAlert = true
                return
            }

            if let result = results?.first as? HKQuantitySample {
                DispatchQueue.main.async {
                    self.weight = result.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                    self.weightText = String(format: "%.1f", self.weight)
                }
            } else {
                DispatchQueue.main.async {
                    self.weightText = ""
                }
            }
        }
        healthStore.execute(query)
    }

    func calculateWeeklyAverage(for date: Date) {
        let calendar = Calendar.current
        var startOfWeek: Date = Date()
        var interval: TimeInterval = 0

        guard calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: date) else {
            print("Unable to determine the start and end of the week")
            return
        }

        let endOfWeek = startOfWeek.addingTimeInterval(interval - 1)

        let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: endOfWeek, options: .strictStartDate)

        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            if let error = error {
                print("Error calculating weekly average: \(error.localizedDescription)")
                alertMessage = "Error calculating weekly average: \(error.localizedDescription)"
                showAlert = true
                return
            }

            if let results = results as? [HKQuantitySample] {
                let weights = results
                    .sorted(by: { $0.startDate < $1.startDate })
                    .reduce(into: [Date: HKQuantitySample]()) { (dict, sample) in
                        let day = Calendar.current.startOfDay(for: sample.startDate)
                        if dict[day] == nil {
                            dict[day] = sample
                        }
                    }
                    .values
                    .map { $0.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) }
                let weeklyAverage = weights.reduce(0, +) / Double(weights.count)

                // Fetch previous week's average
                let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: startOfWeek)!
                let previousWeekEnd = previousWeekStart.addingTimeInterval(interval - 1)
                let previousWeekPredicate = HKQuery.predicateForSamples(withStart: previousWeekStart, end: previousWeekEnd, options: .strictStartDate)

                let previousWeekQuery = HKSampleQuery(sampleType: weightType, predicate: previousWeekPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, prevResults, error in
                    if let error = error {
                        print("Error calculating previous week's average: \(error.localizedDescription)")
                        alertMessage = "Error calculating previous week's average: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }

                    if let prevResults = prevResults as? [HKQuantitySample] {
                        let prevWeights = prevResults
                            .sorted(by: { $0.startDate < $1.startDate })
                            .reduce(into: [Date: HKQuantitySample]()) { (dict, sample) in
                                let day = Calendar.current.startOfDay(for: sample.startDate)
                                if dict[day] == nil {
                                    dict[day] = sample
                                }
                            }
                            .values
                            .map { $0.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) }
                        let previousWeekAverage = prevWeights.reduce(0, +) / Double(prevWeights.count)

                        DispatchQueue.main.async {
                            self.weeklyAverage = weeklyAverage
                            self.weeklyAverageDifference = weeklyAverage - previousWeekAverage
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.weeklyAverage = weeklyAverage
                            self.weeklyAverageDifference = 0
                        }
                    }
                }
                self.healthStore.execute(previousWeekQuery)
            }
        }
        healthStore.execute(query)
    }
}

struct WeightEntryView_Previews: PreviewProvider {
    static var previews: some View {
        WeightEntryView(weight: .constant(70.0), healthStore: HKHealthStore(), date: Date())
    }
}

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

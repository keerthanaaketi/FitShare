import SwiftUI
import HealthKit

struct WeightView: View {
    @Binding var isPresentingWeightView: Bool
    @Binding var weight: Double
    @Binding var selectedDate: Date
    let healthStore: HKHealthStore
    @ObservedObject var viewHelper: ViewHelper
    @State private var weightText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var weeklyAverage: Double = 0.0
    @State private var weeklyAverageDifference: Double = 0.0
    @State private var showWeightEntryPopup = false

    var body: some View {
        VStack {
            Text("Weight")
                .font(.title)
                .padding()

            // Horizontal Scrollable Date View
            HStack {
                Button(action: {
                    let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: viewHelper.weekDates.first ?? selectedDate) ?? selectedDate
                    viewHelper.updateWeekDates(for: newDate)
                    fetchWeight(for: newDate)
                    calculateWeeklyAverage(for: newDate)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.largeTitle)
                        .padding()
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(viewHelper.weekDates, id: \.self) { date in
                            VStack {
                                Text(viewHelper.dateFormatter.string(from: date))
                                    .font(.caption)
                                    .foregroundColor(date == selectedDate ? .blue : viewHelper.getContrastColor(for: date))
                                    .padding(.bottom, 2)
                                Text(viewHelper.monthFormatter.string(from: date))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(viewHelper.weightForDate(date) ?? "")
                                    .font(.caption2)
                                    .foregroundColor(date == selectedDate ? .blue : viewHelper.getContrastColor(for: date))
                            }
                            .padding(.vertical)
                            .padding(.horizontal, 3)
                            .background(date == selectedDate ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .onTapGesture {
                                selectedDate = date
                                fetchWeight(for: selectedDate)
                                calculateWeeklyAverage(for: selectedDate)
                            }
                        }
                    }
                }
                Button(action: {
                    let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: viewHelper.weekDates.first ?? selectedDate) ?? selectedDate
                    viewHelper.updateWeekDates(for: newDate)
                    fetchWeight(for: newDate)
                    calculateWeeklyAverage(for: newDate)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.largeTitle)
                        .padding()
                }
            }

            // Weekly Average and Difference
            HStack {
                VStack {
                    Text("Weekly Avg")
                        .font(.caption)
                    Text("\(weeklyAverage, specifier: "%.2f")")
                        .font(.headline)
                }
                VStack {
                    Text("Weekly Avg Diff")
                        .font(.caption)
                    Text("\(weeklyAverageDifference, specifier: "%.2f")")
                        .font(.headline)
                }
            }
            .padding()

            // Weight Log List
            List {
                ForEach(viewHelper.weightHistory) { weightEntry in
                    HStack {
                        Text("\(weightEntry.dateString): \(String(format: "%.2f", weightEntry.value))")
                        Spacer()
                        Button(action: {
                            viewHelper.deleteWeightEntry(weight: weightEntry)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // Add Weight Button
            Button(action: {
                showWeightEntryPopup = true
            }) {
                Text("Add Weight")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showWeightEntryPopup) {
                WeightEntryPopup(selectedDate: $selectedDate, weight: $weight, onSave: {
                    saveWeight()
                    showWeightEntryPopup = false
                })
            }
        }
        .onAppear {
            viewHelper.fetchWeightHistory()
            viewHelper.updateWeekDates(for: selectedDate)
            fetchWeight(for: selectedDate)
            calculateWeeklyAverage(for: selectedDate)
        }
        .onChange(of: selectedDate) { newValue in
            fetchWeight(for: newValue)
            calculateWeeklyAverage(for: newValue)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Weight Entry"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func saveWeight() {
        self.weightText = String(format: "%.2f", self.weight)
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
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
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
                    self.calculateWeeklyAverage(for: self.selectedDate)
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
                    self.weightText = String(format: "%.2f", self.weight)
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

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct WeightEntry: Identifiable, Hashable {
    var id: UUID
    var date: Date
    var value: Double

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }
}

struct weightView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(phoneViewModel: PhoneViewModel(), goalModel: GoalModel(), shareList: ShareList())
    }
}

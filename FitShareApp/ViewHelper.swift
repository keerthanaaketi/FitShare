import SwiftUI
import HealthKit
import FirebaseDatabase
import FirebaseDatabaseSwift
import FirebaseStorage

class ViewHelper: ObservableObject {
    @Published var weightHistory: [WeightEntry] = []
       @Published var weekDates: [Date] = []
       private var currentDate = Date()
    @Published var selectedImage: UIImage? = nil
    @Published var screenshot: UIImage? = nil
    @Published var isPresentingActivityViewController = false
    @Published var readyToPresentActivityView = false
    @Environment(\.colorScheme) var colorScheme
    var imagesCache: [Date: UIImage] = [:]
    @Published var imageCache: [String: UIImage] = [:]
    
    init() {
            updateWeekDates(for: currentDate)
        }
    func getContrastColor(for date: Date) -> Color {
        return Calendar.current.isDate(date, inSameDayAs: Date()) ? .blue : .primary
    }
    var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd"
            return formatter
        }
    func setImage(_ image: UIImage, for date: Date) {
           let key = dateKey(for: date)
           imageCache[key] = image
       }
    func dateKey(for date: Date) -> String {
          let formatter = DateFormatter()
          formatter.dateFormat = "dd-MM-yyyy"
          return formatter.string(from: date)
      }

    var monthFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter
        }
    
    let healthStore = HKHealthStore()
    func updateWeekDates(for date: Date) {
            weekDates = (0..<7).compactMap {
                Calendar.current.date(byAdding: .day, value: $0 - Calendar.current.component(.weekday, from: date) + 1, to: date)
            }
        }
    func previousWeek() {
            guard let previousDate = Calendar.current.date(byAdding: .day, value: -7, to: currentDate) else { return }
            updateWeekDates(for: previousDate)
        }

        func nextWeek() {
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) else { return }
            updateWeekDates(for: nextDate)
        }
    // Fetch weight history
    func fetchWeightHistory() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)

        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, results, error in
            if let error = error {
                print("Error fetching weight history: \(error.localizedDescription)")
                return
            }

            if let results = results as? [HKQuantitySample] {
                let weightEntries = results.map { WeightEntry(id: UUID(), date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))) }
                DispatchQueue.main.async {
                    self?.weightHistory = weightEntries.sorted(by: { $0.date > $1.date })
                }
            }
        }

        healthStore.execute(query)
    }
    func getWeightString(for date: Date) -> String {
          if let weightEntry = weightHistory.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
              return "\(weightEntry.value)"
          } else {
              return ""
          }
      }
    func weightForDate(_ date: Date) -> String? {
            if let weightEntry = weightHistory.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                return String(format: "%.2f", weightEntry.value)
            }
            return nil
        }
    func fetchWeightHistory(for date: Date = Date()) {
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
                    print("Error fetching weight history: \(error.localizedDescription)")
                    return
                }

                if let results = results as? [HKQuantitySample] {
                    let weightEntries = results.map { WeightEntry(id: UUID(), date: $0.startDate, value: $0.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))) }
                    DispatchQueue.main.async {
                        self.weightHistory = weightEntries
                    }
                }
            }
            HKHealthStore().execute(query)
        }

    // Delete weight entry
    func deleteWeightEntry(weight: WeightEntry) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: weight.date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: 1, sortDescriptors: nil) { query, results, error in
            guard error == nil else {
                print("Failed to fetch existing weight for deletion: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let existingSample = results?.first as? HKQuantitySample {
                HKHealthStore().delete(existingSample) { success, error in
                    if success {
                        print("Weight deleted successfully.")
                        DispatchQueue.main.async {
                            self.weightHistory.removeAll { $0.id == weight.id }
                        }
                    } else {
                        print("Failed to delete weight: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
        
        HKHealthStore().execute(query)
    }

    // Capture screenshot
    func captureScreenshot() {
        guard let window = UIApplication.shared.windows.first else { return }

        UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        self.screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if self.screenshot != nil {
            self.readyToPresentActivityView = true
        }
    }
    func fetchImage(for date: Date) {
            guard let userID = getUserID() else { return }
            let dateString = getFormattedDate(date: date)

            let dbRef = Database.database().reference()
            dbRef.child("users/\(userID)/images/\(dateString)").observeSingleEvent(of: .value) { snapshot in
                if let imageURL = snapshot.value as? String {
                    self.loadImage(from: imageURL) { image in
                        DispatchQueue.main.async {
                            self.imagesCache[date] = image
                            self.selectedImage = image
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.imagesCache[date] = nil
                        self.selectedImage = nil
                    }
                }
            }
        }
    func imageForDate(_ date: Date) -> UIImage? {
            if let cachedImage = imagesCache[date] {
                return cachedImage
            } else {
                fetchImage(for: date)
                return nil
            }
        }

    private func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = URL(string: url) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
    func uploadImage(_ image: UIImage, for date: Date) {
            guard let userID = getUserID() else { return }
            let dateString = getFormattedDate(date: date)

            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

            let storageRef = Storage.storage().reference().child("images/\(userID)/\(dateString).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("Failed to upload image: \(error.localizedDescription)")
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Failed to get download URL: \(error.localizedDescription)")
                        return
                    }

                    guard let downloadURL = url else { return }
                    let dbRef = Database.database().reference()
                    dbRef.child("users/\(userID)/images/\(dateString)").setValue(downloadURL.absoluteString) { error, _ in
                        if let error = error {
                            print("Failed to save image URL to database: \(error.localizedDescription)")
                        } else {
                            print("Image URL saved to database successfully")
                            self.selectedImage = image
                        }
                    }
                }
            }
        }
    func deleteImage(for date: Date) {
            guard let userID = getUserID() else { return }
            let dateString = getFormattedDate(date: date)

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
                            DispatchQueue.main.async {
                                self.selectedImage = nil
                            }
                        }
                    }
                }
            }
        }

    // Get formatted date
    func getFormattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
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
}



import SwiftUI

struct MonthView: View {
    @Binding var selectedDate: Date
    @ObservedObject var viewHelper: ViewHelper
    @Binding var showWeightEntryPopup: Bool
    @Binding var currentWeekDates: [Date]
    let updateWeeklyAverage: (Date) -> Void

    var body: some View {
        HStack {
            Button(action: {
                loadPreviousWeek()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(currentWeekDates, id: \.self) { date in
                        VStack {
                            Text(getDayOfWeekString(for: date))
                                .font(.system(size: 14))
                            Text(getMonthDayString(for: date))
                                .font(.system(size: 14))
                            Text(viewHelper.getWeightString(for: date))
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(date == selectedDate ? Color.blue : Color.clear)
                        .cornerRadius(10)
                        .onTapGesture {
                            selectedDate = date
                            showWeightEntryPopup = true
                        }
                    }
                }
            }
            Button(action: {
                loadNextWeek()
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
            }
        }
    }

    func getMonthDayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    func getDayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    func loadPreviousWeek() {
        if let firstDate = currentWeekDates.first,
           let previousWeek = Calendar.current.date(byAdding: .day, value: -7, to: firstDate) {
            currentWeekDates = getWeekDates(for: previousWeek)
            viewHelper.fetchWeightHistory(for: previousWeek)
            updateWeeklyAverage(previousWeek)
        }
    }

    func loadNextWeek() {
        if let lastDate = currentWeekDates.last,
           let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: lastDate) {
            currentWeekDates = getWeekDates(for: nextWeek)
            viewHelper.fetchWeightHistory(for: nextWeek)
            updateWeeklyAverage(nextWeek)
        }
    }

    func getWeekDates(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? Date()
        return (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

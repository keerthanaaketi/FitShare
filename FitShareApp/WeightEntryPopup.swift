import SwiftUI

struct WeightEntryPopup: View {
    @Binding var selectedDate: Date
    @Binding var weight: Double
    @State private var wholeNumber: Int = 0
    @State private var fractionalNumber: Int = 0
    @State private var showDatePicker = false
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter weight")
                .font(.headline)
                .padding(.top)

            HStack(spacing: 10) {
                Picker("Whole Number", selection: $wholeNumber) {
                    ForEach(0..<300, id: \.self) { number in
                        Text("\(number)")
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100, height: 100)

                Picker("Fractional Number", selection: $fractionalNumber) {
                    ForEach(0..<100, id: \.self) { number in
                        Text(String(format: "%02d", number))
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 100, height: 100)
            }

            Text("on \(selectedDate, formatter: DateFormatter.shortDate)")
                .font(.subheadline)
                .padding(.bottom)
                .onTapGesture {
                    showDatePicker = true
                }
                .sheet(isPresented: $showDatePicker) {
                    VStack {
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                        Button("Done") {
                            showDatePicker = false
                        }
                        .padding()
                    }
                }

            Button(action: {
                weight = Double(wholeNumber) + Double(fractionalNumber) / 100.0
                onSave()
                showDatePicker = false
            }) {
                Text("Save")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

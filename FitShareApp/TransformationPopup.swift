import SwiftUI

struct TransformationPopup: View {
    @Binding var isPresented: Bool
    @Binding var beforeDate: Date
    @Binding var afterDate: Date
    @Binding var showTransformationView: Bool

    @State private var showBeforeDatePicker = false
    @State private var showAfterDatePicker = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack {
                    Text("Before")
                    Text("\(beforeDate, formatter: dateFormatter)")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            showBeforeDatePicker.toggle()
                        }
                        .sheet(isPresented: $showBeforeDatePicker) {
                            DatePicker("Select Date", selection: Binding(
                                get: { beforeDate },
                                set: {
                                    beforeDate = $0
                                    showBeforeDatePicker = false
                                }
                            ), displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                        }
                }
                VStack {
                    Text("After")
                    Text("\(afterDate, formatter: dateFormatter)")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            showAfterDatePicker.toggle()
                        }
                        .sheet(isPresented: $showAfterDatePicker) {
                            DatePicker("Select Date", selection: Binding(
                                get: { afterDate },
                                set: {
                                    afterDate = $0
                                    showAfterDatePicker = false
                                }
                            ), displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                        }
                }
            }

            Button(action: {
                // Set state to show TransformationView
                showTransformationView = true
                isPresented = false
            }) {
                Text("Check my transformation")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            // Set default dates
            afterDate = Date()
            beforeDate = Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        }
    }

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct TransformationPopup_Previews: PreviewProvider {
    static var previews: some View {
        TransformationPopup(
            isPresented: .constant(true),
            beforeDate: .constant(Date()),
            afterDate: .constant(Date()),
            showTransformationView: .constant(false)
        )
    }
}

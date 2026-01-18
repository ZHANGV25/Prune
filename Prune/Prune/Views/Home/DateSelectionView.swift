import SwiftUI

struct DateSelectionView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (Date, Date) -> Void
    
    @State private var selectedMonth: Int?
    @State private var showCustomRange = false
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    // Generate last 12 months (Newest -> Oldest)
    var months: [Date] {
        let calendar = Calendar.current
        let now = Date()
        var dates: [Date] = []
        
        for i in 0..<12 {
            // Go back i months from now
            if let date = calendar.date(byAdding: .month, value: -i, to: now) {
                dates.append(date)
            }
        }
        return dates
    }
    
    // Grid for months
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Text("Travel Back in Time")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Select a Month")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        // Month Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(months, id: \.self) { date in
                                Button(action: {
                                    selectMonthDate(date)
                                }) {
                                    VStack {
                                        Text(monthFormatter.string(from: date))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                        
                                        Text(yearFormatter.string(from: date))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color(white: 0.1))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Or Custom Range")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Custom Date Picker Area
                        VStack {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .colorScheme(.dark)
                            Divider().background(Color.gray)
                            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                .colorScheme(.dark)
                            
                            Button(action: {
                                onSelect(startDate, endDate)
                                dismiss()
                            }) {
                                Text("Go to Dates")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    private var yearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }
    
    func selectMonthDate(_ date: Date) {
        let calendar = Calendar.current
        
        // Start of month
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return }
        
        // End of month
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: start),
              let end = calendar.date(byAdding: .day, value: -1, to: nextMonth) else { return }
        
        onSelect(start, end)
        dismiss()
    }
}

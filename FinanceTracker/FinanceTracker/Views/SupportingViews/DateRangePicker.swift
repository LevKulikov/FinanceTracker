//
//  DateRangePicker.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 14.06.2024.
//

import SwiftUI

struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let dateRange: ClosedRange<Date>
    let calendar: Calendar
    
    private var startDateRange: ClosedRange<Date> {
        let lowerBound = dateRange.lowerBound
        let upperBound = calendar.date(byAdding: .second, value: -1, to: calendar.startOfDay(for: endDate))
        
        return lowerBound...(upperBound ?? calendar.startOfDay(for: endDate))
    }
    
    private var endDateRange: ClosedRange<Date> {
        let nextAfterStartDate = calendar.date(byAdding: .day, value: 1, to: startDate)
        let lowerBound = calendar.startOfDay(for: nextAfterStartDate ?? startDate)
        let upperBound = dateRange.upperBound
        
        guard lowerBound < upperBound else {
            return calendar.startOfDay(for: startDate)...upperBound
        }
        
        return lowerBound...upperBound
    }
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, dateRange: ClosedRange<Date>, calendar: Calendar = .current) {
        self._startDate = startDate
        self._endDate = endDate
        self.dateRange = dateRange
        self.calendar = calendar
    }
    
    var body: some View {
        HStack {
            DatePicker("Start date", selection: $startDate, in: startDateRange, displayedComponents: .date)
                .datePickerStyle(.compact)
            
            Image(systemName: "arrow.left.and.right")
            
            DatePicker("End date", selection: $endDate, in: endDateRange, displayedComponents: .date)
                .datePickerStyle(.compact)
        }
        .labelsHidden()
    }
}

#Preview {
    @State var startDate = Date.now
    @State var endDate = Date.now
    
    return DateRangePicker(startDate: $startDate, endDate: $endDate, dateRange: FTAppAssets.availableDateRange)
}

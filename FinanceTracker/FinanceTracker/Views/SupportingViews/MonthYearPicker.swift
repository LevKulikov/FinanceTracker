//
//  MonthYearPicker.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 14.06.2024.
//

import SwiftUI

struct MonthYearPicker: View {
    enum MonthYearComponent: Equatable {
        case monthYear
        case year
    }
    
    @Binding var date: Date {
        didSet {
            if !dateRange.contains(date) {
                if date > dateRange.upperBound {
                    date = dateRange.upperBound
                } else {
                    date = dateRange.lowerBound
                }
            }
        }
    }
    let dateRange: ClosedRange<Date>
    let components: MonthYearComponent
    let calendar: Calendar
    
    private var monthRange: ClosedRange<Int> {
        let upperBound = dateRange.upperBound
        let lowerBound = dateRange.lowerBound
        if calendar.component(.year, from: date) == calendar.component(.year, from: upperBound) {
            return 1...calendar.component(.month, from: upperBound)
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: lowerBound) {
            return calendar.component(.month, from: lowerBound)...12
        }
        return 1...12
    }
    private var yearRange: ClosedRange<Int> {
        let upperBound = dateRange.upperBound
        let lowerBound = dateRange.lowerBound
        
        return calendar.component(.year, from: lowerBound)...calendar.component(.year, from: upperBound)
    }
    
    init(date: Binding<Date>, dateRange: ClosedRange<Date>, components: MonthYearComponent, calendar: Calendar = .current) {
        self._date = date
        self.dateRange = dateRange
        self.components = components
        self.calendar = calendar
    }
    
    var body: some View {
        HStack {
            if case .monthYear = components {
                Menu(date.month) {
                    ForEach(monthRange.reversed(), id: \.self) { monthIndex in
                        let year = calendar.component(.year, from: date)
                        let monthName = calendar.date(from: DateComponents(year: year, month: monthIndex))?.month
                        Button(monthName ?? "Error") {
                            selectMonth(monthIndex)
                        }
                    }
                }
                .onTapGesture(count: 20, perform: {
                    // prevents iOS 17 bug
                })
                .hoverEffect(.highlight)
            }
            
            let yearNumber = calendar.component(.year, from: date)
            Menu(String(yearNumber)) {
                ForEach(yearRange.reversed(), id: \.self) { yearIndex in
                    Button(String(yearIndex)) {
                        selectYear(yearIndex)
                    }
                }
            }
            .onTapGesture(count: 20, perform: {
                // prevents iOS 17 bug
            })
            .hoverEffect(.highlight)
        }
        .buttonStyle(.bordered)
        .foregroundStyle(.primary)
    }
    
    private func selectMonth(_ monthIndex: Int) {
        var dateComponents = calendar.dateComponents([.year, .month], from: date)
        dateComponents.month = monthIndex
        
        guard let setDate = calendar.date(from: dateComponents) else {
            print("MonthYearPicker: unable to set month to date, month index: \(monthIndex)")
            return
        }
        date = setDate
    }
    
    private func selectYear(_ yearNumber: Int) {
        var dateComponents = calendar.dateComponents([.year, .month], from: date)
        dateComponents.year = yearNumber
        
        guard let setDate = calendar.date(from: dateComponents) else {
            print("MonthYearPicker: unable to set year to date, year number: \(yearNumber)")
            return
        }
        date = setDate
    }
}

#Preview {
    @Previewable @State var date = Calendar.current.date(byAdding: .year, value: -1, to: Date.now)!
    
    return MonthYearPicker(date: $date, dateRange: FTAppAssets.availableDateRange, components: .monthYear)
}

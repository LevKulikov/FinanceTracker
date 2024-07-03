//
//  Date+Extension.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 01.06.2024.
//

import Foundation

extension Date {
    var month: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM"
            return dateFormatter.string(from: self)
        }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }
    
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
    func endOfDay(calendar: Calendar = Calendar.current) -> Date? {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: self) else { return nil }
        let startOfNextDay = calendar.startOfDay(for: nextDay)
        return calendar.date(byAdding: .second, value: -1, to: startOfNextDay)
    }
    
    func startOfWeek(using calendar: Calendar = .current) -> Date? {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date
    }
    
    func isFirstWeekOfMonth(using calendar: Calendar = .current) -> Bool {
        let dateComponents = calendar.dateComponents([.weekOfMonth], from: self)
        return dateComponents.weekOfMonth == 1 ? true : false
    }
    
    func isFirstMonthOfYear(using calendar: Calendar = .current) -> Bool {
        let dateComponents = calendar.dateComponents([.month], from: self)
        return dateComponents.month == 1 ? true : false
    }
}

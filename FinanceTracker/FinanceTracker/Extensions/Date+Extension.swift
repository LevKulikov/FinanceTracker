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
    
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
    
    func endOfDay(calendar: Calendar = Calendar.current) -> Date? {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: self) else { return nil }
        let startOfNextDay = calendar.startOfDay(for: nextDay)
        return calendar.date(byAdding: .nanosecond, value: -50_000_000, to: startOfNextDay)
    }
    
    func startOfWeek(using calendar: Calendar = .current) -> Date? {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date
    }
    
    func endOfWeek(using calendar: Calendar = .current) -> Date? {
        guard let nextWeek = calendar.date(byAdding: .weekOfMonth, value: 1, to: self) else { return nil }
        return nextWeek.startOfWeek()
    }
    
    func isFirstWeekOfMonth(using calendar: Calendar = .current) -> Bool {
        let dateComponents = calendar.dateComponents([.weekOfMonth], from: self)
        return dateComponents.weekOfMonth == 1 ? true : false
    }
    
    func isFirstMonthOfYear(using calendar: Calendar = .current) -> Bool {
        let dateComponents = calendar.dateComponents([.month], from: self)
        return dateComponents.month == 1 ? true : false
    }
    
    func startOfMonth(using calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.month, .year], from: self)
        let date = calendar.date(from: components)
        return date
    }
    
    func endOfMonth(using calendar: Calendar = .current) -> Date? {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: self)
        return nextMonth?.startOfMonth()
    }
    
    func startOfYear(using calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.year], from: self)
        let date = calendar.date(from: components)
        return date
    }
    
    func endOfYear(using calendar: Calendar = .current) -> Date? {
        let nextYear = calendar.date(byAdding: .year, value: 1, to: self)
        return nextYear?.startOfYear()
    }
}

//
//  NumberFormater.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 31.05.2024.
//

import Foundation

struct FTFormatters {
    static var numberFormatterWithDecimals: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        
        return formatter
    }
    
    static var numberFormatterWithoutDecimals: NumberFormatter {
        let formatter = Self.numberFormatterWithDecimals
        formatter.numberStyle = .none
        return formatter
    }
    
    private init() {}
    
    static func dayOfWeek(for date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date).capitalized(with: .current)
    }
}

//
//  TransactionCalculationValueType.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.07.2025.
//

import Foundation
import SwiftUI

enum TransactionCalculationValueType: LocalizedStringResource {
    case spending = "Spending"
    case income = "Income"
    case profit = "Profit"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .spending:
            return .red
        case .income:
            return .green
        case .profit:
            return .blue
        case .unknown:
            return .yellow
        }
    }
}

//
//  TransactionBarChartData.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.07.2025.
//

import Foundation

struct TransactionBarChartData: Identifiable, Hashable {
    let id: UUID = UUID()
    let type: TransactionCalculationValueType
    let value: Float
    let date: Date
}

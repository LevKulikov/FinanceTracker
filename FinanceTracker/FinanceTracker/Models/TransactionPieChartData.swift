//
//  TransactionPieChartData.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.07.2025.
//

import Foundation

struct TransactionPieChartData: Identifiable {
    let id = UUID().uuidString
    let category: Category
    let sumValue: Float
    let transactions: [Transaction]
}

//
//  TransactionDatedValue.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.07.2025.
//

import Foundation

struct TransactionDatedValue: Hashable {
    let value: Float
    let date: Date
    let forPeriod: Calendar.Component
}

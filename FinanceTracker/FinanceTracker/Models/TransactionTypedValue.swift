//
//  TransactionTypedValue.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 07.08.2025.
//

import Foundation

struct TransactionTypedValue: Identifiable {
    let id: UUID = UUID()
    let type: TransactionCalculationValueType
    let value: Float
    let description: LocalizedStringResource
}

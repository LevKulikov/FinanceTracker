//
//  TransactionPieChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI
import Charts

struct TransactionPieChart: View {
    let transactionGroups: [(categoryName: String, sumValue: Float)]
    
    var body: some View {
        Chart(transactionGroups, id: \.categoryName) { transaction in
            SectorMark(
                angle: .value(transaction.categoryName, transaction.sumValue),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(by: .value(Text(verbatim: transaction.categoryName), transaction.categoryName))
        }
    }
}

#Preview {
    TransactionPieChart(transactionGroups: [])
}

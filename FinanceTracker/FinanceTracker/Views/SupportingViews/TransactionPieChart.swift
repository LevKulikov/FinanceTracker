//
//  TransactionPieChart.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI
import Charts
import Algorithms

struct TransactionPieChart: View {
    let transactions: [Transaction]
    @State private var transactionsGroups: [(categoryName: String, sumValue: Float)] = []
    
    init(transactions: [Transaction]) {
        self.transactions = transactions
    }
    
    var body: some View {
        Chart(transactionsGroups, id: \.categoryName) { transaction in
            SectorMark(
                angle: .value(transaction.categoryName, transaction.sumValue),
                innerRadius: .ratio(0.6)
            )
            .foregroundStyle(by: .value(Text(verbatim: transaction.categoryName), transaction.categoryName))
        }
        .onAppear {
            transactionsGroups = transactions
                .grouped { $0.category.name }
                .map { singleDict in
                    let sumOfValue = singleDict.value.reduce(0, { $0 + $1.value })
                    let name = singleDict.key
                    return (categoryName: name, sumValue: sumOfValue)
                }
                .sorted(by: { $0.categoryName < $1.categoryName })
        }
    }
}

#Preview {
    TransactionPieChart(transactions: FTAppAssets.testTransactions)
}

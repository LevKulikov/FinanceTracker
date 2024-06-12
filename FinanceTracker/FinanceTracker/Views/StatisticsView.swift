//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI

struct StatisticsView: View {
    var body: some View {
        TransactionPieChart(transactions: FTAppAssets.testTransactions)
    }
}

#Preview {
    StatisticsView()
}

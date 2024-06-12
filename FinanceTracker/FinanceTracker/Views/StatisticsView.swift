//
//  StatisticsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 13.06.2024.
//

import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel
    
    init(viewModel: StatisticsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        TransactionPieChart(transactions: viewModel.transactions)
    }
}

#Preview {
    let dataManger = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = StatisticsViewModel(dataManager: dataManger)
    
    return StatisticsView(viewModel: viewModel)
}

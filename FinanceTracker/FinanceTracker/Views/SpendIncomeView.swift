//
//  SpendIncomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 25.05.2024.
//

import SwiftUI

struct SpendIncomeView: View {
    //MARK: Properties
    @Namespace private var namespace
    @StateObject private var viewModel: SpendIncomeViewModel
    
    //MARK: Init
    init(viewModel: SpendIncomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: Computed View props
    var body: some View {
        SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
    }
    
    //MARK: Methods
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    return SpendIncomeView(viewModel: viewModel)
}

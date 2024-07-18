//
//  BudgetCard.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI

struct BudgetCard: View {
    //MARK: - Properties
    @StateObject private var viewModel: BudgetCardViewModel
    
    //MARK: - Initializer
    init(viewModel: BudgetCardViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    //MARK: - Computed View Properties
    
    //MARK: - Methods
    
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = BudgetCardViewModel(dataManager: dataManager, budget: .empty)
    
    return BudgetCard(viewModel: viewModel)
}

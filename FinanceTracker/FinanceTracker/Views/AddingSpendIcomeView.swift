//
//  AddingSpendIcomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import SwiftUI

enum ActionWithTransaction {
    case none
    case add
    case update(Transaction)
}

struct AddingSpendIcomeView: View {
    //MARK: Properties
    @ObservedObject var viewModel: SpendIncomeViewModel
    @Binding var action: ActionWithTransaction
    
    //MARK: Body
    var body: some View {
        VStack {
            SpendIncomePicker(transactionsTypeSelected: $viewModel.transactionsTypeSelected)
        }
    }
    
    //MARK: Computed View Props
    
    
    //MARK: Methods
    
}

#Preview {
    let container = FinanceTrackerApp.createModelContainer()
    let dataManager = DataManager(container: container)
    let viewModel = SpendIncomeViewModel(dataManager: dataManager)
    
    @State var action: ActionWithTransaction = .add
    
    return AddingSpendIcomeView(viewModel: viewModel, action: $action)
}

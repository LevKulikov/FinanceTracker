//
//  AddingSpendIcomeView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 29.05.2024.
//

import SwiftUI

struct AddingSpendIcomeView: View {
    //MARK: Properties
    @Binding var action: ActionWithTransaction
    @StateObject private var viewModel: AddingSpendIcomeViewModel
    
    //MARK: Init
    init(action: Binding<ActionWithTransaction>, viewModel: AddingSpendIcomeViewModel) {
        self._action = action
        self._viewModel = StateObject(wrappedValue: viewModel)
        viewModel.action = self.action
    }
    
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
    let transactionsTypeSelected: TransactionsType = .spending
    let viewModel = AddingSpendIcomeViewModel(dataManager: dataManager, transactionsTypeSelected: transactionsTypeSelected)
    
    @State var action: ActionWithTransaction = .add
    
    return AddingSpendIcomeView(action: $action, viewModel: viewModel)
}

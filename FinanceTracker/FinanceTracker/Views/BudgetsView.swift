//
//  BudgetsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI

struct BudgetsView: View {
    //MARK: - Properties
    @Namespace private var namespace
    @StateObject private var viewModel: BudgetsViewModel
    
    //MARK: - Initializer
    init(viewModel: BudgetsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                headerView
                    .padding(.horizontal)
                
                ForEach(viewModel.budgets) { budget in
                    viewModel.getBudgetCard(for: budget, namespace: namespace)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        //TODO: Continue
                    }
                }
            }
        }
    }
    
    //MARK: - Computed View Properties
    private var headerView: some View {
        HStack {
            Text("Balance Account")
                .bold()
                .font(.title3)
                .layoutPriority(1)
            
            Spacer()
            
            Menu(viewModel.selectedBalanceAccount.name) {
                Picker("Balance account", selection: $viewModel.selectedBalanceAccount) {
                    ForEach(viewModel.allBalanceAccounts) { balanceAccount in
                        HStack {
                            Text(balanceAccount.name)
                            
                            if let uiImage = FTAppAssets.iconUIImage(name: balanceAccount.iconName) {
                                Image(uiImage: uiImage)
                            } else {
                                Image(systemName: "xmark")
                            }
                        }
                        .tag(balanceAccount)
                    }
                }
            }
            .modifier(RoundedRectMenu())
        }
    }
    
    //MARK: - Methods
}

#Preview {
    let dataManager = DataManager(container: FinanceTrackerApp.createModelContainer())
    let viewModel = BudgetsViewModel(dataManager: dataManager)
    
    return BudgetsView(viewModel: viewModel)
}

//
//  BudgetsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI

struct BudgetsView: View {
//    enum ActionWithBudgetNavPath: Hashable {
//        case add
//        case update(Bud)
//    }
    
    //MARK: - Properties
    @Namespace private var namespace
    @StateObject private var viewModel: BudgetsViewModel
    @State private var navigationPath = NavigationPath()
    
    //MARK: - Initializer
    init(viewModel: BudgetsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack {
                    headerView
                        .padding([.horizontal, .bottom])
                    
                    ForEach(viewModel.budgets) { budget in
                        viewModel.getBudgetCard(for: budget, namespace: namespace)
                            .padding(.vertical, 5)
                    }
                    .padding(.horizontal)
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 50)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        navigationPath.append(ActionWithBudget.add(.emptyBalanceAccount))
                    }
                }
            }
            .navigationDestination(for: ActionWithBudget.self) { action in
                viewModel.getAddingBudgetView()
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

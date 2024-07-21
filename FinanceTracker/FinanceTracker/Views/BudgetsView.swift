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
    @State private var navigationPath = NavigationPath()
    @State private var deletionAlertItem: Budget?
    @State private var budgetDataForDetails: BudgetCardViewData?
    
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
                        .padding(.horizontal)
                    
                    Divider()
                        .padding([.horizontal, .bottom])
                    
                    if !viewModel.isFetching, viewModel.budgets.isEmpty {
                        ContentUnavailableView {
                            Label("No budgets", systemImage: "dollarsign.square")
                        } description: {
                            Text("You don't have any saved budgets yet. Good opportunity to give it a try!")
                        } actions: {
                            Button("Add budget") {
                                navigationPath.append(ActionWithBudget.add(.emptyBalanceAccount))
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                    }
                    
                    ForEach(viewModel.budgets) { budget in
                        viewModel.getBudgetCard(for: budget, namespace: namespace) { budgetCardData in
                            Button("Transactions", systemImage: "list.bullet.clipboard") {
                                budgetDataForDetails = budgetCardData
                            }
                            
                            Button("Update", systemImage: "pencil.and.outline") {
                                navigationPath.append(ActionWithBudget.update(budget: budget))
                            }
                            
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deletionAlertItem = budget
                            }
                        }
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
            .confirmationDialog(
                "Delete budget?",
                isPresented: .init(get: { deletionAlertItem != nil }, set: { _ in deletionAlertItem = nil }),
                titleVisibility: .visible,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let deletionAlertItem {
                            viewModel.deleteBudget(deletionAlertItem)
                        }
                    }
                },
                message: {
                    Text("This action is irretable")
                })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        navigationPath.append(ActionWithBudget.add(.emptyBalanceAccount))
                    }
                }
            }
            .navigationDestination(for: ActionWithBudget.self) { action in
                switch action {
                case .add:
                    viewModel.getAddingBudgetView()
                case .update(let budget):
                    viewModel.getUpdaingBudgetView(for: budget)
                case .none:
                    EmptyView()
                }
            }
            .overlay {
                if viewModel.isFetching {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .sheet(item: $budgetDataForDetails) {
                viewModel.refreshIfNeeded()
            } content: { budgetData in
                viewModel.getTransactionsListView(for: budgetData)
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

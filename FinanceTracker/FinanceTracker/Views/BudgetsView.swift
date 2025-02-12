//
//  BudgetsView.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import SwiftUI

struct BudgetsView: View {    
    //MARK: - Properties
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var namespace
    @Namespace private var emptyNamespace
    @StateObject private var viewModel: BudgetsViewModel
    @State private var deletionAlertItem: Budget?
    @State private var budgetDataForDetails: BudgetCardViewData?
    private var backgroundColor: Color {
        colorScheme == .light ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }
    private var isIpad: Bool {
        FTAppAssets.currentUserDevise == .pad
    }
    
    //MARK: - Initializer
    init(viewModel: BudgetsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
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
                                viewModel.navigationPath.append(ActionWithBudget.add(.emptyBalanceAccount))
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
                                viewModel.navigationPath.append(ActionWithBudget.update(budget: budget))
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
                isPresented: 
                        .init(get: { isIpad ? false : deletionAlertItem != nil }, set: { _ in deletionAlertItem = nil }),
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
            .alert(
                "Delete budget?",
                isPresented:
                        .init(get: { isIpad ? deletionAlertItem != nil : false }, set: { _ in deletionAlertItem = nil }),
                actions: {
                    Button("Delete", role: .destructive) {
                        if let deletionAlertItem {
                            viewModel.deleteBudget(deletionAlertItem)
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }, message: {
                    Text("This action is irretable")
                })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Card type", systemImage: viewModel.cardTypeIsLine ? "chart.pie" : "chart.line.flattrend.xyaxis") {
                        withAnimation {
                            viewModel.cardTypeIsLine.toggle()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        viewModel.navigationPath.append(ActionWithBudget.add(.emptyBalanceAccount))
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
            .onAppear {
                viewModel.isViewDisplayed = true
                viewModel.refreshIfNeeded()
            }
            .onDisappear {
                viewModel.isViewDisplayed = false
            }
            .background { backgroundColor.ignoresSafeArea() }
        }
    }
    
    //MARK: - Computed View Properties
    private var headerView: some View {
        HStack {
            Text("Balance Account")
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

//
//  BudgetsViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 18.07.2024.
//

import Foundation
import SwiftData
import SwiftUI

//MARK: - Delegate protocol
protocol BudgetsViewModelDelegate: AnyObject {
    func didAddBudget(_ budget: Budget)
    
    func didUpdateBudget(_ budget: Budget)
    
    func didDeleteBudget(_ budget: Budget)
    
    func didUpdateTransaction()
    
    func showTabBar(_ show: Bool)
}

struct BudgetCardViewData: Identifiable, Hashable {
    let id = UUID().uuidString
    let budget: Budget
    let transactions: [Transaction]
}

//MARK: - ViewModel class
final class BudgetsViewModel: ObservableObject, @unchecked Sendable {
    //MARK: - Properties
    weak var delegate: (any BudgetsViewModelDelegate)?
    
    //MARK: Private properties
    private let dataManager: any DataManagerProtocol
    private var neededToBeRefreshed = false
    
    //MARK: Published props
    @MainActor @Published var action: ActionWithBudget?
    @MainActor @Published var selectedBalanceAccount: BalanceAccount = .emptyBalanceAccount {
        didSet {
            Task {
                self.isFetching = true
                await self.fetchBudgets()
                self.isFetching = false
            }
        }
    }
    /// true = line card, false = pie card (because only two type exists)
    @MainActor @Published var cardTypeIsLine: Bool = true
    @MainActor @Published private(set) var allBalanceAccounts: [BalanceAccount] = []
    @MainActor @Published private(set) var budgets: [Budget] = []
    @MainActor @Published private(set) var isFetching = false
    @MainActor @Published var navigationPath = NavigationPath() {
        didSet {
            if navigationPath.isEmpty {
                delegate?.showTabBar(true)
            } else {
                delegate?.showTabBar(false)
            }
        }
    }
    @MainActor var isViewDisplayed = false
    
    //MARK: - Initializer
    init(dataManager: any DataManagerProtocol) {
        self.dataManager = dataManager
        initialFetchData()
    }
    
    //MARK: - Methods
    func refreshIfNeeded(compeletionHandler: (@MainActor @Sendable () -> Void)? = nil) {
        guard neededToBeRefreshed else { return }
        neededToBeRefreshed = false
        refreshData(compeletionHandler: compeletionHandler)
    }
    
    func refreshData(compeletionHandler: (@MainActor @Sendable () -> Void)? = nil) {
        Task { @MainActor in
            isFetching = true
            await fetchBalanceAccounts()
            await fetchBudgets()
            isFetching = false
            compeletionHandler?()
        }
    }
    
    @MainActor
    func getBudgetCard<MenuItems: View>(for budget: Budget, namespace: Namespace.ID, @ViewBuilder menuItems: @escaping (BudgetCardViewData) -> MenuItems) -> some View {
        let viewModel = BudgetCardViewModel(dataManager: dataManager, budget: budget)
        let cardType: BudgetCardType = cardTypeIsLine ? .line : .pie
        return BudgetCard(viewModel: viewModel, namespace: namespace, type: cardType, menuItems: menuItems)
    }
    
    @MainActor
    func getAddingBudgetView() -> some View {
        return FTFactory.shared.createAddingBudgetView(dataManager: dataManager, action: .add(selectedBalanceAccount), delegate: self)
    }
    
    @MainActor
    func getUpdaingBudgetView(for budget: Budget) -> some View {
        return FTFactory.shared.createAddingBudgetView(dataManager: dataManager, action: .update(budget: budget), delegate: self)
    }
    
    @MainActor
    func getTransactionsListView(for budgetData: BudgetCardViewData) -> some View {
        let budget = budgetData.budget
        let title = budget.name.isEmpty ? budget.category?.name ?? String(localized: "For all categories") : budget.name
        return FTFactory.shared.createTransactionListView(dataManager: dataManager, transactions: budgetData.transactions, title: title, threadToUse: .global, delegate: self)
    }
    
    @MainActor
    func getTransactionsListView(for budgetData: BudgetCardViewData, namespace: Namespace.ID) -> some View {
        let budget = budgetData.budget
        let title = budget.name.isEmpty ? budget.category?.name ?? String(localized: "For all categories") : budget.name
        let cardType: BudgetCardType = cardTypeIsLine ? .line : .pie
        let dataManagerCopy = dataManager
        return FTFactory.shared.createTransactionListView(dataManager: dataManager, transactions: budgetData.transactions, title: title, threadToUse: .global, delegate: self) { transes in
            let newBudgetData = BudgetCardViewData(budget: budgetData.budget, transactions: transes)
            return BudgetCard(dataManager: dataManagerCopy, namespace: namespace, type: cardType, budgetData: newBudgetData)
        }
    }
    
    
    @MainActor
    func deleteBudget(_ budget: Budget) {
        Task {
            await dataManager.deleteBudget(budget)
            delegate?.didDeleteBudget(budget)
        }
        
        withAnimation {
            budgets.removeAll { $0 == budget }
        }
    }
    
    //MARK: Private methods
    /// Does not fetch budgets because of they are fetched from selectedBalanceAccount observer
    private func initialFetchData() {
        Task { @MainActor in
            isFetching = true
            await fetchBalanceAccounts()
            selectedBalanceAccount = dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
            isFetching = false
        }
    }
    
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)? = nil) async {
        let descriptor = FetchDescriptor<BalanceAccount>()
        
        do {
            let fetchedBAs = try dataManager.fetch(descriptor)
            allBalanceAccounts = fetchedBAs
        } catch {
            errorHandler?(error)
        }
    }
    
    @MainActor
    private func fetchBudgets(errorHandler: ((Error) -> Void)? = nil) async {
        let copyBalanceAccId = selectedBalanceAccount.persistentModelID
        
        let predicate = #Predicate<Budget> {
            $0.balanceAccount?.persistentModelID == copyBalanceAccId
        }
        
        var descriptor = FetchDescriptor<Budget>(predicate: predicate)
        descriptor.relationshipKeyPathsForPrefetching = [\.category, \.balanceAccount]
        
        do {
            let fetchedBudgets = try dataManager.fetch(descriptor)
            withAnimation {
                budgets = fetchedBudgets
            }
        } catch {
            errorHandler?(error)
        }
    }
}

//MARK: - Extensions
//MARK: Extension for AddingBudgetViewModelDelegate
extension BudgetsViewModel: AddingBudgetViewModelDelegate {
    func didAddBudget(_ newBudget: Budget) {
        delegate?.didAddBudget(newBudget)
        Task { @MainActor in
            isFetching = true
            await fetchBudgets()
            isFetching = false
        }
    }
    
    func didUpdateBudget(_ updatedBudget: Budget) {
        delegate?.didUpdateBudget(updatedBudget)
    }
    
    func didDeleteBudget(_ deletedBudget: Budget) {
        delegate?.didDeleteBudget(deletedBudget)
    }
}

extension BudgetsViewModel: TransactionListViewModelDelegate {
    func didUpdatedTransaction() {
        delegate?.didUpdateTransaction()
        neededToBeRefreshed = true
        Task { @MainActor in
            withAnimation {
                budgets = []
            }
        }
    }
}

extension BudgetsViewModel: CustomTabViewModelDelegate {
    var id: String {
        return "BudgetsViewModel"
    }
    
    func addButtonPressed() {
        return
    }
    
    func didUpdateData(for dataType: SettingsSectionAndDataType, from tabView: TabViewType) {
        guard tabView != .budgetsView else { return }
        
        switch dataType {
        case .categories:
            neededToBeRefreshed = true
            Task { @MainActor in
                budgets = []
            }
        case .balanceAccounts:
            Task {@MainActor in
                await fetchBalanceAccounts()
            }
        case .tags:
            return
        case .transactions:
            neededToBeRefreshed = true
            Task { @MainActor in
                budgets = []
                if isViewDisplayed {
                    try await Task.sleep(for: .seconds(0.3))
                    refreshIfNeeded()
                }
            }
        case .appearance:
            return
        case .data:
            neededToBeRefreshed = true
            Task { @MainActor in
                budgets = []
                await fetchBalanceAccounts()
            }
        case .budgets:
            neededToBeRefreshed = true
            Task { @MainActor in
                budgets = []
            }
        case .notifications:
            return
        }
    }
}

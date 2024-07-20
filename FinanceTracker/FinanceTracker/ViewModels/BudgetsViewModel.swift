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
}

struct BudgetCardViewData: Identifiable, Hashable {
    let id = UUID().uuidString
    let budget: Budget
    let transactions: [Transaction]
}

//MARK: - ViewModel class
final class BudgetsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any BudgetsViewModelDelegate)?
    
    //MARK: Private properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published props
    @Published var action: ActionWithBudget?
    @Published var selectedBalanceAccount: BalanceAccount = .emptyBalanceAccount {
        didSet {
            Task.detached { @MainActor [weak self] in
                self?.isFetching = true
                await self?.fetchBudgets()
                self?.isFetching = false
            }
        }
    }
    @Published private (set) var allBalanceAccounts: [BalanceAccount] = []
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var isFetching = false
    
    //MARK: - Initializer
    init(dataManager: any DataManagerProtocol) {
        self.dataManager = dataManager
        initialFetchData()
    }
    
    //MARK: - Methods
    func refreshData(compeletionHandler: (() -> Void)? = nil) {
        Task {
            isFetching = true
            await fetchBalanceAccounts()
            await fetchBudgets()
            isFetching = false
            compeletionHandler?()
        }
    }
    
    func getBudgetCard<MenuItems: View>(for budget: Budget, namespace: Namespace.ID, @ViewBuilder menuItems: @escaping (BudgetCardViewData) -> MenuItems) -> some View {
        let viewModel = BudgetCardViewModel(dataManager: dataManager, budget: budget)
        return BudgetCard(viewModel: viewModel, namespace: namespace,  menuItems: menuItems)
    }
    
    func getAddingBudgetView() -> some View {
        return FTFactory.shared.createAddingBudgetView(dataManager: dataManager, action: .add(selectedBalanceAccount), delegate: self)
    }
    
    func getUpdaingBudgetView(for budget: Budget) -> some View {
        return FTFactory.shared.createAddingBudgetView(dataManager: dataManager, action: .update(budget: budget), delegate: self)
    }
    
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
        guard let index = budgets.firstIndex(of: updatedBudget) else { return }
    }
    
    func didDeleteBudget(_ deletedBudget: Budget) {
        delegate?.didDeleteBudget(deletedBudget)
    }
}

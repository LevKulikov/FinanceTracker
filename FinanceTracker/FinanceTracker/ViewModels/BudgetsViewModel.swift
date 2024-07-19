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
    
}

struct BudgetCardViewData: Identifiable {
    let id = UUID().uuidString
    let budget: Budget
    let transactions: [Transaction]
}

enum ActionWithBudget: Equatable {
    case add
    case update(Budget)
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
    
    func getBudgetCard(for budget: Budget, namespace: Namespace.ID) -> some View {
        let viewModel = BudgetCardViewModel(dataManager: dataManager, budget: budget)
        return BudgetCard(viewModel: viewModel, namespace: namespace)
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

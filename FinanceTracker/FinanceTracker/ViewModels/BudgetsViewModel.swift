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

//MARK: - ViewModel class
final class BudgetsViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any BudgetsViewModelDelegate)?
    
    //MARK: Private properties
    private let dataManager: any DataManagerProtocol
    
    //MARK: Published props
    @Published var selectedBalanceAccount: BalanceAccount = .emptyBalanceAccount {
        didSet {
            
        }
    }
    @Published private (set) var allBalanceAccounts: [BalanceAccount] = []
    @Published private(set) var budgets: [Budget] = []
    
    //MARK: - Initializer
    init(dataManager: any DataManagerProtocol) {
        self.dataManager = dataManager
        initialFetchData()
    }
    
    //MARK: - Methods
    func refreshData(compeletionHandler: (() -> Void)? = nil) {
        Task {
            await fetchBalanceAccounts()
            await fetchBudgets()
            compeletionHandler?()
        }
    }
    
    //MARK: Private methods
    private func initialFetchData() {
        Task { @MainActor in
            await fetchBalanceAccounts()
            selectedBalanceAccount = dataManager.getDefaultBalanceAccount() ?? .emptyBalanceAccount
            await fetchBudgets()
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

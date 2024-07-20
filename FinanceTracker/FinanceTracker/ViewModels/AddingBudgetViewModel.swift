//
//  AddingBudgetViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 20.07.2024.
//

import Foundation
import SwiftData
import SwiftUI

protocol AddingBudgetViewModelDelegate: AnyObject {
    func didAddBudget(_ newBudget: Budget)
    
    func didUpdateBudget(_ updatedBudget: Budget)
    
    func didDeleteBudget(_ deletedBudget: Budget)
}

enum ActionWithBudget: Equatable {
    case none
    case add(BalanceAccount)
    case update(budget: Budget)
}

final class AddingBudgetViewModel: ObservableObject {
    //MARK: - Properties
    weak var delegate: (any AddingBudgetViewModelDelegate)?
    
    //MARK: Published props
    @Published private(set) var action: ActionWithBudget
    @Published var name: String = ""
    @Published var value: Float = 0
    @Published var period: Budget.Period = .month
    @Published var category: Category?
    @Published var balanceAccount: BalanceAccount = .emptyBalanceAccount
    
    //MARK: Private props
    private let dataManager: any DataManagerProtocol
    private var budgetToUpdate: Budget?
    
    //MARK: - Initializer
    init(action: ActionWithBudget, dataManager: any DataManagerProtocol) {
        self._action = Published(wrappedValue: action)
        self.dataManager = dataManager
    }
    
    //MARK: - Methods
    func saveBudget(completionHandler: (() -> Void)? = nil) throws {
        switch action {
        case .none:
            completionHandler?()
        case .add:
            let newBudget = Budget(
                name: name,
                value: value,
                period: period,
                category: category,
                balanceAccount: balanceAccount
            )
            Task { @MainActor in
                dataManager.insert(newBudget)
                delegate?.didAddBudget(newBudget)
                completionHandler?()
            }
        case .update:
            guard let budgetToUpdate else {
                print("budgetToUpdate is nil, though action is .update")
                return
            }
            
            budgetToUpdate.name = name
            budgetToUpdate.value = value
            budgetToUpdate.period = period
            budgetToUpdate.setCategory(category)
            budgetToUpdate.setBalanceAccount(balanceAccount)
            
            Task { @MainActor in
                try dataManager.save()
                delegate?.didUpdateBudget(budgetToUpdate)
                completionHandler?()
            }
        }
    }
    
    //MARK: Private methods
    private func setBudgetData() {
        switch action {
        case .none:
            break
        case .add(let balanceAccount):
            self.balanceAccount = balanceAccount
        case .update(let budget):
            budgetToUpdate = budget
            name = budget.name
            value = budget.value
            period = budget.period
            category = budget.category
            balanceAccount = budget.balanceAccount ?? .emptyBalanceAccount
        }
    }
}

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
    func didAddBudget()
    
    func didUpdateBudget()
    
    func didDeleteBudget()
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

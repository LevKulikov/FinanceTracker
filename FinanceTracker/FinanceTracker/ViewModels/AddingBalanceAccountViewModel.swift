//
//  AddingBalanceAccountViewModel.swift
//  FinanceTracker
//
//  Created by Лев Куликов on 10.06.2024.
//

import Foundation
import SwiftUI
import SwiftData

protocol AddingBalanceAccountViewModelDelegate: AnyObject {
    func didUpdateBalanceAccount()
}

enum ActionWithBalanceAccaunt: Equatable {
    case none
    case add
    case update(BalanceAccount)
}

final class AddingBalanceAccountViewModel: ObservableObject {
    //MARK: - Properties
    private let dataManager: any DataManagerProtocol
    private var balanceAccountToUpdate: BalanceAccount?
    private var transactionWithBalanceAccount: [Transaction] = []
    private var transactionsChanges: Float = 0
    weak var delegate: (any AddingBalanceAccountViewModelDelegate)?
    
    //MARK: Published props
    @Published private(set) var action: ActionWithBalanceAccaunt = .none
    @Published private(set) var availableBalanceAccounts: [BalanceAccount] = []
    @Published var balanceString: String = ""
    
    //MARK: Category props to set
    @Published var name: String = ""
    @Published var currency: String = ""
    private var balance: Float = 0
    @Published var iconName: String = ""
    @Published var color: Color = .cyan
    
    //TODO: Чтобы была возможность изменить текущий балас с учетом всех трат и доходов: через формулу изначально устанавливать калькулированное значение изначальный баланс + изменения в значение balanceString, и только в ините; далее после изменения пользователем и кнопки сохранить через формулу вычислять, какое должно быть изначальное значение баланса, чтобы оно сходилось с установленным пользователем значением после добавления изменений всех трат и доходов
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, action: ActionWithBalanceAccaunt) {
        self.dataManager = dataManager
        self.action = action
    }
    
    //MARK: - Methods
    
    //MARK: Private props
    @MainActor
    private func fetchBalanceAccounts(errorHandler: ((Error) -> Void)?) {
        let descriptor = FetchDescriptor<BalanceAccount>()
        
        do {
            let fetchedBAs = try dataManager.fetch(descriptor)
            availableBalanceAccounts = fetchedBAs
        } catch {
            errorHandler?(error)
        }
    }
    
    private func setTransactionsChanges() {
        Task {
            await fetchTransactionsWithBalanceAccount(errorHandler: nil)
            let changes = calulateTransactionsChanges()
            transactionsChanges = changes
        }
    }
    
    private func fetchTransactionsWithBalanceAccount(errorHandler: ((Error) -> Void)?) async {
        guard let balanceAccountToUpdate else { return }
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate {
                $0.balanceAccount == balanceAccountToUpdate
            }
        )
        
        do {
            let fetchedTransactions = try await dataManager.fetch(descriptor)
            transactionWithBalanceAccount = fetchedTransactions
        } catch {
            errorHandler?(error)
        }
    }
    
    private func calulateTransactionsChanges() -> Float {
        let changes = transactionWithBalanceAccount.map { trans in
            let value = trans.type == .income ? trans.value : -trans.value
            return value
        }.reduce(0, +)
        return changes
    }
}

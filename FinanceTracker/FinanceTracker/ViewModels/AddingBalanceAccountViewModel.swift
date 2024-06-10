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
    /// Converted from balanceString to float from View
    var balance: Float = 0
    @Published var iconName: String = ""
    @Published var color: Color = .cyan
    
    //MARK: - Initializer
    init(dataManager: some DataManagerProtocol, action: ActionWithBalanceAccaunt) {
        self.dataManager = dataManager
        self.action = action
        setData()
    }
    
    //MARK: - Methods
    func save(completionHandler: @escaping () -> Void) {
        switch action {
        case .none, .add:
            let newBalanceAccount = BalanceAccount(
                name: name,
                currency: currency,
                balance: balance,
                iconName: iconName,
                color: color
            )
            
            Task {
                await dataManager.insert(newBalanceAccount)
                delegate?.didUpdateBalanceAccount()
                completionHandler()
            }
        case .update:
            guard let balanceAccountToUpdate else {
                print("balanceAccountToUpdate is nil, though action is .update")
                return
            }
            
            let balanceToSet = calculateNeededBalance()
            
            balanceAccountToUpdate.name = name
            balanceAccountToUpdate.currency = currency
            balanceAccountToUpdate.balance = balanceToSet
            balanceAccountToUpdate.iconName = iconName
            balanceAccountToUpdate.color = color
            
            Task {
                do {
                    try await dataManager.save()
                    delegate?.didUpdateBalanceAccount()
                    completionHandler()
                } catch {
                    print("Saving BalanceAccount error: \(error)")
                    return
                }
            }
        }
    }
    
    //MARK: Private props
    private func setData() {
        switch action {
        case .none, .add:
            break
        case .update(let balanceAccount):
            balanceAccountToUpdate = balanceAccount
            name = balanceAccount.name
            currency = balanceAccount.currency
            balance = balanceAccount.balance
            iconName = balanceAccount.iconName
            color = balanceAccount.color
            Task {
                await setTransactionsChanges()
                let totalBalance = balance + transactionsChanges
                balanceString = AppFormatters.numberFormatterWithDecimals.string(for: totalBalance) ?? ""
            }
        }
    }
    
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
    
    @MainActor
    private func setTransactionsChanges() async {
        await fetchTransactionsWithBalanceAccount(errorHandler: nil)
        let changes = calulateTransactionsChanges()
        transactionsChanges = changes
    }
    
    private func fetchTransactionsWithBalanceAccount(errorHandler: ((Error) -> Void)?) async {
        guard let balanceAccountToUpdate else { return }
        let baId = balanceAccountToUpdate.id
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate {
                $0.balanceAccount.id == baId
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
    
    //TODO: Чтобы была возможность изменить текущий балас с учетом всех трат и доходов: через формулу изначально устанавливать калькулированное значение изначальный баланс + изменения в значение balanceString, и только в ините; далее после изменения пользователем и кнопки сохранить через формулу вычислять, какое должно быть изначальное значение баланса, чтобы оно сходилось с установленным пользователем значением после добавления изменений всех трат и доходов
    
    private func calculateNeededBalance() -> Float {
        let valueToReturn = balance - transactionsChanges
        return valueToReturn
    }
}

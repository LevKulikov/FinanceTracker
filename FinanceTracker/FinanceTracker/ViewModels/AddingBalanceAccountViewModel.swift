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

enum ActionWithBalanceAccaunt: Equatable, Hashable {
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
    //TODO: Published property "action" is changed from background thread when action is .update(_). I dnk why, but the issue should be solved
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
            
            Task { @MainActor in
                dataManager.insert(newBalanceAccount)
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
            
            Task { @MainActor in
                do {
                    try dataManager.save()
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
                balanceString = FTFormatters.numberFormatterWithDecimals.string(for: totalBalance) ?? ""
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
        
        //Because of problems with predicate (it does not support multiple keypath and is unable to convert PredicateExpresion)
        //fetch descriptor fetches all transaction, and afterwords ViewModel filters fetched array
        let descriptor = FetchDescriptor<Transaction>()
        
        do {
            let fetchedTransactions = try await dataManager.fetch(descriptor)
            let filteredTransactions = fetchedTransactions.filter { $0.balanceAccount == balanceAccountToUpdate }
            transactionWithBalanceAccount = filteredTransactions
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
    
    private func calculateNeededBalance() -> Float {
        let valueToReturn = balance - transactionsChanges
        return valueToReturn
    }
}
